import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyB9-_fimhOl_uiOMMjGvf-228Ya1cwfkxM")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
