#ifndef FLAPPY_ADS_IOS_H
#define FLAPPY_ADS_IOS_H

#include "core/object.h"

class FlappyAdsIOS : public Object {
	GDCLASS(FlappyAdsIOS, Object);

	static void _bind_methods();

	void *_delegate = nullptr;
	void *_interstitial = nullptr;
	bool _initializing = false;
	bool _initialized = false;
	bool _loading_interstitial = false;

public:
	void initialize();
	void loadInterstitial();
	bool isInterstitialReady() const;
	bool showInterstitial();

	void _on_interstitial_loaded(void *p_interstitial);
	void _on_interstitial_failed();
	void _on_interstitial_closed();
	void _on_interstitial_shown();

	FlappyAdsIOS();
	~FlappyAdsIOS();
};

void flappy_ads_ios_initialize();
void flappy_ads_ios_deinitialize();

#endif
