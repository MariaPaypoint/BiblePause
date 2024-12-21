//
//  PageSelectView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI

struct PageSelectView: View {
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Binding var showFromRead: Bool
    @State private var scrollToTop = false
    
    @State private var selectedBiblePartIndex: Int = -1 // 0 - ВЗ, 1 - НЗ
    @State private var expandedBook: Int = 0
    @State private var needSelectedBookOpen: Bool = true
    
    @State private var translationInfo: Components.Schemas.TranslationInfoModel?
    @State private var loadedTranslation: Int = 0
    
    @State private var isLoading = false
    @State private var loadingError = ""

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
                                .environmentObject(settingsManager)
                        }
                        Spacer()
                        
                        Text("Выберите")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .padding(.trailing, 32) // компенсация меню, чтобы надпись была по центру
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    
                    if isLoading {
                        Spacer()
                        // вообще надо бы лоадер отображать
                    }
                    else if loadingError == "" {
                        viewSelectTestament()
                        viewBooksList()
                    }
                    else {
                        Spacer()
                        Text("Error: \(loadingError)")
                            .foregroundColor(.white)
                        Spacer()
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
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
            
        }
        .onAppear {
            if settingsManager.translation != self.loadedTranslation {
                //Task {
                if fetchTranslationInfo() {
                    self.loadedTranslation = settingsManager.translation
                }
                //}
                
            }
        }
    }
    
    // MARK: fetchTranslationInfo
    func fetchTranslationInfo() -> Bool {
        Task {
            do {
                self.isLoading = true
                
                let response = try await settingsManager.client.get_translation_info(query: .init(translation:  settingsManager.translation))
                let translationInfoResponse = try response.ok.body.json
                
                self.translationInfo = translationInfoResponse
                
                self.isLoading = false
                self.loadingError = ""
                return true
            } catch {
                self.isLoading = false
                self.loadingError = error.localizedDescription
            }
            return false
        }
        return false
    }
    
    // MARK: Выбор завета
    fileprivate func viewSelectTestament() -> some View {
        return viewSegmentedButtons(arr: bibleParts,
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
    }
    
    // MARK: Список глав
    @ViewBuilder fileprivate func viewChaptersList(_ book: Components.Schemas.BookInfoModel) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 6), spacing: 15) {
            ForEach(1...book.chapters_count, id: \.self) { chapter_number in
                Button(action: {
                    // MARK: При выборе главы
                    settingsManager.currentExcerpt = "\(book.alias) \(chapter_number)"
                    settingsManager.currentExcerptTitle = book.name
                    settingsManager.currentExcerptSubtitle = "Глава \(chapter_number)"
                    settingsManager.selectedMenuItem = .read
                    withAnimation(Animation.easeInOut(duration: 1)) {
                        showFromRead = false
                    }
                    
                }) {
                    if settingsManager.currentBookId == book.number && settingsManager.currentChapterId == chapter_number {
                        Text("\(chapter_number)").frame(maxWidth: .infinity)
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
                        Text("\(chapter_number)").frame(maxWidth: .infinity)
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
    
    // MARK: Список книг
    @ViewBuilder fileprivate func viewBooksList() -> ScrollViewReader<some View> {
        ScrollViewReader { proxy in
            ScrollView() {
                VStack(alignment: .leading) {
                    Color.clear
                        .frame(height: 0)
                        .id("top")
                    
                    /*
                    let oldbooks = globalBibleText.getCurrentTranslation().books
                    ForEach(Array(oldbooks.enumerated()), id: \.element.id) { index, book in
                        if (selectedBiblePartIndex == 0 && index < 39) || (selectedBiblePartIndex == 1 && index >= 39) || selectedBiblePartIndex == -1 {
                            if let headerTitle = bibleHeaders[index] {
                                viewGroupHeader(text: headerTitle)
                            }
                            // Разворачивание книги
                            Button {
                                withAnimation {
                                    expandedBook = book.id
                                    
                                    if book.id != settingsManager.currentBookId {
                                        needSelectedBookOpen = false
                                    }
                                    
                                    proxy.scrollTo("book_\(book.id)", anchor: .top)
                                }
                            } label: {
                                Text(book.fullName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                                    .id("book_\(book.id)")
                            }
                            
                            if expandedBook == book.id || (settingsManager.currentBookId == book.id && needSelectedBookOpen) {
                                viewChaptersList(book)
                            }
                        }
                    }
                     */
                    if (self.translationInfo != nil) {
                        ForEach(self.translationInfo!.books_info, id: \.code) { book in
                            if (selectedBiblePartIndex == 0 && book.number < 39) || (selectedBiblePartIndex == 1 && book.number >= 39) || selectedBiblePartIndex == -1 {
                                
                                if let headerTitle = bibleHeaders[book.number] {
                                    viewGroupHeader(text: headerTitle)
                                }
                                
                                // Разворачивание книги
                                Button {
                                    
                                     withAnimation {
                                         expandedBook = book.number
                                     
                                         if book.number != settingsManager.currentBookId {
                                            needSelectedBookOpen = false
                                         }
                                     
                                         proxy.scrollTo("book_\(book.number)", anchor: .top)
                                     }
                                     
                                } label: {
                                    Text(book.name)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 10)
                                        .id("book_\(book.number)")
                                }
                                 
                                if expandedBook == book.number || (settingsManager.currentBookId == book.number && needSelectedBookOpen) {
                                    viewChaptersList(book)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(Color("localAccentColor"))
                
            }
            .frame(maxHeight: .infinity)
            .onAppear {
                proxy.scrollTo("book_\(settingsManager.currentBookId)", anchor: .top)
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
    
}


struct TestPageSelectView: View {
    
    @State private var showFromRead: Bool = true
    
    var body: some View {
        PageSelectView(showFromRead: $showFromRead)
            .environmentObject(SettingsManager())
    }
}


#Preview {
    TestPageSelectView()
}
