//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI
import OpenAPIURLSession

// MARK: ReadProgress
struct ReadProgress: Codable {
    var readChapters: Set<String> = [] // ["gen_1", "exo_2", ...]
    var startDate: Date = Date()
}

// MARK: SettingsManager
class SettingsManager: ObservableObject {
    
    @Published var showMenu: Bool = false
    @Published var selectedMenuItem: MenuItem = .main
    
    @AppStorage("fontIncreasePercent") var fontIncreasePercent: Double = 100.0
    
    @AppStorage("pauseType") var pauseType: PauseType = .none
    @AppStorage("pauseLength") var pauseLength: Double = 3.0
    @AppStorage("pauseBlock") var pauseBlock: PauseBlock = .verse
    
    @AppStorage("autoNextChapter") var autoNextChapter: Bool = true
    
    @AppStorage("language") var language: String = "ru"
    @AppStorage("translation") var translation: Int = 1 // syn
    @AppStorage("translationName") var translationName: String = "SYNO"
    @AppStorage("voice") var voice: Int = 1 // prozorovsky
    @AppStorage("voiceName") var voiceName: String = "Александр Бондаренко"
    @AppStorage("voiceMusic") var voiceMusic: Bool = true
    
    @AppStorage("currentExcerpt") var currentExcerpt: String = "jhn 1"
    @AppStorage("currentExcerptTitle") var currentExcerptTitle: String = "От Иоанна святое благовествование"
    @AppStorage("currentExcerptSubtitle") var currentExcerptSubtitle: String = "Глава 1"
    @AppStorage("currentBookId") var currentBookId: Int = 0
    @AppStorage("currentChapterId") var currentChapterId: Int = 0
    
    @AppStorage("currentSpeed") var currentSpeed: Double = 1.0
    
    private let baseURLString: String = Config.baseURL
    static let apiKey: String = Config.apiKey
    
    let client: any APIProtocol
    
    // MARK: Кеширование книг и глав
    @Published var cachedBooks: [Components.Schemas.TranslationBookModel] = []
    @Published var cachedBooksTranslation: Int = 0
    @Published var cachedBooksVoice: Int = 0
    
    // MARK: Прогресс чтения
    @Published var readProgress: ReadProgress = ReadProgress()
    private let readProgressKey = "readProgress"
    
    init() {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpAdditionalHeaders = [
            "X-API-Key": Self.apiKey
        ]
        let session = URLSession(configuration: sessionConfiguration)
        let transport = URLSessionTransport(configuration: .init(session: session))
        self.client = Client(serverURL: URL(string: baseURLString)!, transport: transport)
        
        // Загружаем прогресс чтения
        loadReadProgress()
    }
    
    /// Builds a full audio URL by appending the api_key query parameter.
    /// - Parameter relativePath: For example: "syn/bondarenko/01/01.mp3".
    /// - Returns: A URL like "http://.../api/audio/syn/bondarenko/01/01.mp3?api_key=YOUR_KEY"
    func audioURL(forRelativePath relativePath: String) -> URL? {
        var components = URLComponents(string: baseURLString)
        components?.path = "/api/audio/" + relativePath
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "api_key", value: Self.apiKey))
        components?.queryItems = queryItems
        return components?.url
    }
    
    /// Appends the api_key query parameter to absolute audio URLs if missing (static variant).
    /// - Parameter url: An absolute URL that may point to the audio endpoint.
    /// - Returns: The same URL with the api_key attached if it's an audio URL, otherwise unchanged.
    static func audioURLWithKey(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        guard components.path.contains("/audio/") else { return url }
        var items = components.queryItems ?? []
        let hasKey = items.contains { $0.name == "api_key" }
        if !hasKey {
            items.append(URLQueryItem(name: "api_key", value: Self.apiKey))
            components.queryItems = items
        }
        return components.url ?? url
    }
    
    /// Appends the api_key query parameter to absolute audio URLs if missing.
    /// - Parameter url: An absolute URL that may point to the audio endpoint.
    /// - Returns: The same URL with the api_key attached if it's an audio URL, otherwise unchanged.
    func audioURL(fromAbsoluteURL url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        guard components.path.contains("/audio/") else { return url }
        var items = components.queryItems ?? []
        let hasKey = items.contains { $0.name == "api_key" }
        if !hasKey {
            items.append(URLQueryItem(name: "api_key", value: Self.apiKey))
            components.queryItems = items
        }
        return components.url ?? url
    }
    
    // MARK: Получение книг с кешированием
    /// Получает список книг для текущего перевода и голоса.
    /// Использует кеш если данные уже загружены для этой комбинации translation/voice.
    /// - Returns: Массив книг или throws error при ошибке загрузки
    func getTranslationBooks() async throws -> [Components.Schemas.TranslationBookModel] {
        // Проверяем, есть ли актуальный кеш
        if !cachedBooks.isEmpty && 
           cachedBooksTranslation == translation && 
           cachedBooksVoice == voice {
            return cachedBooks
        }
        
        // Загружаем данные с API
        let response = try await client.get_translation_books(
            path: .init(translation_code: translation),
            query: .init(voice_code: voice)
        )
        let books = try response.ok.body.json
        
        // Сохраняем в кеш
        await MainActor.run {
            self.cachedBooks = books
            self.cachedBooksTranslation = translation
            self.cachedBooksVoice = voice
        }
        
        return books
    }
    
    /// Очищает кеш книг (например, при изменении настроек)
    func clearBooksCache() {
        cachedBooks = []
        cachedBooksTranslation = 0
        cachedBooksVoice = 0
    }
    
    // MARK: Методы работы с прогрессом чтения
    
    /// Загружает прогресс чтения из UserDefaults
    private func loadReadProgress() {
        if let data = UserDefaults.standard.data(forKey: readProgressKey),
           let progress = try? JSONDecoder().decode(ReadProgress.self, from: data) {
            self.readProgress = progress
        }
    }
    
    /// Сохраняет прогресс чтения в UserDefaults
    private func saveReadProgress() {
        if let data = try? JSONEncoder().encode(readProgress) {
            UserDefaults.standard.set(data, forKey: readProgressKey)
        }
    }
    
    /// Формирует ключ главы в формате "bookAlias_chapterNumber"
    private func chapterKey(book: String, chapter: Int) -> String {
        return "\(book)_\(chapter)"
    }
    
    /// Отмечает главу как прочитанную
    func markChapterAsRead(book: String, chapter: Int) {
        let key = chapterKey(book: book, chapter: chapter)
        readProgress.readChapters.insert(key)
        saveReadProgress()
    }
    
    /// Отмечает главу как непрочитанную
    func markChapterAsUnread(book: String, chapter: Int) {
        let key = chapterKey(book: book, chapter: chapter)
        readProgress.readChapters.remove(key)
        saveReadProgress()
    }
    
    /// Проверяет, прочитана ли глава
    func isChapterRead(book: String, chapter: Int) -> Bool {
        let key = chapterKey(book: book, chapter: chapter)
        return readProgress.readChapters.contains(key)
    }
    
    /// Получает прогресс по книге
    func getBookProgress(book: String, totalChapters: Int) -> (read: Int, total: Int) {
        var readCount = 0
        for chapter in 1...totalChapters {
            if isChapterRead(book: book, chapter: chapter) {
                readCount += 1
            }
        }
        return (readCount, totalChapters)
    }
    
    /// Получает общий прогресс (требует информацию о всех книгах)
    func getTotalProgress(books: [Components.Schemas.TranslationBookModel]) -> (read: Int, total: Int) {
        var totalRead = 0
        var totalChapters = 0
        
        for book in books {
            let progress = getBookProgress(book: book.alias, totalChapters: book.chapters_count)
            totalRead += progress.read
            totalChapters += progress.total
        }
        
        return (totalRead, totalChapters)
    }
    
    /// Сбрасывает весь прогресс
    func resetProgress() {
        readProgress = ReadProgress()
        saveReadProgress()
    }
    
    /// Сбрасывает прогресс по конкретной книге
    func resetBookProgress(book: String, totalChapters: Int) {
        for chapter in 1...totalChapters {
            markChapterAsUnread(book: book, chapter: chapter)
        }
    }
    
    /// Отмечает всю книгу как прочитанную
    func markBookAsRead(book: String, totalChapters: Int) {
        for chapter in 1...totalChapters {
            markChapterAsRead(book: book, chapter: chapter)
        }
    }
    
    /// Получает алиас книги по её номеру из кешированных данных
    func getBookAlias(bookNumber: Int) -> String {
        if let book = cachedBooks.first(where: { $0.book_number == bookNumber }) {
            return book.alias
        }
        return ""
    }
}

struct SkeletonView: View {
    
    @StateObject private var settingsManager = SettingsManager()
    
    // не имеет значения здесь
    @State private var showAsPartOfRead: Bool = false
    
    var body: some View {
        
        ZStack {
            Color("DarkGreen")
                .edgesIgnoringSafeArea(.all)
            
            if settingsManager.selectedMenuItem == .main {
                PageMainView()
                .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .read {
                PageReadView()
                    .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .select {
                PageSelectView(showFromRead: $showAsPartOfRead)
                .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .progress {
                PageProgressView()
                .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .setup {
                PageSetupView(showFromRead: $showAsPartOfRead)
                .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .contacts {
                PageContactsView()
                .environmentObject(settingsManager)
            }
            
            /// menu layer
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
        }
        
    }
}

#Preview {
    SkeletonView()
}

