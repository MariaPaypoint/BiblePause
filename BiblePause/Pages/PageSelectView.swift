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
    
    @State private var booksInfo: [Components.Schemas.TranslationBookModel] = []
    
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
                        ProgressView()
                            .tint(.white)
                        Spacer()
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
            fetchTranslationBooks()
        }
    }
    
    // MARK: fetchTranslationBooks
    func fetchTranslationBooks() {
        Task {
            do {
                self.isLoading = true
                self.loadingError = ""
                
                // Используем кешированный метод из SettingsManager
                let books = try await settingsManager.getTranslationBooks()
                
                self.booksInfo = books
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.loadingError = error.localizedDescription
            }
        }
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
    @ViewBuilder fileprivate func viewChaptersList(_ book: Components.Schemas.TranslationBookModel) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 6), spacing: 15) {
            ForEach(1...book.chapters_count, id: \.self) { chapter_number in
                let hasNoAudio = book.chapters_without_audio?.contains(chapter_number) ?? false
                let hasNoText = book.chapters_without_text?.contains(chapter_number) ?? false
                
                let isCurrentChapter = settingsManager.currentBookId == book.book_number && settingsManager.currentChapterId == chapter_number
                let isRead = settingsManager.isChapterRead(book: book.alias, chapter: chapter_number)
                
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
                    ZStack {
                        Text("\(chapter_number)").frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background(isCurrentChapter ? .white.opacity(0.3) : .clear)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                            .fontWeight(.bold)
                        
                        // Значок отсутствия аудио (слева вверху)
                        if hasNoAudio {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "speaker.slash.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("Mustard"))
                                        .padding(3)
                                }
                            }
                        }
                        
                        // Галочка прочитанной главы (справа вверху)
                        if isRead {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                        .padding(2)
                                }
                                Spacer()
                            }
                        }
                    }
                    .opacity(hasNoText ? 0.3 : 1)
                }
                .disabled(hasNoText)
                .contextMenu {
                    if isRead {
                        Button {
                            settingsManager.markChapterAsUnread(book: book.alias, chapter: chapter_number)
                        } label: {
                            Label("Отметить как непрочитанную", systemImage: "xmark.circle")
                        }
                    } else {
                        Button {
                            settingsManager.markChapterAsRead(book: book.alias, chapter: chapter_number)
                        } label: {
                            Label("Отметить как прочитанную", systemImage: "checkmark.circle")
                        }
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
                    
                    if !self.booksInfo.isEmpty {
                        ForEach(self.booksInfo, id: \.code) { book in
                            if (selectedBiblePartIndex == 0 && book.book_number < 39) || (selectedBiblePartIndex == 1 && book.book_number >= 39) || selectedBiblePartIndex == -1 {
                                
                                if let headerTitle = bibleHeaders[book.book_number] {
                                    viewGroupHeader(text: headerTitle)
                                }
                                
                                // Разворачивание книги
                                Button {
                                    
                                     withAnimation {
                                         expandedBook = book.book_number
                                     
                                         if book.book_number != settingsManager.currentBookId {
                                            needSelectedBookOpen = false
                                         }
                                     
                                         proxy.scrollTo("book_\(book.book_number)", anchor: .top)
                                     }
                                     
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(book.name)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // Прогресс-бар справа от названия
                                        let progress = settingsManager.getBookProgress(book: book.alias, totalChapters: book.chapters_count)
                                        if progress.read > 0 {
                                            let isCompleted = progress.read == progress.total
                                            let progressColor = isCompleted ? Color("Success") : Color("Marigold")
                                            
                                            ZStack {
                                                GeometryReader { geometry in
                                                    ZStack(alignment: .leading) {
                                                        // Фон
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(Color.white.opacity(0.15))
                                                            .frame(height: 20)
                                                        
                                                        // Прогресс
                                                        let progressWidth = geometry.size.width * CGFloat(progress.read) / CGFloat(progress.total)
                                                        let progressPercent = CGFloat(progress.read) / CGFloat(progress.total)
                                                        
                                                        progressColor
                                                            .frame(width: progressWidth, height: 20)
                                                            .mask(
                                                                HStack(spacing: 0) {
                                                                    if progressPercent > 0.98 {
                                                                        RoundedRectangle(cornerRadius: 6)
                                                                    } else {
                                                                        UnevenRoundedRectangle(
                                                                            topLeadingRadius: 6,
                                                                            bottomLeadingRadius: 6,
                                                                            bottomTrailingRadius: 0,
                                                                            topTrailingRadius: 0
                                                                        )
                                                                    }
                                                                }
                                                                .frame(width: progressWidth, height: 20)
                                                            )
                                                    }
                                                }
                                                .frame(height: 20)
                                                
                                                // Счетчик поверх прогресс-бара
                                                Text("\(progress.read) / \(progress.total)")
                                                    .font(.footnote)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                            .frame(width: 100, height: 24)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .id("book_\(book.book_number)")
                                }
                                 
                                if expandedBook == book.book_number || (settingsManager.currentBookId == book.book_number && needSelectedBookOpen) {
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
