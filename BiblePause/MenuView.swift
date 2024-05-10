//
//  MenuView.swift
//  BiblePause
//
//  Created by Maria Novikova on 09.05.2024.
//

import SwiftUI



// Menu View...
struct MenuView: View{
    
    @Binding var showMenu: Bool
    @Binding var animatePath: Bool
    @Binding var animateBG: Bool
    
    var body: some View{
        
        ZStack{
            
            // Blur View...
            BlurView(style: .systemUltraThinMaterialDark)
            
            // Blending With Color..
            Color("1st")
                .opacity(0.2)
                .blur(radius: 15)
            
            // Content...
            VStack(alignment: .leading, spacing: UIScreen.main.bounds.height < 750 ? 20 : 25) {
                
                // Close...
                Button {
                    // Animating Path with little Delay...
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3)){
                        animatePath.toggle()
                    }
                    withAnimation{
                        animateBG.toggle()
                    }
                    withAnimation(.spring().delay(0.1)){
                        showMenu.toggle()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .fontWeight(.light)
                }
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.bottom, 15)

                // Menu Buttons...
                NavigationLink {
                    Text("234")
                } label: {
                    MenuTitle(title: "Главное окно")
                }
                MenuTitle(title: "Продолжить чтение", subTitle: "Евангелие от Иоанна, Глава 1")
                    .foregroundColor(Color("2nd").opacity(0.5))
                MenuTitle(title: "Выбрать", subTitle: "Выберите книгу и главу Библии", selected: true)
                MenuTitle(title: "Настройки")
                MenuTitle(title: "Контакты и донаты", subTitle: "Донат, кстати, на новый проект")
                
                Spacer(minLength: 10)
                
                Text("Версия 1.0.2")
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .padding(.trailing,120)
            .padding()
            .padding(.top,getSafeArea().top)
            .padding(.bottom,getSafeArea().bottom)
            .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .topLeading)
        }
        .clipShape(MenuShape(value: animatePath ? 150 : 0))
        .background(
        
            MenuShape(value: animatePath ? 150 : 0)
                .stroke(
                
                    .linearGradient(.init(colors: [
                    
                        Color("2nd"),
                        Color("3rd")
                            .opacity(0.7),
                        Color("4th")
                            .opacity(0.7),
                        Color.clear,
                        
                    ]), startPoint: .top, endPoint: .bottom),
                    lineWidth: animatePath ? 7 : 0
                )
                .padding(.leading,-50)
        )
        // Custom Shape....
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    func MenuTitle(title: String, subTitle: String="", selected: Bool = false) -> some View {
        
        //let isSmall = UIScreen.main.bounds.height < 750
        
        VStack(alignment: .leading, spacing: 4) {
            
            Text(title)
                .font(.system(.headline))
                .fontWeight(.bold)
                .foregroundColor(selected ? Color("4th").opacity(0.9) : Color.white.opacity(0.9))
            
            Text(subTitle)
                .font(.system(size: 14))
                .foregroundColor(selected ? Color("4th").opacity(0.9) : Color.white.opacity(0.9))
        }
    }
}

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
            
            path.addCurve(to: CGPoint(x: width, y: height + 100), control1: CGPoint(x: width + value, y: height / 3), control2: CGPoint(x: width - value, y: height / 2))
        }
    }
}

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


struct TestView: View {
    
    @State var showMenu: Bool = true
    
    @State var animatePath: Bool = true
    @State var animateBG: Bool = true
    
    var body: some View {
        
        ZStack{
            
            MenuView(showMenu: $showMenu,animatePath: $animatePath,animateBG: $animateBG)
                .offset(x: showMenu ? 0 : -getRect().width)
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

