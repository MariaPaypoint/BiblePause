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
    @State private var currentExcerpt: String = "mat 1"
    @State private var currentExcerptTitle: String = "Евангелие от Матфея"
    @State private var currentExcerptSubtitle: String = "Глава 1"
    @State private var currentExcerptIsSingleChapter: Bool = true
    
    // не имеет значения здесь
    @State private var showSelectionAsPartOfRead: Bool = false
    
    var body: some View {
        
        ZStack {
            Color("DarkGreen")
                .edgesIgnoringSafeArea(.all)
            
            if selectedMenuItem == .main {
                PageMainView(showMenu: $showMenu,
                             selectedMenuItem: $selectedMenuItem)
            }
            
            if selectedMenuItem == .read {
                PageReadView(showMenu: $showMenu,
                             selectedMenuItem: $selectedMenuItem, 
                             currentExcerpt: $currentExcerpt,
                             currentExcerptTitle: $currentExcerptTitle,
                             currentExcerptSubtitle: $currentExcerptSubtitle,
                             currentExcerptIsSingleChapter: $currentExcerptIsSingleChapter)
                //.opacity(selectedMenuItem == .read ? 1 : 0)
            }
            
            if selectedMenuItem == .select {
                PageSelectView(showMenu: $showMenu,
                               selectedMenuItem: $selectedMenuItem,
                               showFromRead: $showSelectionAsPartOfRead,
                               currentExcerpt: $currentExcerpt,
                               currentExcerptTitle: $currentExcerptTitle,
                               currentExcerptSubtitle: $currentExcerptSubtitle)
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
