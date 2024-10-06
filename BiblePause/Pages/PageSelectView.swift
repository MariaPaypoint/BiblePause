//
//  PageSelectView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

struct PageSelectView: View {
    
    @EnvironmentObject var windowsDataManager: WindowsDataManager
    
    @Binding var showFromRead: Bool
    @State private var scrollToTop = false
    
    @State private var selectedBiblePartIndex: Int = -1 // 0 - ВЗ, 1 - НЗ
    @State private var expandedBook: Int = 0
    @State private var needSelectedBookOpen: Bool = true

    var body: some View {
        
        ZStack {
            VStack(spacing: 0) {
                
                VStack(spacing: 0) {
                    // MARK: шапка
                    HStack {
                        if showFromRead {
                            
                            Button {
                                showFromRead = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .fontWeight(.light)
                            }
                            .foregroundColor(Color.white.opacity(0.5))
                        }
                        else {
                            MenuButtonView()
                                .environmentObject(windowsDataManager)
                        }
                        Spacer()
                        
                        Text("Выберите")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .padding(.trailing, 32) // компенсация меню, чтобы надпись была по центру
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
                    // MARK: Выбор завета
                    viewSegmentedButtons(arr: bibleParts,
                                         selIndex: selectedBiblePartIndex,
                                         baseColor: Color("Marigold"),
                                         bgColor: Color("DarkGreen-light")
                    ) { selectedIndex in
                        if selectedBiblePartIndex == selectedIndex {
                            // повторный клик - отмена выделения
                            selectedBiblePartIndex = -1
                        }
                        else {
                            selectedBiblePartIndex = selectedIndex
                        }
                        scrollToTop.toggle()
                    }
                    .padding(.vertical, 15)
                    .font(.title)
                    
                    // MARK: Список
                    ScrollViewReader { proxy in
                        ScrollView() {
                            VStack(alignment: .leading) {
                                Color.clear
                                    .frame(height: 0)
                                    .id("top")

                                let books = globalBibleText.getCurrentTranslation().books
                                ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                                    if (selectedBiblePartIndex == 0 && index < 39) || (selectedBiblePartIndex == 1 && index >= 39) || selectedBiblePartIndex == -1 {
                                        if let headerTitle = bibleHeaders[index] {
                                            viewGroupHeader(text: headerTitle)
                                        }
                                        // MARK: Разворачивание книги
                                        Button {
                                            withAnimation {
                                                expandedBook = book.id
                                                
                                                if book.id != windowsDataManager.currentBookId {
                                                    needSelectedBookOpen = false
                                                }
                                                
                                                proxy.scrollTo("book_\(book.id)", anchor: .top)
                                            }
                                        } label: {
                                            Text(book.fullName)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                //.frame(width: .infinity)
                                                .padding(.vertical, 10)
                                                .id("book_\(book.id)")
                                        }
                                        
                                        if expandedBook == book.id || (windowsDataManager.currentBookId == book.id && needSelectedBookOpen) {
                                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 6), spacing: 15) {
                                                ForEach(book.chapters) { chapter in
                                                    Button(action: {
                                                        // MARK: Действие при нажатии на кнопку главы
                                                        windowsDataManager.currentExcerpt = "\(book.code) \(chapter.id)"
                                                        windowsDataManager.currentExcerptTitle = book.fullName
                                                        windowsDataManager.currentExcerptSubtitle = "Глава \(chapter.id)"
                                                        windowsDataManager.selectedMenuItem = .read
                                                        withAnimation(Animation.easeInOut(duration: 1)) {
                                                            showFromRead = false
                                                        }
                                                        
                                                    }) {
                                                        if windowsDataManager.currentBookId == book.id && windowsDataManager.currentChapterId == chapter.id {
                                                            Text("\(chapter.id)").frame(maxWidth: .infinity)
                                                                .padding(.vertical, 10)
                                                            //.foregroundColor(Color("DarkGreen"))
                                                                .background(.white.opacity(0.3))
                                                                .cornerRadius(5)
                                                                .overlay(
                                                                    RoundedRectangle(cornerRadius: 5)
                                                                        .stroke(Color.white, lineWidth: 1)
                                                                )
                                                                .fontWeight(.bold)
                                                        } else {
                                                            Text("\(chapter.id)").frame(maxWidth: .infinity)
                                                                .padding(.vertical, 10)
                                                                .foregroundColor(.white)
                                                                .overlay(
                                                                    RoundedRectangle(cornerRadius: 5)
                                                                        .stroke(Color.white, lineWidth: 1)
                                                                )
                                                                .fontWeight(.bold)
                                                            
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.bottom, 10)
                                            .padding(1)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color("localAccentColor"))
                            
                        }
                        .frame(maxHeight: .infinity)
                        .onAppear {
                            proxy.scrollTo("book_\(windowsDataManager.currentBookId)", anchor: .top)
                        }
                        .onChange(of: scrollToTop) { oldValue, newValue in
                            if newValue {
                                withAnimation {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                                // Сбрасываем флаг после прокрутки
                                scrollToTop = false
                            }
                        }
                        //Spacer()
                    }
                }
                .padding(.horizontal, globalBasePadding)
            }
            // подложка
            .background(
                Color("DarkGreen")
            )
            
            
            // слой меню
            MenuView()
                .environmentObject(windowsDataManager)
                .offset(x: windowsDataManager.showMenu ? 0 : -getRect().width)
            
        }
    }
}


struct TestPageSelectView: View {
    
    @State private var showFromRead: Bool = true
    @StateObject var windowsDataManager = WindowsDataManager()
    
    var body: some View {
        PageSelectView(showFromRead: $showFromRead)
            .environmentObject(windowsDataManager)
    }
}


#Preview {
    TestPageSelectView()
}
