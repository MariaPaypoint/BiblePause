import SwiftUI

struct PageProgressView: View {
    
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showResetConfirmation = false
    @State private var booksInfo: [Components.Schemas.TranslationBookModel] = []
    @State private var isLoading = false
    @State private var showMenuForBook: Int? = nil
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    // MARK: Header
                    HStack {
                        MenuButtonView()
                            .environmentObject(settingsManager)
                        Spacer()
                        Text("page.progress.title".localized)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Button {
                            showResetConfirmation = true
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.bottom, 10)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if !booksInfo.isEmpty {
                        ScrollView {
                            VStack(spacing: 20) {
                                // MARK: Overall stats
                                let totalProgress = settingsManager.getTotalProgress(books: booksInfo)
                                
                                VStack(spacing: 10) {
                                    Text("progress.total".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    // Progress bar with overlayed percent
                                    ZStack {
                                        // Progress bar background
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.3))
                                            .frame(height: 24)
                                        
                                        GeometryReader { geometry in
                                            let progressWidth = geometry.size.width * CGFloat(totalProgress.read) / CGFloat(totalProgress.total)
                                            let progressPercent = CGFloat(totalProgress.read) / CGFloat(totalProgress.total)
                                            
                                            // Green progress fill
                                            HStack(spacing: 0) {
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                                .frame(width: progressWidth, height: 24)
                                                
                                                Spacer(minLength: 0)
                                            }
                                            .clipShape(
                                                UnevenRoundedRectangle(
                                                    topLeadingRadius: 6,
                                                    bottomLeadingRadius: 6,
                                                    bottomTrailingRadius: progressPercent > 0.98 ? 6 : 0,
                                                    topTrailingRadius: progressPercent > 0.98 ? 6 : 0
                                                )
                                            )
                                        }
                                        .frame(height: 24)
                                        
                                        // Percentage label on top of the bar
                                        Text(String(format: "%.1f%%", Double(totalProgress.read) / Double(totalProgress.total) * 100))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // MARK: Progress by books
                                VStack(alignment: .leading, spacing: 12) {
                                    // Books currently in progress
                                    let inProgressBooks = booksInfo.filter { book in
                                        let progress = settingsManager.getBookProgress(book: book.alias, totalChapters: book.chapters_count)
                                        return progress.read > 0 && progress.read < progress.total
                                    }
                                    
                                    if !inProgressBooks.isEmpty {
                                        Text("progress.books_in_progress".localized)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.top, inProgressBooks.isEmpty ? 0 : globalBasePadding)
                                        
                                        ForEach(inProgressBooks, id: \.code) { book in
                                            bookProgressCard(book: book)
                                        }
                                    }
                                    
                                    // Books not yet started
                                    let unstartedBooks = booksInfo.filter { book in
                                        let progress = settingsManager.getBookProgress(book: book.alias, totalChapters: book.chapters_count)
                                        return progress.read == 0
                                    }
                                    
                                    if !unstartedBooks.isEmpty {
                                        Text("progress.unstarted_books".localized)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.top, inProgressBooks.isEmpty ? 0 : globalBasePadding)
                                        
                                        ForEach(unstartedBooks, id: \.code) { book in
                                            bookProgressCard(book: book)
                                        }
                                    }
                                    
                                    // Completed books
                                    let completedBooks = booksInfo.filter { book in
                                        let progress = settingsManager.getBookProgress(book: book.alias, totalChapters: book.chapters_count)
                                        return progress.read > 0 && progress.read == progress.total
                                    }
                                    
                                    if !completedBooks.isEmpty {
                                        Text("progress.completed_books".localized)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.top, (inProgressBooks.isEmpty && unstartedBooks.isEmpty) ? 0 : globalBasePadding)
                                        
                                        ForEach(completedBooks, id: \.code) { book in
                                            bookProgressCard(book: book)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, globalBasePadding)
            }
            .background(Color("DarkGreen"))
            
            // Menu layer
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
        }
        .alert("progress.reset_confirmation.title".localized, isPresented: $showResetConfirmation) {
            Button("progress.reset_confirmation.cancel".localized, role: .cancel) { }
            Button("progress.reset_confirmation.reset".localized, role: .destructive) {
                settingsManager.resetProgress()
            }
        } message: {
            Text("progress.reset_confirmation.message".localized)
        }
        .onAppear {
            loadBooks()
        }
    }
    
    func loadBooks() {
        Task {
            do {
                isLoading = true
                let books = try await settingsManager.getTranslationBooks()
                self.booksInfo = books
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
    
    @ViewBuilder
    func bookProgressCard(book: Components.Schemas.TranslationBookModel) -> some View {
        let progress = settingsManager.getBookProgress(book: book.alias, totalChapters: book.chapters_count)
        let isCompleted = progress.read == progress.total
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(book.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(progress.read)/\(progress.total)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Button {
                    showMenuForBook = book.code
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16))
                        .padding(.leading, 8)
                }
            }
            
            // Segmented progress bar
            GeometryReader { geometry in
                let spacing: CGFloat = progress.total > 50 ? 0 : 1
                let totalSpacing = spacing * CGFloat(progress.total - 1)
                
                HStack(spacing: spacing) {
                    ForEach(1...progress.total, id: \.self) { chapter in
                        let isRead = settingsManager.isChapterRead(book: book.alias, chapter: chapter)
                        let segmentWidth = (geometry.size.width - totalSpacing) / CGFloat(progress.total)
                        
                        Rectangle()
                            .fill(isRead ? (isCompleted ? Color.green : Color("Marigold")) : Color.white.opacity(0.2))
                            .frame(width: segmentWidth, height: 8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
        )
        .confirmationDialog("", isPresented: Binding(
            get: { showMenuForBook == book.code },
            set: { if !$0 { showMenuForBook = nil } }
        )) {
            if !isCompleted {
                let nextChapter = findNextUnreadChapter(book: book, totalChapters: progress.total)
                Button("progress.read_chapter".localized(nextChapter)) {
                    navigateToUnreadChapter(book: book, progress: progress)
                }
            }
            
            if !isCompleted {
                Button("progress.mark_all_as_read".localized) {
                    settingsManager.markBookAsRead(book: book.alias, totalChapters: book.chapters_count)
                }
            }
            
            Button("progress.reset_book".localized, role: .destructive) {
                settingsManager.resetBookProgress(book: book.alias, totalChapters: book.chapters_count)
            }
            
            Button("progress.reset_confirmation.cancel".localized, role: .cancel) {}
        }
    }
    
    
    func findNextUnreadChapter(book: Components.Schemas.TranslationBookModel, totalChapters: Int) -> Int {
        for chapter in 1...totalChapters {
            if !settingsManager.isChapterRead(book: book.alias, chapter: chapter) {
                return chapter
            }
        }
        return 1 // Fallback
    }
    
    func navigateToUnreadChapter(book: Components.Schemas.TranslationBookModel, progress: (read: Int, total: Int)) {
        // Locate the first unread chapter
        let nextChapter = findNextUnreadChapter(book: book, totalChapters: progress.total)
        
        // Close menu if it is open
        if settingsManager.showMenu {
            withAnimation(.spring().delay(0.1)) {
                settingsManager.showMenu = false
            }
        }
        
        // Update current excerpt selection
        settingsManager.currentExcerpt = "\(book.alias) \(nextChapter)"
        settingsManager.currentExcerptTitle = book.name
        settingsManager.currentExcerptSubtitle = "chapter.title".localized(nextChapter)
        
        // Switch to the reading page
        settingsManager.selectedMenuItem = .read
    }
}

struct TestPageProgressView: View {
    var body: some View {
        PageProgressView()
            .environmentObject(SettingsManager())
    }
}

#Preview {
    TestPageProgressView()
}
