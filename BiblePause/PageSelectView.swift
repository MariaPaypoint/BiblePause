//
//  PageSelectView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

import SwiftUI

struct PageSelectView: View {
    
    @Binding var showMenu: Bool
    @Binding var menuItem: MenuItem
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 20) {
                MenuButtonView(
                    showMenu: $showMenu,
                    menuItem: $menuItem)
                .padding(.bottom, 50)
                
                Text("Select")
                
                // и все толкнем наверх
                Spacer()
            }
            .padding(20)
            // подложка
            .background(
                Color("ForestGreen")
            )
            
            // слой меню
            MenuView(showMenu: $showMenu,
                     menuItem: $menuItem
            )
                .offset(x: showMenu ? 0 : -getRect().width)
        }
    }
}

struct TestPageSelectView: View {
    
    @State var showMenu: Bool = false
    @State var menuItem: MenuItem = .read
    
    var body: some View {
        PageSelectView(showMenu: $showMenu,
                     menuItem: $menuItem)
    }
}

#Preview {
    TestPageSelectView()
}
