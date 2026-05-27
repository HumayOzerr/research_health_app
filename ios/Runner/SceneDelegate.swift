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


    if messenger == nil,
       let vc = window?.rootViewController as? FlutterViewController {
      messenger = vc.binaryMessenger
    }

    guard let m = messenger else { return }
    NativeHealthPlugin.setup(messenger: m)
    healthPluginRegistered = true
  }
}
