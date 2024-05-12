//
//  PageReadView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

struct PageReadView: View {
    
    @Binding var showMenu: Bool
    @Binding var animatePath: Bool
    @Binding var animateBG: Bool
    @Binding var menuItem: MenuItem
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 0) {
                
                // шапка
                HStack {
                    MenuButtonView(
                        showMenu: $showMenu,
                        animatePath: $animatePath,
                        animateBG: $animateBG,
                        menuItem: $menuItem)
                    
                    Spacer()
                    
                    Text("Название книги")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    
                    Spacer()
                    
                    Image(systemName: "textformat.size")
                        .font(.title2)
                }
                .foregroundColor(.white)
                
                Text("Глава X")
                    .foregroundColor(Color("3rd"))
                    .font(.title3)
                
                // и все толкнем наверх
                Spacer()
            }
            .padding(20)
            // подложка
            .background(
                Color("1st")
            )
            
            // слой меню
            MenuView(showMenu: $showMenu,
                     animatePath: $animatePath,
                     animateBG: $animateBG,
                     menuItem: $menuItem
            )
            .offset(x: showMenu ? 0 : -getRect().width)
        }
    }
}

struct TestPageReadView: View {
    
    @State var showMenu: Bool = false
    @State var animatePath: Bool = false
    @State var animateBG: Bool = false
    @State var menuItem: MenuItem = .read
    
    var body: some View {
        PageReadView(showMenu: $showMenu,
                     animatePath: $animatePath,
                     animateBG: $animateBG,
                     menuItem: $menuItem)
    }
}

#Preview {
    TestPageReadView()
}
