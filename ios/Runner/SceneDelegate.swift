import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  private var healthPluginRegistered = false

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    registerNativeHealthIfNeeded()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    registerNativeHealthIfNeeded()
  }

  // Search all connected UIWindowScenes for a FlutterViewController.
  // self.window can be nil when FlutterSceneDelegate manages the window
  // through the scene directly, so we enumerate scenes instead.
  private func registerNativeHealthIfNeeded() {
    guard !healthPluginRegistered else { return }

    var messenger: FlutterBinaryMessenger?

    for scene in UIApplication.shared.connectedScenes {
      guard let ws = scene as? UIWindowScene else { continue }
      for win in ws.windows {
        if let vc = win.rootViewController as? FlutterViewController {
          messenger = vc.binaryMessenger
          break
        }
      }
      if messenger != nil { break }
    }

    // Fallback: self.window (works in some FlutterSceneDelegate configurations)
    if messenger == nil,
       let vc = window?.rootViewController as? FlutterViewController {
      messenger = vc.binaryMessenger
    }

    guard let m = messenger else { return }
    NativeHealthPlugin.setup(messenger: m)
    healthPluginRegistered = true
  }
}
