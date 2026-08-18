# iOS TestFlight Upload

Run this from macOS with Xcode installed. The Linux workspace can prepare the project, but Apple signing, archive export, and upload require Xcode tools.

## Prerequisites

- The app exists in App Store Connect with bundle ID `com.slgdeveloper.flappyrace`.
- The Mac has access to the Apple Developer team, signing certificate, and provisioning profile, or the API key can manage signing with `-allowProvisioningUpdates`.
- You have an App Store Connect API key `.p8`, Key ID, Issuer ID, and Apple Team ID.

## Build, export, validate, and upload

```bash
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000"
export ASC_KEY_PATH="$HOME/AuthKey_XXXXXXXXXX.p8"
export APPLE_TEAM_ID="XXXXXXXXXX"

./tools/ios_testflight_upload.sh
```

The script assigns a unique `CFBundleVersion` automatically using UTC time. To set it yourself:

```bash
IOS_BUILD_NUMBER=2026081801 ./tools/ios_testflight_upload.sh
```

To upload an already exported IPA:

```bash
IPA_PATH="builds/ios/export/FlappyRace.ipa" ./tools/ios_testflight_upload.sh
```

After the upload finishes, wait for Apple processing. The build appears in App Store Connect under TestFlight once processing completes.
