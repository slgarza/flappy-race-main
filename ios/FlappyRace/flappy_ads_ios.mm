#include "flappy_ads_ios.h"

#include "core/class_db.h"
#include "core/engine.h"
#include "core/os/os.h"

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <UIKit/UIKit.h>

static NSString *const kFlappyAdsInterstitialAdUnitID = @"ca-app-pub-5520658565266027/6038612501";
static FlappyAdsIOS *flappy_ads_singleton = nullptr;

@interface FlappyAdsDelegate : NSObject <GADFullScreenContentDelegate>
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

@end

void FlappyAdsIOS::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize"), &FlappyAdsIOS::initialize);
	ClassDB::bind_method(D_METHOD("loadInterstitial"), &FlappyAdsIOS::loadInterstitial);
	ClassDB::bind_method(D_METHOD("isInterstitialReady"), &FlappyAdsIOS::isInterstitialReady);
	ClassDB::bind_method(D_METHOD("showInterstitial"), &FlappyAdsIOS::showInterstitial);

	ADD_SIGNAL(MethodInfo("interstitial_loaded"));
	ADD_SIGNAL(MethodInfo("interstitial_failed"));
	ADD_SIGNAL(MethodInfo("interstitial_shown"));
	ADD_SIGNAL(MethodInfo("interstitial_closed"));
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

FlappyAdsIOS::FlappyAdsIOS() {
	FlappyAdsDelegate *delegate = [[FlappyAdsDelegate alloc] initWithOwner:this];
	_delegate = (__bridge_retained void *)delegate;
}

FlappyAdsIOS::~FlappyAdsIOS() {
	if (_interstitial != nullptr) {
		CFRelease(_interstitial);
		_interstitial = nullptr;
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
