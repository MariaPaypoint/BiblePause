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
    
    //var translationInfo: Components.Schemas.TranslationInfoModel?
    
    let client: any APIProtocol
    
    init() {
        //let url = "http://34.69.129.96:8000" // Google Cloude
        //let url = "http://192.168.130.169" // helper-vm-maria INT
        //let url = "http://82.202.219.181"  // helper-vm-maria external
        let url = "http://replica-vm-maria:8000" // replica-vm-maria INT 192.168.100.30
        
        
        self.client = Client(serverURL: URL(string: url)!, transport: URLSessionTransport())
        
        // загрузка информации о переводе
        /*
        Task {
            do {
                let response = try await client.get_translation_info(query: .init(translation: Int(exactly: translation)!))
                let translationInfoResponse = try response.ok.body.json
                self.translationInfo = translationInfoResponse
            } catch {
                // ничего не делать
            }
        }
        */
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
