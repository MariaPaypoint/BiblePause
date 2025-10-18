//
//  advElements.swift
//  BiblePause
//
//  Created by Maria Novikova on 08.06.2024.
//

import SwiftUI

// красивые кнопки-переключалки
@ViewBuilder 
func viewSegmentedButtons(arr: [String], selIndex: Int, baseColor: Color, bgColor: Color, closure:@escaping (_ selectedIndex: Int) -> Void) -> some View {
    
    
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

// заголовок группы
@ViewBuilder
func viewGroupHeader(text: String) -> some View {
    Text(text)
        .textCase(.uppercase)
        .padding(.top, 30)
        .padding(.bottom, 10)
        .foregroundColor(Color("localAccentColor").opacity(0.5))
        .frame(maxWidth: .infinity, alignment: .leading)
}

// выбор из листа
@ViewBuilder
func viewSelectList(texts: [String], keys: [String], selectedKey: Binding<String>,
                    onSelect: @escaping (Int) -> Void = { _ in }) -> some View {
    LazyVStack(alignment: .leading, spacing: 0) {
        ForEach(texts.indices, id: \.self) { index in
            let text = texts[index]
            let key = keys[index]
            HStack {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(selectedKey.wrappedValue == key ? Color("Mustard") : .white)
                    .padding(.vertical, 10)
                Spacer()
                if selectedKey.wrappedValue == key {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color("Mustard"))
                }
            }
            .background(Color("DarkGreen"))
            .onTapGesture {
                selectedKey.wrappedValue = key
                onSelect(index)
            }
        }
    }
}

// выбор из листа с кнопкой предпрослушивания
@ViewBuilder
func viewSelectListWithPreview(texts: [String], keys: [String], selectedKey: Binding<String>,
                                onSelect: @escaping (Int) -> Void = { _ in },
                                onPreview: @escaping (Int) -> Void,
                                isPlaying: @escaping (Int) -> Bool) -> some View {
    LazyVStack(alignment: .leading, spacing: 0) {
        ForEach(texts.indices, id: \.self) { index in
            let text = texts[index]
            let key = keys[index]
            HStack {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(selectedKey.wrappedValue == key ? Color("Mustard") : .white)
                    .padding(.vertical, 10)
                
                Spacer()
                
                // Кнопка предпрослушивания
                Button {
                    onPreview(index)
                } label: {
                    Image(systemName: isPlaying(index) ? "stop.circle.fill" : "play.circle.fill")
                        .foregroundColor(Color("localAccentColor"))
                        .font(.system(size: 24))
                }
                .frame(width: 32)
                
                // Галочка с фиксированной шириной
                Image(systemName: "checkmark")
                    .foregroundColor(Color("Mustard"))
                    .frame(width: 20)
                    .opacity(selectedKey.wrappedValue == key ? 1 : 0)
            }
            .background(Color("DarkGreen"))
            .onTapGesture {
                selectedKey.wrappedValue = key
                onSelect(index)
            }
        }
    }
}

// выбор из выпадающего списка
@ViewBuilder
func viewEnumPicker<T: RawRepresentable & CaseIterable & Identifiable & Hashable & DisplayNameProvider>(
    title: String,
    selection: Binding<T>
) -> some View where T.RawValue == String, T.AllCases: RandomAccessCollection, T.AllCases.Element == T {
    Menu {
        Picker("", selection: selection) {
            ForEach(Array(T.allCases), id: \.self) { value in
                Text(value.displayName).tag(value)
            }
        }
    } label: {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: "chevron.down")
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(Color("DarkGreen-light").opacity(0.6))
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
    }
}
