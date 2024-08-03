//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

class WindowsDataManager: ObservableObject {
    @Published var showMenu: Bool = false
    @Published var selectedMenuItem: MenuItem = .main
    
    @Published var currentTranslationIndex: Int = globalBibleText.getCurrentTranslationIndex()
    
    @Published var currentExcerpt: String = "mat 3:2-3"
    @Published var currentExcerptTitle: String = "Евангелие от Матфея"
    @Published var currentExcerptSubtitle: String = "Глава 3:2-3"
    //@Published var currentExcerptIsSingleChapter: Bool = true
    @Published var currentBookId: Int = 0
    @Published var currentChapterId: Int = 0
}

struct SkeletonView: View {
    
    @StateObject var windowsDataManager = WindowsDataManager()
    
    // не имеет значения здесь
    @State private var showAsPartOfRead: Bool = false
    
    var body: some View {
        
        ZStack {
            Color("DarkGreen")
                .edgesIgnoringSafeArea(.all)
            
            if windowsDataManager.selectedMenuItem == .main {
                PageMainView(windowsDataManager: windowsDataManager)
            }
            
            else if windowsDataManager.selectedMenuItem == .read {
                PageReadView(windowsDataManager: windowsDataManager)
            }
            
            else if windowsDataManager.selectedMenuItem == .select {
                PageSelectView(windowsDataManager: windowsDataManager,
                               showFromRead: $showAsPartOfRead)
            }
            
            else if windowsDataManager.selectedMenuItem == .setup {
                PageSetupView(windowsDataManager: windowsDataManager,
                              showFromRead: $showAsPartOfRead)
            }
            
            else if windowsDataManager.selectedMenuItem == .contacts {
                PageContactsView(windowsDataManager: windowsDataManager)
                //PageContactsView()
            }
            
            // слой меню
            MenuView(windowsDataManager: windowsDataManager)
                .offset(x: windowsDataManager.showMenu ? 0 : -getRect().width)
        }
        
    }
}

#Preview {
    SkeletonView()
}
