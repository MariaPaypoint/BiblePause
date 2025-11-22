import SwiftUI

@main
struct BiblePauseApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    
    var body: some Scene {
        WindowGroup {
            SkeletonView()
        }
    }
}
