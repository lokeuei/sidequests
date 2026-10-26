# Sidequests setup for Pixel 9

Target: Google Pixel 9 (Android 14/15) via USB or Wi-Fi debugging.
Time: ~30–60 min first install, ~2 min after that.

## 1. Install Flutter (missing on this machine)

1. Download the latest **stable** Flutter SDK from
   <https://docs.flutter.dev/get-started/install/windows> (desktop + mobile).
2. Extract to a short path without spaces, e.g. `C:\flutter`.
3. Add `C:\flutter\bin` to your user `PATH`, then open a **new** terminal:

```powershell
flutter --version
flutter doctor
```

## 2. Android toolchain (mostly present)

This machine already has:

- JDK 21 (`C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot`)
- Android SDK at `C:\Users\Loke\AppData\Local\Android\Sdk` with
  platforms 29/33/34, build-tools incl. 34.0.0, cmdline-tools, emulator
- `adb` on PATH, `gh` logged in as `lokeuei`

Still needed:

```powershell
flutter doctor --android-licenses   # accept all (needs network)
flutter doctor                      # aim: all green except optional Studio/VS Code
```

Optional but recommended: install
[Android Studio](https://developer.android.com/studio) for the emulator and
SDK updates. The app targets `compileSdk 34`, which is already installed.

## 3. Prep the Pixel 9

1. Settings → About phone → tap **Build number** 7× (developer mode).
2. Settings → System → Developer options → enable **USB debugging**
   (and **Wireless debugging** if you prefer no cable).
3. Plug in via USB, accept the RSA prompt, then verify:

```powershell
adb devices   # should list your Pixel 9 as "device"
```

## 4. Get the code and complete the native shells

```powershell
git clone https://github.com/lokeuei/sidequests.git
cd sidequests
flutter create --platforms=android,ios .  # fills icons, Gradle wrapper, iOS shell
flutter pub get
```

(`flutter create .` only adds missing/generated platform files. It keeps `lib/`.)

## 5. Run on the Pixel 9

```powershell
flutter devices     # Pixel 9 should appear
flutter run         # pick the Pixel 9; first build takes a few minutes
```

On first launch, grant **location** (for nearby ranking + travel detection)
and **notifications** (for nudges) when asked. Denying either is fine.
The app falls back to stub context and in-app-only suggestions.

Useful during dev:

```powershell
flutter run -d <device-id>   # if several devices are attached
r                            # hot reload, R for hot restart (inside flutter run)
flutter analyze              # lints
flutter test                 # unit + widget tests
```

## 6. Build an installable APK (optional)

```powershell
flutter build apk --release
# output: build\app\outputs\flutter-apk\app-release.apk
adb install build\app\outputs\flutter-apk\app-release.apk
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `flutter.sdk not set in local.properties` | Run `flutter pub get` once. The tool writes it. |
| Gradle download stalls | Check proxy/VPN; retry `flutter run -v`. |
| `compileSdk 34` / build-tools missing | `sdkmanager "platforms;android-34" "build-tools;34.0.0"` |
| JDK errors in Gradle | Keep JDK 17–21; this repo compiles against Java 17 bytecode. |
| Location always "Your neighborhood" | Grant location permission; enable Location Services on the phone. |
| No notification | Grant notification permission; check Do Not Disturb / channel "Adventure nudges". |
| Fonts look off in tests | Tests set `allowRuntimeFetching = false`. That is expected; tests use fallback fonts. |
