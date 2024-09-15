import UIKit
import WebKit

class AppDelegate: NSObject, UIApplicationDelegate {

    var preloadedWebView: WKWebView?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Предварительная загрузка WKWebView
        preloadedWebView = WKWebView()
        preloadedWebView?.loadHTMLString("", baseURL: nil)

        return true
    }
}
