//
//  MenuView.swift
//  BiblePause
//
//  Created by Maria Novikova on 09.05.2024.
//

import SwiftUI

enum MenuItem {
    case main
    case read
    case select
    case setup
    case contacts
}

struct MenuView: View{
    
    //@Binding var showMenu: Bool
    //@Binding var selectedMenuItem: MenuItem
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View{
        
        ZStack{
            
            // Blur View...
            BlurView(style: .systemUltraThinMaterialDark)
            
            // Blending With Color..
            Color("DarkGreen")
                .opacity(0.2)
                .blur(radius: 15)
            
            // Content...
            VStack(alignment: .leading, spacing: UIScreen.main.bounds.height < 750 ? 20 : 25) {
                
                // MARK: Close Button
                Button {
                    toggleWithAnimation()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .fontWeight(.light)
                }
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.bottom, 15)

                // MARK: Menu Buttons
                Button { changeSelected(selected: .main)     } label: { MenuItem(title: "Главное окно", selected: (settingsManager.selectedMenuItem == .main)) }
                Button { changeSelected(selected: .read)     } label: { MenuItem(title: "Продолжить чтение", subTitle: "Евангелие от Иоанна, Глава 1", selected: (settingsManager.selectedMenuItem == .read)) }
                Button { changeSelected(selected: .select)   } label: { MenuItem(title: "Выбрать", subTitle: "Выберите книгу и главу Библии", selected: (settingsManager.selectedMenuItem == .select)) }
                Button { changeSelected(selected: .setup)    } label: { MenuItem(title: "Настройки", selected: (settingsManager.selectedMenuItem == .setup)) }
                Button { changeSelected(selected: .contacts) } label: { MenuItem(title: "Контакты и донаты", subTitle: "Донат, кстати, на новый проект", selected: (settingsManager.selectedMenuItem == .contacts)) }
                
                Spacer(minLength: 10)
                
                // MARK: Version
                Text("Версия 1.0.2")
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .padding(.trailing,120)
            .padding()
            .padding(.top,getSafeArea().top)
            .padding(.bottom,getSafeArea().bottom)
            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .topLeading)
        }
        .clipShape(
            MenuShape(value: 0)
        )
        .background(
            MenuShape(value: 0)
            
                .stroke(
                    .linearGradient(.init(colors: [
                    
                        Color("ForestGreen"),
                        Color("Mustard")
                            .opacity(0.7),
                        Color("Marigold")
                            .opacity(0.7),
                        //Color.clear,
                        
                    ]), startPoint: .top, endPoint: .bottom),
                    lineWidth: 1 // 2 for line
                )
             
                .padding(.leading,-50)
             
        )
        // Custom Shape....
        .ignoresSafeArea()
    }
    
    func toggleWithAnimation() {
        withAnimation(.spring().delay(0.1)){
            settingsManager.showMenu.toggle()
        }
    }
    
    // MARK: Закрытие меню по выбору пункта
    func changeSelected(selected: MenuItem) {
        toggleWithAnimation()
        settingsManager.selectedMenuItem = selected
        
    }
    
    @ViewBuilder
    func MenuItem(title: String, subTitle: String="", selected: Bool = false) -> some View {
        
        //let isSmall = UIScreen.main.bounds.height < 750
        
        VStack(alignment: .leading, spacing: 4) {
            
            Text(title)
                .font(.system(.headline))
                .fontWeight(.bold)
                .foregroundColor(selected ? Color("Marigold").opacity(0.9) : Color.white.opacity(0.9))
            
            Text(subTitle)
                .font(.system(size: 14))
                .foregroundColor(selected ? Color("Marigold").opacity(0.9) : Color.white.opacity(0.9))
        }
    }
}

// MARK: Изгиб
struct MenuShape: Shape{
    
    var value: CGFloat
    
    // Animating Path...
    var animatableData: CGFloat{
        get{return value}
        set{value = newValue}
    }
    
    func path(in rect: CGRect) -> Path {
        
        return Path{path in
            
            // For Curve Shape 100...
            let width = rect.width - 100
            let height = rect.height
            
            path.move(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            
            // Curve...
            path.move(to: CGPoint(x: width, y: 0))
            
            path.addCurve(to: CGPoint(x: width, y: height),
                          control1: CGPoint(x: width + value, y: height / 3),
                          control2: CGPoint(x: width - value, y: height / 2))
        }
    }
}

// MARK: Кнопка меню др.окон
struct MenuButtonView: View {
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Button {
            withAnimation(.spring()){
                settingsManager.showMenu.toggle()
            }
        } label: {
            /*
             Image(systemName: "line.3.horizontal")
             .foregroundColor(.white)
             .font(.largeTitle)
             .fontWeight(.light)
             */
            Image("Menu")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: Extensions

// Extedning View to get SafeArea...
extension View{
    
    func getSafeArea()->UIEdgeInsets{
        
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else{
            return .zero
        }
        
        guard let safeArea = screen.windows.first?.safeAreaInsets else{
            return .zero
        }
        
        return safeArea
    }
    
    func getRect()->CGRect{
        return UIScreen.main.bounds
    }
}

// Since App Supports iOS 14...
struct BlurView: UIViewRepresentable {
    
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        
    }
}


// MARK: Preview
struct TestView: View {
    
    @StateObject var settingsManager = SettingsManager()
    
    var body: some View {
        
        ZStack{
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
        }
        .background(
            Image("Forest")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        )
    }
}

#Preview {
    TestView()
}

