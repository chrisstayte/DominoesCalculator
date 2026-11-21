import AVFAudio
import CoreHaptics
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "dominoes/haptics",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "isSupported" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(CHHapticEngine.capabilitiesForHardware().supportsHaptics)
    }
    FlutterEventChannel(
      name: "dominoes/systemSound",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setStreamHandler(OutputVolumeStatus())
  }
}

private final class OutputVolumeStatus: NSObject, FlutterStreamHandler {
  private var observation: NSKeyValueObservation?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    // outputVolume is public and observable. Silent Mode is applied separately by the ambient session.
    observation = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.initial, .new]) { session, _ in
      let status = session.outputVolume == 0 ? "zeroVolume" : "normal"
      DispatchQueue.main.async { events(status) }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observation = nil
    return nil
  }
}
