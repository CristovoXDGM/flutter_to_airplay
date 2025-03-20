import Flutter
import UIKit
import AVFoundation
import MediaPlayer

public class SwiftFlutterToAirplayPlugin: NSObject, FlutterPlugin {
  private var routeDetector: AVRouteDetector?
  private var channel: FlutterMethodChannel?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_to_airplay", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterToAirplayPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    registrar.register(
        SharePlatformViewFactory(messenger: registrar.messenger()),
        withId: "airplay_route_picker_view",
        gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy(rawValue: 0))
    
    registrar.register(
        SharePlatformViewFactory(messenger: registrar.messenger()),
        withId: "flutter_avplayer_view",
        gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy(rawValue: 0))
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startMonitoringAirplayConnection":
      startMonitoringAirplayConnection()
      result(nil)
    case "stopMonitoringAirplayConnection":
      stopMonitoringAirplayConnection()
      result(nil)
    case "isConnectedToAirplay":
      result(isConnectedToAirplay())
    case "disconnectFromAirplay":
      disconnectFromAirplay()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func startMonitoringAirplayConnection() {
    routeDetector = AVRouteDetector()
    routeDetector?.isRouteDetectionEnabled = true
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRouteChange),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
  }
  
  private func stopMonitoringAirplayConnection() {
    routeDetector?.isRouteDetectionEnabled = false
    routeDetector = nil
    NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
  }
  
  @objc private func handleRouteChange(notification: Notification) {
    channel?.invokeMethod("onAirplayConnectionChanged", arguments: ["connected": isConnectedToAirplay()])
  }
  
  private func isConnectedToAirplay() -> Bool {
    let currentRoute = AVAudioSession.sharedInstance().currentRoute
    for output in currentRoute.outputs {
      if output.portType == AVAudioSession.Port.airPlay {
        return true
      }
    }
    return false
  }
  
  private func disconnectFromAirplay() {
  // Método para desconectar do Airplay
  do {
    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
    // Forçar a saída de áudio para o alto-falante interno
    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
    
    // Corrigindo o uso do MPVolumeView
    let volumeView = MPVolumeView()
    for view in volumeView.subviews {
      if let button = view as? UIButton {
        button.sendActions(for: .touchUpInside)
        break
      }
    }
  } catch {
    print("Erro ao desconectar do Airplay: \(error.localizedDescription)")
  }
}

}
