//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

struct SkeletonView: View {
    
    @State var showMenu: Bool = false
    @State var selectedMenuItem: MenuItem = .main
    
    @State var currentTranslationIndex: Int = globalBibleText.getCurrentTranslationIndex()
        
    var body: some View {
        
        ZStack {
            if selectedMenuItem == .main {
                PageMainView(showMenu: $showMenu,
                             selectedMenuItem: $selectedMenuItem)
            }
            else if selectedMenuItem == .read {
                PageReadView(showMenu: $showMenu,
                             selectedMenuItem: $selectedMenuItem)
                .transition(.move(edge: .trailing))
            }
            else if selectedMenuItem == .select {
                PageSelectView(showMenu: $showMenu,
                               selectedMenuItem: $selectedMenuItem)
                .transition(.move(edge: .leading))
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
