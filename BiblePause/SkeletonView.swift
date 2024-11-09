//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI
import OpenAPIURLSession

// MARK: SettingsManager
class SettingsManager: ObservableObject {
    
    @Published var showMenu: Bool = false
    @Published var selectedMenuItem: MenuItem = .main
    
    @AppStorage("fontIncreasePercent") var fontIncreasePercent: Double = 100.0
    
    @AppStorage("pauseType") var pauseType: PauseType = .none
    @AppStorage("pauseLength") var pauseLength: Double = 3.0
    @AppStorage("pauseBlock") var pauseBlock: PauseBlock = .verse
    
    @AppStorage("language") var language: String = "ru"
    @AppStorage("translation") var translation: Int = 10 // bti
    @AppStorage("translationName") var translationName: String = "BTI"
    @AppStorage("voice") var voice: Int = 4 // prozorovsky
    @AppStorage("voiceName") var voiceName: String = "Н. Семёнов-Прозоровский"
    @AppStorage("voiceMusic") var voiceMusic: Bool = false
    
    @AppStorage("currentExcerpt") var currentExcerpt: String = "mat 1"
    @AppStorage("currentExcerptTitle") var currentExcerptTitle: String = "Евангелие от Матфея"
    @AppStorage("currentExcerptSubtitle") var currentExcerptSubtitle: String = "Глава 1"
    @AppStorage("currentBookId") var currentBookId: Int = 0
    @AppStorage("currentChapterId") var currentChapterId: Int = 0
    
    @AppStorage("currentSpeed") var currentSpeed: Double = 1.0
    
    let client: any APIProtocol
    
    init() {
        //let url = "http://helper-vm-maria:8000"
        let url = "http://192.168.130.169:8000"
        self.client = Client(serverURL: URL(string: url)!, transport: URLSessionTransport())
    }
}

struct SkeletonView: View {
    
    @StateObject private var settingsManager = SettingsManager()
    
    // не имеет значения здесь
    @State private var showAsPartOfRead: Bool = false
    
    var body: some View {
        
        ZStack {
            Color("DarkGreen")
                .edgesIgnoringSafeArea(.all)
            
            if settingsManager.selectedMenuItem == .main {
                PageMainView()
                .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .read {
                PageReadView()
                    .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .select {
                PageSelectView(showFromRead: $showAsPartOfRead)
                .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .setup {
                PageSetupView(showFromRead: $showAsPartOfRead)
                .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .contacts {
                PageContactsView()
                .environmentObject(settingsManager)
            }
            
            // слой меню
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
        }
        
    }
}

#Preview {
    SkeletonView()
}
