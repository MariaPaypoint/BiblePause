//
//  ContentView.swift
//  BiblePause
//
//  Created by Maria Novikova on 09.05.2024.
//

import SwiftUI

struct PageMainView: View {
    
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var booksLoaded = false
    
    var body: some View {
        
        ZStack {
            // подложка
            Image("Forest")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            
            VStack(spacing: 20) {
                HStack {
                    MenuButtonView()
                        .environmentObject(settingsManager)
                        .padding(.bottom, 50)
                    Spacer()
                }
                // заголовок
                Image("TitleRus")
                
                // кнопка
                Button {
                    settingsManager.selectedMenuItem = .read
                } label: {
                    VStack {
                        Text("page.main.continue_reading".localized)
                            .foregroundColor(Color("ForestGreen"))
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, weight: .heavy))
                        Text("\(settingsManager.currentExcerptTitle), \(settingsManager.currentExcerptSubtitle)")
                            .foregroundColor(Color("Chocolate"))
                            .font(.system(.subheadline))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(12)
                }
                
                // и все толкнем наверх
                Spacer()
            }
            .padding(20)
            
            // Карточка со статистикой прогресса (внизу экрана)
            progressCardView()
            
            // слой меню
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
        }
        .onAppear {
            loadBooksIfNeeded()
        }
    }
    
    @ViewBuilder
    func progressCardView() -> some View {
        if !settingsManager.cachedBooks.isEmpty {
            let totalProgress = settingsManager.getTotalProgress(books: settingsManager.cachedBooks)
            if totalProgress.read > 0 {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Text("page.main.reading_progress".localized)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        // Прогресс-бар с процентом поверх
                        ZStack {
                            // Фон прогресс-бара
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 24)
                            
                            GeometryReader { geometry in
                                let progressWidth = geometry.size.width * CGFloat(totalProgress.read) / CGFloat(totalProgress.total)
                                let progressPercent = CGFloat(totalProgress.read) / CGFloat(totalProgress.total)
                                
                                // Зеленый прогресс
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
                            
                            // Процент поверх прогресс-бара
                            Text(String(format: "%.1f%%", Double(totalProgress.read) / Double(totalProgress.total) * 100))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("DarkGreen").opacity(0.75))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("DarkGreen"), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    func loadBooksIfNeeded() {
        guard !booksLoaded else { return }
        
        Task {
            do {
                _ = try await settingsManager.getTranslationBooks()
                booksLoaded = true
            } catch {
                // Ошибка загрузки, но не критично для главной страницы
            }
        }
    }
}

struct TestPageMainView: View {
    
    var body: some View {
        PageMainView()
            .environmentObject(SettingsManager())
    }
}

#Preview {
    TestPageMainView()
}
