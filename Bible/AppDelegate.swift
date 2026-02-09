import UIKit
import WebKit

class AppDelegate: NSObject, UIApplicationDelegate {

    var preloadedWebView: WKWebView?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Preload WKWebView ahead of time
        preloadedWebView = WKWebView()
        preloadedWebView?.loadHTMLString("", baseURL: nil)

        return true
    }
}
