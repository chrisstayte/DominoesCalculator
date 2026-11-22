# Dormant camera scanning

The camera, live detection, photo review and on-device models are parked here
until the detector's licensing is resolved. Nothing in this folder is compiled
into the app, analyzed, or tested: `analysis_options.yaml` excludes
`dormant/**`, and `flutter test` only runs `test/`.

The app ships without any camera plugin or permission. There is no flag or
remote setting that brings the camera back; it takes a code change and a new
release.

## Layout

- `lib/` mirrors the app's `lib/` paths (models, providers, screens, services
  and widgets that only the camera used).
- `test/` mirrors `test/`. `test/helpers/noop_camera_provider.dart` held the
  `NoopCameraProvider` that lived in `test/helpers/test_app.dart`.
- Model files stay in `assets/models/` but are not listed in `pubspec.yaml`.

## Restoring the camera

1. Move `dormant/camera/lib/**` back into `lib/` and `dormant/camera/test/**`
   into `test/` (merge `NoopCameraProvider` back into `test_app.dart` and add
   the `cameraProvider` harness parameters).
2. Re-add packages to `pubspec.yaml`: `camera`, `permission_handler`,
   `flutter_litert: 1.4.0`, `image: 4.13.1`, `crypto`, `path_provider`,
   `sensors_plus`, and dev dependency `camera_platform_interface`. Re-add
   `assets/models/` and `assets/models/licenses/` to the asset list.
3. Restore the camera tab, `/camera` route, `AppRoutes.camera`, the
   `CameraProvider` in `main.dart`, and the camera pause/resume in
   `scaffold_with_nav_bar.dart`.
4. Re-add the native declarations: `NSCameraUsageDescription` in
   `ios/Runner/Info.plist`, `android.permission.CAMERA` in
   `android/app/src/main/AndroidManifest.xml`, and the `PERMISSION_CAMERA=1`
   preprocessor definition in the `ios/Podfile` post-install hook.
5. Restore the Ultralytics licence entry in `main.dart` if the detector is
   still Ultralytics, and settle the licence first. See the
   [model contracts and licensing](../../assets/models/README.md).

Git history before this move has the camera fully wired in.
