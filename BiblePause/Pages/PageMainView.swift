//
//  ContentView.swift
//  BiblePause
//
//  Created by Maria Novikova on 09.05.2024.
//

import SwiftUI

struct PageMainView: View {
    
    @ObservedObject var windowsDataManager: WindowsDataManager
    
    //@Binding var showMenu: Bool
    //@Binding var selectedMenuItem: MenuItem
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    MenuButtonView(windowsDataManager: windowsDataManager)
                    .padding(.bottom, 50)
                    Spacer()
                }
                // заголовок
                Image("TitleRus")
                
                // кнопка
                Button {
                    
                } label: {
                    VStack {
                        Text("Продолжить чтение")
                            .foregroundColor(Color("ForestGreen"))
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, weight: .heavy))
                        Text("Евангелие от Иоанна, Глава 1")
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
            MenuView(windowsDataManager: windowsDataManager)
            .offset(x: windowsDataManager.showMenu ? 0 : -getRect().width)
        }
    }
}

struct TestPageMainView: View {
    
    @StateObject var windowsDataManager = WindowsDataManager()
    
    var body: some View {
        PageMainView(windowsDataManager: windowsDataManager)
    }
}

#Preview {
    TestPageMainView()
}
