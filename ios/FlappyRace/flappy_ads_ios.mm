#include "flappy_ads_ios.h"

#include "core/class_db.h"
#include "core/engine.h"
#include "core/os/os.h"

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>

static NSString *const kFlappyAdsInterstitialAdUnitID = @"ca-app-pub-5520658565266027/6038612501";
static NSString *const kFlappyAdsRemoveAdsProductID = @"remove_ads_flappykart";
static FlappyAdsIOS *flappy_ads_singleton = nullptr;

@interface FlappyAdsDelegate : NSObject <GADFullScreenContentDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
- (instancetype)initWithOwner:(FlappyAdsIOS *)owner;
@end

@implementation FlappyAdsDelegate {
	FlappyAdsIOS *_owner;
}

- (instancetype)initWithOwner:(FlappyAdsIOS *)owner {
	self = [super init];
	if (self) {
		_owner = owner;
	}
	return self;
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
	NSLog(@"FlappyAds: interstitial failed to present: %@", error.localizedDescription);
	if (_owner) {
		_owner->_on_interstitial_failed();
		_owner->loadInterstitial();
	}
}

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
	if (_owner) {
		_owner->_on_interstitial_shown();
	}
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
	if (_owner) {
		_owner->_on_interstitial_closed();
		_owner->loadInterstitial();
	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	if (_owner) {
		_owner->_on_remove_ads_products_response((__bridge void *)response.products);
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	NSLog(@"FlappyAds: remove ads product request failed: %@", error.localizedDescription);
	if (_owner) {
		_owner->_on_remove_ads_product_request_failed();
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
	for (SKPaymentTransaction *transaction in transactions) {
		if (![transaction.payment.productIdentifier isEqualToString:kFlappyAdsRemoveAdsProductID]) {
			continue;
		}

		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased:
			case SKPaymentTransactionStateRestored:
				if (_owner) {
					_owner->_on_remove_ads_purchased();
				}
				[queue finishTransaction:transaction];
				break;
			case SKPaymentTransactionStateFailed:
				if (_owner) {
					if (transaction.error.code == SKErrorPaymentCancelled) {
						_owner->_on_remove_ads_purchase_cancelled();
					} else {
						NSLog(@"FlappyAds: remove ads purchase failed: %@", transaction.error.localizedDescription);
						_owner->_on_remove_ads_purchase_failed();
					}
				}
				[queue finishTransaction:transaction];
				break;
			case SKPaymentTransactionStatePurchasing:
			case SKPaymentTransactionStateDeferred:
				break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	NSLog(@"FlappyAds: restore purchases failed: %@", error.localizedDescription);
	if (_owner) {
		if (error.code == SKErrorPaymentCancelled) {
			_owner->_on_remove_ads_purchase_cancelled();
		} else {
			_owner->_on_remove_ads_purchase_failed();
		}
	}
}

@end

void FlappyAdsIOS::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize"), &FlappyAdsIOS::initialize);
	ClassDB::bind_method(D_METHOD("loadInterstitial"), &FlappyAdsIOS::loadInterstitial);
	ClassDB::bind_method(D_METHOD("isInterstitialReady"), &FlappyAdsIOS::isInterstitialReady);
	ClassDB::bind_method(D_METHOD("showInterstitial"), &FlappyAdsIOS::showInterstitial);
	ClassDB::bind_method(D_METHOD("purchase_remove_ads"), &FlappyAdsIOS::purchase_remove_ads);
	ClassDB::bind_method(D_METHOD("restore_purchases"), &FlappyAdsIOS::restore_purchases);
	ClassDB::bind_method(D_METHOD("has_remove_ads"), &FlappyAdsIOS::has_remove_ads);

	ADD_SIGNAL(MethodInfo("interstitial_loaded"));
	ADD_SIGNAL(MethodInfo("interstitial_failed"));
	ADD_SIGNAL(MethodInfo("interstitial_shown"));
	ADD_SIGNAL(MethodInfo("interstitial_closed"));
	ADD_SIGNAL(MethodInfo("remove_ads_purchased"));
	ADD_SIGNAL(MethodInfo("remove_ads_purchase_failed"));
	ADD_SIGNAL(MethodInfo("remove_ads_purchase_cancelled"));
}

void FlappyAdsIOS::initialize() {
	if (_initialized || _initializing) {
		return;
	}

	_initializing = true;
	dispatch_async(dispatch_get_main_queue(), ^{
		[[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *status) {
			_initializing = false;
			_initialized = true;
			NSLog(@"FlappyAds: Google Mobile Ads initialized.");
			loadInterstitial();
		}];
	});
}

void FlappyAdsIOS::loadInterstitial() {
	if (_remove_ads_owned) {
		if (_interstitial != nullptr) {
			CFRelease(_interstitial);
			_interstitial = nullptr;
		}
		return;
	}

	if (_loading_interstitial || _interstitial != nullptr) {
		return;
	}

	if (!_initialized) {
		initialize();
		return;
	}

	_loading_interstitial = true;
	dispatch_async(dispatch_get_main_queue(), ^{
		[GADInterstitialAd loadWithAdUnitID:kFlappyAdsInterstitialAdUnitID
		                            request:[GADRequest request]
		                  completionHandler:^(GADInterstitialAd *ad, NSError *error) {
			                  _loading_interstitial = false;

			                  if (error) {
				                  NSLog(@"FlappyAds: interstitial failed to load: %@", error.localizedDescription);
				                  _on_interstitial_failed();
				                  return;
			                  }

			                  ad.fullScreenContentDelegate = (__bridge FlappyAdsDelegate *)_delegate;
			                  _on_interstitial_loaded((__bridge_retained void *)ad);
		                  }];
	});
}

bool FlappyAdsIOS::isInterstitialReady() const {
	return _interstitial != nullptr;
}

bool FlappyAdsIOS::showInterstitial() {
	if (_remove_ads_owned) {
		emit_signal("interstitial_closed");
		return true;
	}

	if (_interstitial == nullptr) {
		loadInterstitial();
		return false;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		GADInterstitialAd *ad = (__bridge_transfer GADInterstitialAd *)_interstitial;
		_interstitial = nullptr;

		NSError *error = nil;
		if (![ad canPresentFromRootViewController:nil error:&error]) {
			NSLog(@"FlappyAds: interstitial is not presentable: %@", error.localizedDescription);
			_on_interstitial_failed();
			loadInterstitial();
			return;
		}

		[ad presentFromRootViewController:nil];
	});

	return true;
}

void FlappyAdsIOS::purchase_remove_ads() {
	if (_remove_ads_owned) {
		emit_signal("remove_ads_purchased");
		return;
	}

	if (![SKPaymentQueue canMakePayments]) {
		NSLog(@"FlappyAds: StoreKit payments are disabled.");
		emit_signal("remove_ads_purchase_failed");
		return;
	}

	if (_remove_ads_product != nullptr) {
		SKProduct *product = (__bridge SKProduct *)_remove_ads_product;
		SKPayment *payment = [SKPayment paymentWithProduct:product];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
		return;
	}

	if (_loading_remove_ads_product) {
		return;
	}

	_loading_remove_ads_product = true;
	dispatch_async(dispatch_get_main_queue(), ^{
		NSSet<NSString *> *productIDs = [NSSet setWithObject:kFlappyAdsRemoveAdsProductID];
		SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIDs];
		request.delegate = (__bridge FlappyAdsDelegate *)_delegate;
		_product_request = (__bridge_retained void *)request;
		[request start];
	});
}

void FlappyAdsIOS::restore_purchases() {
	if (_remove_ads_owned) {
		emit_signal("remove_ads_purchased");
		return;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	});
}

bool FlappyAdsIOS::has_remove_ads() const {
	return _remove_ads_owned;
}

void FlappyAdsIOS::_on_interstitial_loaded(void *p_interstitial) {
	if (_interstitial != nullptr) {
		CFRelease(_interstitial);
	}
	_interstitial = p_interstitial;
	emit_signal("interstitial_loaded");
}

void FlappyAdsIOS::_on_interstitial_failed() {
	if (_interstitial != nullptr) {
		CFRelease(_interstitial);
		_interstitial = nullptr;
	}
	emit_signal("interstitial_failed");
}

void FlappyAdsIOS::_on_interstitial_closed() {
	emit_signal("interstitial_closed");
}

void FlappyAdsIOS::_on_interstitial_shown() {
	emit_signal("interstitial_shown");
}

void FlappyAdsIOS::_on_remove_ads_products_response(void *p_products) {
	_loading_remove_ads_product = false;
	if (_product_request != nullptr) {
		CFRelease(_product_request);
		_product_request = nullptr;
	}

	NSArray<SKProduct *> *products = (__bridge NSArray<SKProduct *> *)p_products;
	SKProduct *matched_product = nil;
	for (SKProduct *product in products) {
		if ([product.productIdentifier isEqualToString:kFlappyAdsRemoveAdsProductID]) {
			matched_product = product;
			break;
		}
	}

	if (!matched_product) {
		NSLog(@"FlappyAds: StoreKit product not found: %@", kFlappyAdsRemoveAdsProductID);
		emit_signal("remove_ads_purchase_failed");
		return;
	}

	if (_remove_ads_product != nullptr) {
		CFRelease(_remove_ads_product);
	}
	_remove_ads_product = (__bridge_retained void *)matched_product;
	SKPayment *payment = [SKPayment paymentWithProduct:matched_product];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

void FlappyAdsIOS::_on_remove_ads_product_request_failed() {
	_loading_remove_ads_product = false;
	if (_product_request != nullptr) {
		CFRelease(_product_request);
		_product_request = nullptr;
	}
	emit_signal("remove_ads_purchase_failed");
}

void FlappyAdsIOS::_on_remove_ads_purchased() {
	_remove_ads_owned = true;
	if (_interstitial != nullptr) {
		CFRelease(_interstitial);
		_interstitial = nullptr;
	}
	emit_signal("remove_ads_purchased");
}

void FlappyAdsIOS::_on_remove_ads_purchase_failed() {
	emit_signal("remove_ads_purchase_failed");
}

void FlappyAdsIOS::_on_remove_ads_purchase_cancelled() {
	emit_signal("remove_ads_purchase_cancelled");
}

FlappyAdsIOS::FlappyAdsIOS() {
	FlappyAdsDelegate *delegate = [[FlappyAdsDelegate alloc] initWithOwner:this];
	_delegate = (__bridge_retained void *)delegate;
	[[SKPaymentQueue defaultQueue] addTransactionObserver:delegate];
}

FlappyAdsIOS::~FlappyAdsIOS() {
	if (_delegate != nullptr) {
		FlappyAdsDelegate *delegate = (__bridge FlappyAdsDelegate *)_delegate;
		[[SKPaymentQueue defaultQueue] removeTransactionObserver:delegate];
	}
	if (_interstitial != nullptr) {
		CFRelease(_interstitial);
		_interstitial = nullptr;
	}
	if (_product_request != nullptr) {
		SKProductsRequest *request = (__bridge SKProductsRequest *)_product_request;
		request.delegate = nil;
		CFRelease(_product_request);
		_product_request = nullptr;
	}
	if (_remove_ads_product != nullptr) {
		CFRelease(_remove_ads_product);
		_remove_ads_product = nullptr;
	}
	if (_delegate != nullptr) {
		CFRelease(_delegate);
		_delegate = nullptr;
	}
}

void flappy_ads_ios_initialize() {
	if (flappy_ads_singleton) {
		return;
	}

	ClassDB::register_class<FlappyAdsIOS>();
	flappy_ads_singleton = memnew(FlappyAdsIOS);
	Engine::get_singleton()->add_singleton(Engine::Singleton("FlappyAds", flappy_ads_singleton));
}

void flappy_ads_ios_deinitialize() {
	if (!flappy_ads_singleton) {
		return;
	}

	memdelete(flappy_ads_singleton);
	flappy_ads_singleton = nullptr;
}
