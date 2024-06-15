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
                             currentChapterId: $currentChapterId)
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
                              showFromRead: $showAsPartOfRead)
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
