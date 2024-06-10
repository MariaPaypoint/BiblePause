//
//  advElements.swift
//  BiblePause
//
//  Created by Maria Novikova on 08.06.2024.
//

import SwiftUI

// красивые кнопки-переключалки
@ViewBuilder func viewSegmentedButtons(arr: [String], selIndex: Int, baseColor: Color, bgColor: Color, closure:@escaping (_ selectedIndex: Int) -> Void) -> some View {
    
    
    let columns = Array(repeating: GridItem(spacing: 1), count:arr.count)
    LazyVGrid(columns: columns, spacing: 1.0) {
        
        ForEach(Array(arr.enumerated()), id: \.element) { index, name in
            
            
            ZStack {
                
                Rectangle()
                    .foregroundColor(index == selIndex ? baseColor : bgColor)
                    //.cornerRadius(radius: index == 0 ? globalCornerRadius : 0, corners: [.topLeft, .bottomLeft])
                    //.cornerRadius(radius: index == arr.count-1 ? globalCornerRadius : 0, corners: [.topRight, .bottomRight])
                
                Text(name)
                    .padding(.vertical, 10)
                    .font(.callout)
                    //.foregroundColor(index != selIndex ? baseColor : bgColor )
                    .foregroundColor(Color("localAccentColor"))
                
            }
            .contentShape(Rectangle()) // Ensure the entire area is tappable
            .onTapGesture {
                withAnimation {
                    closure(index)
                }
            }
            
        }
         
    }
    .foregroundColor(baseColor)
    //.overlay(
    //    RoundedRectangle(cornerRadius: globalCornerRadius)
    //        .stroke(baseColor, lineWidth: 2)
    //)
    .font(.callout)
    //.background(baseColor)
    .cornerRadius(globalCornerRadius)
    //.padding(.bottom, 10)
     
}
