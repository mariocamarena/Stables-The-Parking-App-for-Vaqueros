import UIKit
import GoogleMaps  // Google Maps SDK
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyA622jt9zHj3qs8L5jdyCwMvpYxEXXvH8k") //API Key
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
