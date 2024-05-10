//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

struct SkeletonView: View {
    
    @State var showMenu: Bool = false
    @State var animatePath: Bool = false
    @State var animateBG: Bool = false
    @State var menuItem: MenuItem = .main
        
    var body: some View {
        
        ZStack {
            if menuItem == .main {
                PageMainView(showMenu: $showMenu,
                             animatePath: $animatePath,
                             animateBG: $animateBG,
                             menuItem: $menuItem)
            }
            else if menuItem == .read {
                PageReadView(showMenu: $showMenu,
                             animatePath: $animatePath,
                             animateBG: $animateBG,
                             menuItem: $menuItem)
            }
            else if menuItem == .select {
                PageSelectView(showMenu: $showMenu,
                               animatePath: $animatePath,
                               animateBG: $animateBG,
                               menuItem: $menuItem)
            }
            
            
            // слой меню
            MenuView(
                showMenu: $showMenu,
                animatePath: $animatePath,
                animateBG: $animateBG,
                menuItem: $menuItem)
                .offset(x: showMenu ? 0 : -getRect().width)
        }
    }
}

#Preview {
    SkeletonView()
}
