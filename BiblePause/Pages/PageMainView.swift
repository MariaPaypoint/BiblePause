import SwiftUI

struct PageMainView: View {
    
    @EnvironmentObject var settingsManager: SettingsManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var booksLoaded = false
    
    var body: some View {
        
        ZStack {
            // Background layer
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
                .padding(.top, 40)
                // Title artwork
                Image("TitleRus")
                
                // Dual Mode Selection
                VStack(spacing: 15) {
                    // Option 1: Silence (Classic Reading)
                    MainMenuCard(
                        title: "Обычное чтение",
                        subtitle: "\(settingsManager.currentExcerptTitle), \(settingsManager.currentExcerptSubtitle)",
                        icon: "book.fill", // Classic book icon
                        color: Color("ForestGreen")
                    ) {
                        settingsManager.selectedMenuItem = .read
                    }
                    
                    // Option 2: Immersion (Multilingual Study)
                    MainMenuCard(
                        title: "Мульти-чтение",
                        subtitle: "Сравнение переводов • Аудио • Изучение языков",
                        icon: "translate", // Headphones for audio/study
                        color: Color("ForestGreen")
                    ) {
                        settingsManager.selectedMenuItem = .multilingual
                    }
                }
                
                // Push remaining content upward
                Spacer()
            }
            .padding(20)
            
            // Reading progress card near bottom
            progressCardView()
            
            // Sliding menu layer
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
                        
                        // Progress bar with overlayed percentage
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
                            
                            // Percentage label above progress bar
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
                // Loading error is non-critical for the main page
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

struct MainMenuCard: View {
    let title: String
    let subtitle: String
    let icon: String // SF Symbol name
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Icon Box
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(Color("ForestGreen")) // Deep green for titles
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color("Chocolate")) // Warm brown for details
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.black.opacity(0.2))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.85)) // Glass effect
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle()) // Keeps standard button press effect minimal or custom
    }
}

#Preview {
    TestPageMainView()
}
