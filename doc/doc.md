···shell
dart run build_runner watch --delete-conflicting-outputs
flutter build apk --target-platform android-arm64
flutter build apk --target-platform android-arm64 --split-per-abi --release
flutter build apk --split-per-abi
···
