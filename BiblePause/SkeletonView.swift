//
//  SkeletonView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI
import OpenAPIURLSession

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
    @AppStorage("translation") var translation: Int = 10 // bti
    @AppStorage("translationName") var translationName: String = "BTI"
    @AppStorage("voice") var voice: Int = 4 // prozorovsky
    @AppStorage("voiceName") var voiceName: String = "Н. Семёнов-Прозоровский"
    @AppStorage("voiceMusic") var voiceMusic: Bool = false
    
    @AppStorage("currentExcerpt") var currentExcerpt: String = "mat 1"
    @AppStorage("currentExcerptTitle") var currentExcerptTitle: String = "Евангелие от Матфея"
    @AppStorage("currentExcerptSubtitle") var currentExcerptSubtitle: String = "Глава 1"
    @AppStorage("currentBookId") var currentBookId: Int = 0
    @AppStorage("currentChapterId") var currentChapterId: Int = 0
    
    @AppStorage("currentSpeed") var currentSpeed: Double = 1.0
    
    //var translationInfo: Components.Schemas.TranslationInfoModel?
    
    private let baseURLString: String = Config.baseURL
    static let apiKey: String = Config.apiKey
    
    let client: any APIProtocol
    
    init() {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpAdditionalHeaders = [
            "X-API-Key": Self.apiKey
        ]
        let session = URLSession(configuration: sessionConfiguration)
        let transport = URLSessionTransport(configuration: .init(session: session))
        self.client = Client(serverURL: URL(string: baseURLString)!, transport: transport)
        
        // загрузка информации о переводе
        /*
        Task {
            do {
                let response = try await client.get_translation_info(query: .init(translation: Int(exactly: translation)!))
                let translationInfoResponse = try response.ok.body.json
                self.translationInfo = translationInfoResponse
            } catch {
                // ничего не делать
            }
        }
        */
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
            
            else if settingsManager.selectedMenuItem == .setup {
                PageSetupView(showFromRead: $showAsPartOfRead)
                .environmentObject(settingsManager)
            }
            
            else if settingsManager.selectedMenuItem == .contacts {
                PageContactsView()
                .environmentObject(settingsManager)
            }
            
            // слой меню
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
        }
        
    }
}

#Preview {
    SkeletonView()
}

