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
    
    //@Published var currentTranslationIndex: Int = globalBibleText.getCurrentTranslationIndex()
    
    @Published var currentExcerpt: String = "mat 3:2-3"
    @Published var currentExcerptTitle: String = "Евангелие от Матфея"
    @Published var currentExcerptSubtitle: String = "Глава 3:2-3"
    //@Published var currentExcerptIsSingleChapter: Bool = true
    @Published var currentBookId: Int = 0
    @Published var currentChapterId: Int = 0
    
    let client: any APIProtocol
    
    init() {
        self.client = Client(serverURL: URL(string: "http://helper-vm-maria:8000")!, transport: URLSessionTransport())
    }
}

struct SkeletonView: View {
    
    @StateObject private var windowsDataManager = WindowsDataManager()
    
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
