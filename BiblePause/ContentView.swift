//
//  ContentView.swift
//  BiblePause
//
//  Created by Maria Novikova on 09.05.2024.
//

import SwiftUI

struct ContentView: View {
    
    @State var showMenu: Bool = false
    
    @State var animatePath: Bool = false
    @State var animateBG: Bool = false
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 20) {
                // button menu
                HStack {
                    Button {
                        
                        withAnimation{
                            animateBG.toggle()
                        }
                        
                        withAnimation(.spring()){
                            showMenu.toggle()
                        }
                        
                        // Animating Path with little Delay...
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3).delay(0.2)){
                            animatePath.toggle()
                        }
                        
                    } label: {
                        Image("Menu")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 50)
                
                // заголовок
                Image("TitleRus")
                
                // кнопка
                Button {
                    
                } label: {
                    VStack {
                        Text("Продолжить чтение")
                            .foregroundColor(Color("2nd"))
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, weight: .heavy))
                        Text("Евангелие от Иоанна, Глава 1")
                            .foregroundColor(Color("clBrownAdv"))
                            .font(.system(.subheadline))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.7))
                
                // и все толкнем наверх
                Spacer()
            }
            .padding(20)
            // подложка
            .background(
                Image("Forest")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
            
            // слой меню
            MenuView(showMenu: $showMenu,animatePath: $animatePath,animateBG: $animateBG)
                .offset(x: showMenu ? 0 : -getRect().width)
        }
    }
}


#Preview {
    ContentView()
}
