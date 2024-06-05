//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

struct SkeletonView: View {
    
    @State var showMenu: Bool = false
    @State var menuItem: MenuItem = .main
        
    var body: some View {
        
        ZStack {
            if menuItem == .main {
                PageMainView(showMenu: $showMenu,
                             menuItem: $menuItem)
            }
            else if menuItem == .read {
                PageReadView(showMenu: $showMenu,
                             menuItem: $menuItem)
            }
            else if menuItem == .select {
                PageSelectView(showMenu: $showMenu,
                               menuItem: $menuItem)
            }
            
            
            // слой меню
            MenuView(
                showMenu: $showMenu,
                menuItem: $menuItem)
                .offset(x: showMenu ? 0 : -getRect().width)
        }
    }
}

#Preview {
    SkeletonView()
}
