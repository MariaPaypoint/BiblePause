//
//  ContentView.swift
//  BiblePause
//
//  Created by Maria Novikova on 09.05.2024.
//

import SwiftUI

struct PageMainView: View {
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    MenuButtonView()
                        .environmentObject(settingsManager)
                        .padding(.bottom, 50)
                    Spacer()
                }
                // заголовок
                Image("TitleRus")
                
                // кнопка
                Button {
                    settingsManager.selectedMenuItem = .read
                } label: {
                    VStack {
                        Text("Продолжить чтение")
                            .foregroundColor(Color("ForestGreen"))
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, weight: .heavy))
                        Text("\(settingsManager.currentExcerptTitle), \(settingsManager.currentExcerptSubtitle)")
                            .foregroundColor(Color("Chocolate"))
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
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
        }
    }
}

struct TestPageMainView: View {
    
    var body: some View {
        PageMainView()
            .environmentObject(SettingsManager())
    }
}

#Preview {
    TestPageMainView()
}
