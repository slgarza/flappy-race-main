#ifndef FLAPPY_ADS_IOS_H
#define FLAPPY_ADS_IOS_H

#include "core/object.h"

class FlappyAdsIOS : public Object {
	GDCLASS(FlappyAdsIOS, Object);

	static void _bind_methods();

	void *_delegate = nullptr;
	void *_interstitial = nullptr;
	void *_product_request = nullptr;
	void *_remove_ads_product = nullptr;
	bool _initializing = false;
	bool _initialized = false;
	bool _loading_interstitial = false;
	bool _remove_ads_owned = false;
	bool _loading_remove_ads_product = false;

public:
	void initialize();
	void loadInterstitial();
	bool isInterstitialReady() const;
	bool showInterstitial();
	void purchase_remove_ads();
	void restore_purchases();
	bool has_remove_ads() const;

	void _on_interstitial_loaded(void *p_interstitial);
	void _on_interstitial_failed();
	void _on_interstitial_closed();
	void _on_interstitial_shown();
	void _on_remove_ads_products_response(void *p_products);
	void _on_remove_ads_product_request_failed();
	void _on_remove_ads_purchased();
	void _on_remove_ads_purchase_failed();
	void _on_remove_ads_purchase_cancelled();

	FlappyAdsIOS();
	~FlappyAdsIOS();
};

void flappy_ads_ios_initialize();
void flappy_ads_ios_deinitialize();

#endif
