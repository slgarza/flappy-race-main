package com.slgdeveloper.flappyrace.ads;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.util.Log;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class FlappyAdsPlugin extends GodotPlugin implements PurchasesUpdatedListener {
	private static final String TAG = "FlappyAds";
	private static final String PLUGIN_NAME = "FlappyAds";
	private static final String PRODUCTION_INTERSTITIAL_AD_UNIT_ID = "ca-app-pub-5520658565266027/1271634501";
	private static final String REMOVE_ADS_PRODUCT_ID = "remove_ads";

	private volatile boolean initializing = false;
	private volatile boolean initialized = false;
	private volatile boolean loadingInterstitial = false;
	private volatile InterstitialAd interstitialAd = null;
	private volatile boolean billingConnecting = false;
	private volatile boolean removeAdsOwned = false;
	private volatile BillingClient billingClient = null;
	private volatile ProductDetails removeAdsProductDetails = null;
	private volatile Runnable pendingBillingAction = null;

	public FlappyAdsPlugin(Godot godot) {
		super(godot);
		Log.i(TAG, "Plugin created.");
	}

	@Override
	public String getPluginName() {
		return PLUGIN_NAME;
	}

	@Override
	public Set<SignalInfo> getPluginSignals() {
		Set<SignalInfo> signals = new HashSet<>();
		signals.add(new SignalInfo("interstitial_loaded"));
		signals.add(new SignalInfo("interstitial_failed"));
		signals.add(new SignalInfo("interstitial_shown"));
		signals.add(new SignalInfo("interstitial_closed"));
		signals.add(new SignalInfo("billing_ready"));
		signals.add(new SignalInfo("remove_ads_purchased"));
		signals.add(new SignalInfo("remove_ads_purchase_failed"));
		signals.add(new SignalInfo("remove_ads_purchase_cancelled"));
		return signals;
	}

	@Override
	public List<String> getPluginMethods() {
		return Arrays.asList(
			"initialize",
			"loadInterstitial",
			"isInterstitialReady",
			"showInterstitial",
			"purchaseRemoveAds",
			"purchase_remove_ads",
			"restorePurchases",
			"restore_purchases",
			"hasRemoveAds",
			"has_remove_ads"
		);
	}

	@UsedByGodot
	public void initialize() {
		if (initialized || initializing) {
			return;
		}

		Activity activity = getActivity();
		if (activity == null) {
			Log.w(TAG, "Cannot initialize Mobile Ads without an Activity.");
			return;
		}

		initializing = true;
		Log.i(TAG, "Initializing Google Mobile Ads SDK.");
		new Thread(() -> MobileAds.initialize(activity, status -> runOnUiThread(() -> {
			initializing = false;
			initialized = true;
			Log.i(TAG, "Google Mobile Ads SDK initialized.");
			loadInterstitialOnUiThread();
		}))).start();
		initializeBilling(activity);
	}

	@UsedByGodot
	public void loadInterstitial() {
		if (!initialized) {
			initialize();
			return;
		}
		runOnUiThread(this::loadInterstitialOnUiThread);
	}

	@UsedByGodot
	public boolean isInterstitialReady() {
		return !removeAdsOwned && interstitialAd != null;
	}

	@UsedByGodot
	public boolean showInterstitial() {
		if (removeAdsOwned) {
			return false;
		}

		Activity activity = getActivity();
		InterstitialAd adToShow = interstitialAd;
		if (activity == null || adToShow == null) {
			loadInterstitial();
			return false;
		}

		interstitialAd = null;
		runOnUiThread(() -> showInterstitialOnUiThread(activity, adToShow));
		return true;
	}

	@UsedByGodot
	public void purchaseRemoveAds() {
		Log.i(TAG, "Remove ads purchase requested.");
		if (removeAdsOwned) {
			emitRemoveAdsPurchased();
			return;
		}

		startBillingConnection(() -> queryRemoveAdsProductDetails(this::launchRemoveAdsPurchase));
	}

	@UsedByGodot
	public void purchase_remove_ads() {
		purchaseRemoveAds();
	}

	@UsedByGodot
	public void restorePurchases() {
		startBillingConnection(this::queryExistingPurchases);
	}

	@UsedByGodot
	public void restore_purchases() {
		restorePurchases();
	}

	@UsedByGodot
	public boolean hasRemoveAds() {
		return removeAdsOwned;
	}

	@UsedByGodot
	public boolean has_remove_ads() {
		return hasRemoveAds();
	}

	private void loadInterstitialOnUiThread() {
		if (removeAdsOwned) {
			interstitialAd = null;
			return;
		}

		if (!initialized || loadingInterstitial || interstitialAd != null) {
			return;
		}

		Activity activity = getActivity();
		if (activity == null) {
			Log.w(TAG, "Cannot load interstitial without an Activity.");
			return;
		}

		loadingInterstitial = true;
		String adUnitId = getInterstitialAdUnitId(activity);
		Log.i(TAG, "Loading interstitial. debug=" + isDebuggable(activity) + ", adUnitId=" + adUnitId);
		AdRequest adRequest = new AdRequest.Builder().build();
		InterstitialAd.load(activity, adUnitId, adRequest, new InterstitialAdLoadCallback() {
			@Override
			public void onAdLoaded(InterstitialAd ad) {
				loadingInterstitial = false;
				interstitialAd = ad;
				Log.i(TAG, "Interstitial loaded.");
				emitSignal("interstitial_loaded");
			}

			@Override
			public void onAdFailedToLoad(LoadAdError loadAdError) {
				loadingInterstitial = false;
				interstitialAd = null;
				Log.w(TAG, "Interstitial failed to load: " + loadAdError);
				emitSignal("interstitial_failed");
			}
		});
	}

	private void showInterstitialOnUiThread(Activity activity, InterstitialAd adToShow) {
		if (removeAdsOwned) {
			emitSignal("interstitial_closed");
			return;
		}

		adToShow.setFullScreenContentCallback(new FullScreenContentCallback() {
			@Override
			public void onAdShowedFullScreenContent() {
				Log.i(TAG, "Interstitial shown.");
				emitSignal("interstitial_shown");
			}

			@Override
			public void onAdDismissedFullScreenContent() {
				Log.i(TAG, "Interstitial closed.");
				emitSignal("interstitial_closed");
				loadInterstitialOnUiThread();
			}

			@Override
			public void onAdFailedToShowFullScreenContent(AdError adError) {
				Log.w(TAG, "Interstitial failed to show: " + adError);
				emitSignal("interstitial_failed");
				emitSignal("interstitial_closed");
				loadInterstitialOnUiThread();
			}
		});

		try {
			Log.i(TAG, "Showing interstitial.");
			adToShow.show(activity);
		} catch (RuntimeException exception) {
			Log.w(TAG, "Interstitial show threw an exception.", exception);
			emitSignal("interstitial_failed");
			emitSignal("interstitial_closed");
			loadInterstitialOnUiThread();
		}
	}

	private String getInterstitialAdUnitId(Activity activity) {
		return PRODUCTION_INTERSTITIAL_AD_UNIT_ID;
	}

	private boolean isDebuggable(Activity activity) {
		if (activity == null || activity.getApplicationInfo() == null) {
			return false;
		}
		return (activity.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
	}

	private void initializeBilling(Activity activity) {
		if (billingClient != null || activity == null) {
			return;
		}

		PendingPurchasesParams pendingPurchasesParams = PendingPurchasesParams.newBuilder()
			.enableOneTimeProducts()
			.build();
		billingClient = BillingClient.newBuilder(activity)
			.setListener(this)
			.enablePendingPurchases(pendingPurchasesParams)
			.enableAutoServiceReconnection()
			.build();
		startBillingConnection(this::queryExistingPurchases);
	}

	private void startBillingConnection(Runnable afterConnected) {
		Activity activity = getActivity();
		if (activity == null) {
			Log.w(TAG, "Cannot start billing without an Activity.");
			emitPurchaseFailed();
			return;
		}

		initializeBillingClientIfNeeded(activity);
		if (billingClient.isReady()) {
			if (afterConnected != null) {
				afterConnected.run();
			}
			return;
		}
		if (billingConnecting) {
			Log.i(TAG, "Billing connection is already in progress. Queuing billing action.");
			pendingBillingAction = afterConnected;
			return;
		}

		billingConnecting = true;
		billingClient.startConnection(new BillingClientStateListener() {
			@Override
			public void onBillingSetupFinished(BillingResult billingResult) {
				billingConnecting = false;
				if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
					Log.i(TAG, "Billing client ready.");
					runOnUiThread(() -> emitSignal("billing_ready"));
					if (afterConnected != null) {
						afterConnected.run();
					}
					Runnable pendingAction = pendingBillingAction;
					pendingBillingAction = null;
					if (pendingAction != null && pendingAction != afterConnected) {
						pendingAction.run();
					}
				} else {
					Log.w(TAG, "Billing setup failed: " + billingResult);
					pendingBillingAction = null;
					emitPurchaseFailed();
				}
			}

			@Override
			public void onBillingServiceDisconnected() {
				boolean hadPendingBillingAction = pendingBillingAction != null;
				billingConnecting = false;
				pendingBillingAction = null;
				Log.w(TAG, "Billing service disconnected.");
				if (hadPendingBillingAction) {
					emitPurchaseFailed();
				}
			}
		});
	}

	private void initializeBillingClientIfNeeded(Activity activity) {
		if (billingClient != null) {
			return;
		}

		PendingPurchasesParams pendingPurchasesParams = PendingPurchasesParams.newBuilder()
			.enableOneTimeProducts()
			.build();
		billingClient = BillingClient.newBuilder(activity)
			.setListener(this)
			.enablePendingPurchases(pendingPurchasesParams)
			.enableAutoServiceReconnection()
			.build();
	}

	private void queryRemoveAdsProductDetails(Runnable afterLoaded) {
		if (billingClient == null || !billingClient.isReady()) {
			emitPurchaseFailed();
			return;
		}

		QueryProductDetailsParams.Product product = QueryProductDetailsParams.Product.newBuilder()
			.setProductId(REMOVE_ADS_PRODUCT_ID)
			.setProductType(BillingClient.ProductType.INAPP)
			.build();
		QueryProductDetailsParams params = QueryProductDetailsParams.newBuilder()
			.setProductList(Arrays.asList(product))
			.build();

		billingClient.queryProductDetailsAsync(params, (billingResult, productDetailsResult) -> {
			if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
				Log.w(TAG, "Failed to query remove ads product: " + billingResult);
				emitPurchaseFailed();
				return;
			}

			List<ProductDetails> productDetailsList = productDetailsResult.getProductDetailsList();
			if (productDetailsList == null || productDetailsList.isEmpty()) {
				Log.w(TAG, "Remove ads product details were not returned. Check Play Console product id: " + REMOVE_ADS_PRODUCT_ID);
				emitPurchaseFailed();
				return;
			}

			removeAdsProductDetails = productDetailsList.get(0);
			if (afterLoaded != null) {
				afterLoaded.run();
			}
		});
	}

	private void launchRemoveAdsPurchase() {
		Activity activity = getActivity();
		ProductDetails details = removeAdsProductDetails;
		if (activity == null || billingClient == null || details == null) {
			emitPurchaseFailed();
			return;
		}

		BillingFlowParams.ProductDetailsParams productDetailsParams = BillingFlowParams.ProductDetailsParams.newBuilder()
			.setProductDetails(details)
			.build();
		BillingFlowParams billingFlowParams = BillingFlowParams.newBuilder()
			.setProductDetailsParamsList(Arrays.asList(productDetailsParams))
			.build();

		runOnUiThread(() -> {
			BillingResult billingResult = billingClient.launchBillingFlow(activity, billingFlowParams);
			int responseCode = billingResult.getResponseCode();
			if (responseCode != BillingClient.BillingResponseCode.OK && responseCode != BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) {
				Log.w(TAG, "Failed to launch remove ads purchase: " + billingResult);
				emitPurchaseFailed();
			}
			if (responseCode == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) {
				queryExistingPurchases();
			}
		});
	}

	private void queryExistingPurchases() {
		if (billingClient == null || !billingClient.isReady()) {
			return;
		}

		QueryPurchasesParams params = QueryPurchasesParams.newBuilder()
			.setProductType(BillingClient.ProductType.INAPP)
			.build();
		billingClient.queryPurchasesAsync(params, (billingResult, purchases) -> {
			if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK) {
				Log.w(TAG, "Failed to restore purchases: " + billingResult);
				return;
			}
			handlePurchases(purchases);
		});
	}

	@Override
	public void onPurchasesUpdated(BillingResult billingResult, List<Purchase> purchases) {
		int responseCode = billingResult.getResponseCode();
		if (responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
			handlePurchases(purchases);
			return;
		}
		if (responseCode == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) {
			queryExistingPurchases();
			return;
		}
		if (responseCode == BillingClient.BillingResponseCode.USER_CANCELED) {
			emitPurchaseCancelled();
			return;
		}
		Log.w(TAG, "Purchase failed: " + billingResult);
		emitPurchaseFailed();
	}

	private void handlePurchases(List<Purchase> purchases) {
		if (purchases == null) {
			return;
		}

		for (Purchase purchase : purchases) {
			if (!purchase.getProducts().contains(REMOVE_ADS_PRODUCT_ID)) {
				continue;
			}
			if (purchase.getPurchaseState() != Purchase.PurchaseState.PURCHASED) {
				continue;
			}

			removeAdsOwned = true;
			interstitialAd = null;
			if (!purchase.isAcknowledged()) {
				acknowledgeRemoveAdsPurchase(purchase);
			}
			emitRemoveAdsPurchased();
		}
	}

	private void acknowledgeRemoveAdsPurchase(Purchase purchase) {
		if (billingClient == null || !billingClient.isReady()) {
			return;
		}

		AcknowledgePurchaseParams params = AcknowledgePurchaseParams.newBuilder()
			.setPurchaseToken(purchase.getPurchaseToken())
			.build();
		billingClient.acknowledgePurchase(params, billingResult -> {
			if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
				Log.i(TAG, "Remove ads purchase acknowledged.");
			} else {
				Log.w(TAG, "Failed to acknowledge remove ads purchase: " + billingResult);
			}
		});
	}

	private void emitRemoveAdsPurchased() {
		runOnUiThread(() -> emitSignal("remove_ads_purchased"));
	}

	private void emitPurchaseFailed() {
		runOnUiThread(() -> emitSignal("remove_ads_purchase_failed"));
	}

	private void emitPurchaseCancelled() {
		runOnUiThread(() -> emitSignal("remove_ads_purchase_cancelled"));
	}
}
