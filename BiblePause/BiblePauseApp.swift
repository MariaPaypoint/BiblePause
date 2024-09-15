//
//  BiblePauseApp.swift
//  BiblePause
//
//  Created by Maria Novikova on 09.05.2024.
//

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
