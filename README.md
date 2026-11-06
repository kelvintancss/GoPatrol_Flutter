# patrol_flutter 📱 

## Flutter version
- Flutter (Channel stable, 3.32, on macOS 15.0.1 24A348 darwin-arm64, locale en-US)
- Java 17
- Dart 3.8.0

---

## 🚀 Features
- Home

---

## 🧑‍💻 Tech Stack
| Technology | Description              |
|------------|--------------------------|
| Flutter    | Cross-platform framework |
| Dart       | Programming language     |
| Firebase   | Backend services         |
| BLoC       | State management         |
| Dio        | Data Handling/REST api   |
-----------------------------------------

## Project structure


## 📌 Notes
- `main_development/main_production/` = entry point run the app (select the flavor)
- `core/` = foundational utilities, services, constants, repository
- `packages/` = API, data layer, other share/ custom packages
- `service_locator/` = startup logic, DI, use before initial very first UI render
- `feature/` = every module/feature with state management

---


## 🛠️ How to run
```bash
# 1. Clone the repo
git clone repo.git

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

## Route management
main -> app -> module 

## Useful command
```bash
# How to create a package
flutter create --template=package "name"

## Run flavor 
flutter pub run flutter_flavorizr

## Build script
dart run build_runner build
'''

firebase command
flutterfire configure --project=[projectId] out=[path] ios-bundle-id=com.css.patrol.int android-package-name=com.css.patrol.int

native splash 
dart run flutter_native_splash:create --path=path/to/my/file.yaml

flutter build apk -t lib/main_development.dart --flavor staging --obfuscate --split-debug-info=build/app/outputs/symbols

flutter build apk -t lib/main_demo.dart --flavor demo --obfuscate --split-debug-info=build/app/outputs/symbols

flutter build apk -t lib/main_production.dart --flavor production --obfuscate --split-debug-info=build/app/outputs/symbols

```

## 🛠️ Deployment
# Build Android APK
flutter build apk

# Build iOS
flutter build ios


## Open issues


## References
1. Bloc state management. https://bloclibrary.dev
2. flutter_gen is deprecated (10/05/25) - https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source#migration-guide
3. Firebase setup. https://firebase.google.com/docs/cli#install-cli-mac-linux
4. Model quick set - https://app.quicktype.io