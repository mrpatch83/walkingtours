import Flutter
import UIKit
import MapKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  var audioPlayer: AVPlayer?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Method channel to provide routing via Apple Maps (MapKit)
    if let controller = window?.rootViewController as? FlutterViewController {
      let routingChannel = FlutterMethodChannel(name: "com.example.walking_tour_app/routing", binaryMessenger: controller.binaryMessenger)
      routingChannel.setMethodCallHandler { call, result in
        if call.method == "getRoute" {
          guard let args = call.arguments as? [String: Any],
                let startLat = args["startLat"] as? Double,
                let startLon = args["startLon"] as? Double,
                let endLat = args["endLat"] as? Double,
                let endLon = args["endLon"] as? Double else {
            DispatchQueue.main.async { result(FlutterError(code: "BAD_ARGS", message: "Missing routing arguments", details: nil)) }
            return
          }

          let sourcePlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: startLat, longitude: startLon))
          let destPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: endLat, longitude: endLon))
          let request = MKDirections.Request()
          request.source = MKMapItem(placemark: sourcePlacemark)
          request.destination = MKMapItem(placemark: destPlacemark)
          request.transportType = .walking

          let directions = MKDirections(request: request)
          directions.calculate { response, error in
            if let error = error {
              DispatchQueue.main.async { result(FlutterError(code: "MKERROR", message: error.localizedDescription, details: nil)) }
              return
            }
            guard let route = response?.routes.first else {
              DispatchQueue.main.async { result([]) }
              return
            }
            let count = route.polyline.pointCount
            var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: count)
            route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))
            var out: [[Double]] = []
            for c in coords {
              out.append([c.latitude, c.longitude])
            }
            DispatchQueue.main.async { result(out) }
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      // audio playback channel (network URLs)
      let audioChannel = FlutterMethodChannel(name: "com.example.walking_tour_app/audio", binaryMessenger: controller.binaryMessenger)
      audioChannel.setMethodCallHandler { [weak self] call, result in
        if call.method == "play" {
          guard let args = call.arguments as? [String: Any], let urlStr = args["url"] as? String else {
            DispatchQueue.main.async { result(FlutterError(code: "BAD_ARGS", message: "Missing audio url", details: nil)) }
            return
          }
          if urlStr.isEmpty {
            DispatchQueue.main.async { result(nil) }
            return
          }
          guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { result(FlutterError(code: "BAD_URL", message: "Invalid url", details: nil)) }
            return
          }
          self?.audioPlayer = AVPlayer(url: url)
          NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self?.audioPlayer?.currentItem, queue: .main) { _ in
            result(nil)
          }
          self?.audioPlayer?.play()
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
