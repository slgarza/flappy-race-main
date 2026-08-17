# Android Studio Build

Open this folder in Android Studio:

`/home/sergiolozano/Downloads/Flappy-Race-main/android/build`

The project is configured with:

- Application ID: `com.slgdeveloper.flappyrace`
- Version code: `142`
- Version name: `0.14.2`
- Min SDK: `21`
- Target SDK: `35`
- ABI: `arm64-v8a`

To create the signed App Bundle, use:

`Build > Generate Signed Bundle / APK > Android App Bundle`

If you prefer building from the terminal, create a release/upload keystore and
fill the commented `release_keystore_*` values in `gradle.properties`, then run:

```bash
./gradlew bundleRelease
```

The bundle output will be:

`build/outputs/bundle/release/build-release.aab`
