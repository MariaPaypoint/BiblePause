//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

struct SkeletonView: View {
    
    @State private var showMenu: Bool = false
    @State private var selectedMenuItem: MenuItem = .main
    
    @State private var currentTranslationIndex: Int = globalBibleText.getCurrentTranslationIndex()
    @State private var currentExcerpt: String = "mat 3:2-3"
    @State private var currentExcerptTitle: String = "Евангелие от Матфея"
    @State private var currentExcerptSubtitle: String = "Глава 3:2-3"
    @State private var currentExcerptIsSingleChapter: Bool = true
    @State private var currentBookId: Int = 0
    @State private var currentChapterId: Int = 0
    
    // не имеет значения здесь
    @State private var showAsPartOfRead: Bool = false
    
    @AppStorage("fontIncreasePercent") private var fontIncreasePercent: Double = 100.0
    
    @AppStorage("pauseType") private var pauseType: PauseType = .none
    @AppStorage("pauseLength") private var pauseLength: Double = 3.0
    @AppStorage("pauseBlock") private var pauseBlock: PauseBlock = .verse
    
    var body: some View {
        
        ZStack {
            Color("DarkGreen")
                .edgesIgnoringSafeArea(.all)
            
            if selectedMenuItem == .main {
                PageMainView(showMenu: $showMenu,
                             selectedMenuItem: $selectedMenuItem)
            }
            
            else if selectedMenuItem == .read {
                PageReadView(showMenu: $showMenu,
                             selectedMenuItem: $selectedMenuItem, 
                             currentExcerpt: $currentExcerpt,
                             currentExcerptTitle: $currentExcerptTitle,
                             currentExcerptSubtitle: $currentExcerptSubtitle,
                             currentExcerptIsSingleChapter: $currentExcerptIsSingleChapter,
                             currentBookId: $currentBookId,
                             currentChapterId: $currentChapterId, 
                             fontIncreasePercent: $fontIncreasePercent,
                             pauseType: $pauseType,
                             pauseLength: $pauseLength,
                             pauseBlock: $pauseBlock)
            }
            
            else if selectedMenuItem == .select {
                PageSelectView(showMenu: $showMenu,
                               selectedMenuItem: $selectedMenuItem,
                               showFromRead: $showAsPartOfRead,
                               currentExcerpt: $currentExcerpt,
                               currentExcerptTitle: $currentExcerptTitle,
                               currentExcerptSubtitle: $currentExcerptSubtitle,
                               currentBookId: $currentBookId,
                               currentChapterId: $currentChapterId)
            }
            
            else if selectedMenuItem == .setup {
                PageSetupView(showMenu: $showMenu,
                              selectedMenuItem: $selectedMenuItem,
                              showFromRead: $showAsPartOfRead,
                              fontIncreasePercent: $fontIncreasePercent,
                              pauseType: $pauseType,
                              pauseLength: $pauseLength,
                              pauseBlock: $pauseBlock)
            }
            
            else if selectedMenuItem == .contacts {
                PageContactsView()
            }
            // слой меню
            MenuView(
                showMenu: $showMenu,
                selectedMenuItem: $selectedMenuItem)
            .offset(x: showMenu ? 0 : -getRect().width)
        }
        
    }
}

#Preview {
    SkeletonView()
}
