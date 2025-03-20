import Flutter
import UIKit
import AVFoundation
import MediaPlayer

public class SwiftFlutterToAirplayPlugin: NSObject, FlutterPlugin {
  private var routeDetector: AVRouteDetector?
  private var channel: FlutterMethodChannel?
  // Referência para o player atual
  private static var currentPlayer: AVPlayer?
  
  // Método para registrar o player atual
  public static func registerCurrentPlayer(_ player: AVPlayer) {
    currentPlayer = player
  }
  
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
    do {
        // Enviar notificação para pausar todos os players
        NotificationCenter.default.post(name: NSNotification.Name("PauseAllPlayers"), object: nil)
        
        // Desativar a sessão de áudio
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        
        // Reconfigurar a sessão de áudio
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
        try audioSession.overrideOutputAudioPort(.speaker)
        
        // Forçar a atualização do sistema de rotas de áudio
        MPMusicPlayerController.systemMusicPlayer.stop()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.channel?.invokeMethod("onAirplayConnectionChanged", arguments: ["connected": self.isConnectedToAirplay()])
        }
    } catch {
        print("Erro ao desconectar do Airplay: \(error.localizedDescription)")
    }
  }
}
