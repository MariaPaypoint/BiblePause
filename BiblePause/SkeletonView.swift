//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI
import OpenAPIURLSession

class WindowsDataManager: ObservableObject {
    @Published var showMenu: Bool = false
    @Published var selectedMenuItem: MenuItem = .main
    @Published var currentExcerpt: String = "mat 1"
    @Published var currentExcerptTitle: String = "Евангелие от Матфея"
    @Published var currentExcerptSubtitle: String = "Глава 1"
    @Published var currentBookId: Int = 0
    @Published var currentChapterId: Int = 0
    
    let client: any APIProtocol
    
    init() {
        //let url = "http://helper-vm-maria:8000"
        let url = "http://192.168.130.169:8000"
        self.client = Client(serverURL: URL(string: url)!, transport: URLSessionTransport())
    }
}

// MARK: SettingsManager
class SettingsManager: ObservableObject {
    
    @AppStorage("fontIncreasePercent") var fontIncreasePercent: Double = 100.0
    
    @AppStorage("pauseType") var pauseType: PauseType = .none
    @AppStorage("pauseLength") var pauseLength: Double = 3.0
    @AppStorage("pauseBlock") var pauseBlock: PauseBlock = .verse
    
    @AppStorage("language") var language: String = "ru"
    @AppStorage("translation") var translation: Int = 10 // bti
    @AppStorage("voice") var voice: Int = 4 // prozorovsky
    
}

struct SkeletonView: View {
    
    @StateObject private var windowsDataManager = WindowsDataManager()
    @StateObject private var settingsManager = SettingsManager()
    
    // не имеет значения здесь
    @State private var showAsPartOfRead: Bool = false
    
    var body: some View {
        
        ZStack {
            Color("DarkGreen")
                .edgesIgnoringSafeArea(.all)
            
            if windowsDataManager.selectedMenuItem == .main {
                PageMainView()
                    .environmentObject(windowsDataManager)
            }
            
            else if windowsDataManager.selectedMenuItem == .read {
                PageReadView()
                    .environmentObject(windowsDataManager)
                    .environmentObject(settingsManager)
            }
            
            else if windowsDataManager.selectedMenuItem == .select {
                PageSelectView(showFromRead: $showAsPartOfRead)
                    .environmentObject(windowsDataManager)
            }
            
            else if windowsDataManager.selectedMenuItem == .setup {
                PageSetupView(showFromRead: $showAsPartOfRead)
                    .environmentObject(windowsDataManager)
            }
            
            else if windowsDataManager.selectedMenuItem == .contacts {
                PageContactsView()
                    .environmentObject(windowsDataManager)
            }
            
            // слой меню
            MenuView()
                .environmentObject(windowsDataManager)
                .offset(x: windowsDataManager.showMenu ? 0 : -getRect().width)
        }
        
    }
}

#Preview {
    SkeletonView()
}
