//
//  PageSelectView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI




struct PageSelectView: View {
    
    @Binding var showMenu: Bool
    @Binding var selectedMenuItem: MenuItem
    
    @State var selectedBiblePartIndex: Int = 1
    @State var expandedBooks: Set<Int> = []

    var body: some View {
        
        ZStack {
            VStack(spacing: 0) {
                
                VStack(spacing: 0) {
                    // MARK: шапка
                    HStack {
                        MenuButtonView(
                            showMenu: $showMenu,
                            selectedMenuItem: $selectedMenuItem)
                        
                        Spacer()
                        
                        Text("Выберите")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .padding(.trailing, 32) // компенсация меню, чтобы надпись была по центру
                        
                        Spacer()
                        
                        //Image(systemName: "textformat.size")
                        //    .font(.title2)
                    }
                    .foregroundColor(.white)
                    
                    // MARK: Выбор завета
                    viewSegmentedButtons(arr: bibleParts,
                                         selIndex: selectedBiblePartIndex,
                                         baseColor: Color("Marigold"), 
                                         bgColor: Color("DarkGreen-light")
                    ) { selectedIndex in
                        self.setBiblePart(index: selectedIndex)
                    }
                    .padding(.vertical, 15)
                    .font(.title)
                    
                    // MARK: Список
                    ScrollView() {
                        VStack(alignment: .leading) {
                            let books = globalBibleText.getCurrentTranslation().books
                            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                                if let headerTitle = bibleHeaders[index] {
                                    Text(headerTitle)
                                        .textCase(.uppercase)
                                        .padding(.top, 30)
                                        .padding(.bottom, 10)
                                        .foregroundColor(Color("localAccentColor").opacity(0.5))
                                }
                                Text(book.fullName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .padding(.vertical, 10)
                                    //
                                    .onTapGesture {
                                        withAnimation {
                                            toggleBookExpansion(bookId: book.id)
                                        }
                                    }
                                if expandedBooks.contains(book.id) {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 6), spacing: 15) {
                                            ForEach(book.chapters) { chapter in
                                                Button(action: {
                                                    // Действие при нажатии на кнопку главы
                                                    withAnimation() {
                                                        selectedMenuItem = .read
                                                    }
                                                }) {
                                                    Text("\(chapter.id)").frame(maxWidth: .infinity)
                                                        .padding(10)
                                                        .foregroundColor(.white)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 5)
                                                                .stroke(Color.white, lineWidth: 1)
                                                        )
                                                        .fontWeight(.bold)
                                                }
                                            }
                                        }
                                        .padding(.bottom, 10)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color("localAccentColor"))
                        
                    }
                    .frame(maxHeight: .infinity)
                    
                    //Spacer()
                    
                }
                .padding(.horizontal, globalBasePadding)
                .padding(.top, globalBasePadding)
                
                //
                
            }
            // подложка
            .background(
                Color("DarkGreen")
            )
            
            // слой меню
            MenuView(showMenu: $showMenu,
                     selectedMenuItem: $selectedMenuItem
            )
            .offset(x: showMenu ? 0 : -getRect().width)
        }
        
    }
    
    private func setBiblePart(index: Int) {
        
        selectedBiblePartIndex = index
        //globalBibleText.setCurrentTranslation(index: index)
        
    }
    
    func toggleBookExpansion(bookId: Int) {
        if expandedBooks.contains(bookId) {
            expandedBooks.remove(bookId)
        } else {
            expandedBooks.insert(bookId)
        }
    }

}

struct TestPageSelectView: View {
    
    @State var showMenu: Bool = false
    @State var selectedMenuItem: MenuItem = .read
    
    var body: some View {
        PageSelectView(showMenu: $showMenu,
                       selectedMenuItem: $selectedMenuItem)
    }
}

#Preview {
    TestPageSelectView()
}