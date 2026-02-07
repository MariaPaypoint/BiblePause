import SwiftUI

enum MenuItem: Hashable {
    case main
    case read
    case select
    case progress
    case setup
    case contacts
    case multilingual
    case multilingualRead
}

// MARK: - Menu Overlay
struct MenuView: View {

    @EnvironmentObject var settingsManager: SettingsManager
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ZStack {
            // Blur View
            BlurView(style: .systemUltraThinMaterialDark)

            Color("DarkGreen")
                .opacity(0.2)
                .blur(radius: 15)

            // Content
            VStack(alignment: .leading, spacing: UIScreen.main.bounds.height < 750 ? 20 : 35) {

                // MARK: Close Button
                Button {
                    withAnimation(.spring()) {
                        settingsManager.showMenu = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .fontWeight(.light)
                }
                .foregroundColor(Color.white.opacity(0.5))

                // MARK: Menu Items

                // 1. Главная
                Button {
                    selectItem(.main)
                } label: {
                    Text("menu.main".localized)
                        .font(.system(.headline))
                        .fontWeight(.bold)
                        .foregroundColor(colorFor(.main))
                }

                // 2. Мультичтение
                Button {
                    if settingsManager.isMultilingualReadingActive {
                        selectItem(.multilingualRead)
                    } else {
                        selectItem(.multilingual)
                    }
                } label: {
                    Text("menu.multilingual".localized)
                        .font(.system(.headline))
                        .fontWeight(.bold)
                        .foregroundColor(
                            settingsManager.selectedMenuItem == .multilingual || settingsManager.selectedMenuItem == .multilingualRead
                            ? Color("Mustard").opacity(0.9)
                            : Color.white.opacity(0.9)
                        )
                }

                // 3. Обычное чтение
                Button {
                    selectItem(.read)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("menu.classic_reading".localized)
                            .font(.system(.headline))
                            .fontWeight(.bold)
                            .foregroundColor(colorFor(.read))
                        Text("\(settingsManager.currentExcerptTitle), \(settingsManager.currentExcerptSubtitle)")
                            .font(.system(size: 14))
                            .foregroundColor(colorFor(.read))
                            .multilineTextAlignment(.leading)
                    }
                }

                // 4. Прогресс
                Button {
                    selectItem(.progress)
                } label: {
                    Text("menu.progress".localized)
                        .font(.system(.headline))
                        .fontWeight(.bold)
                        .foregroundColor(colorFor(.progress))
                }

                // 5. Контакты
                Button {
                    selectItem(.contacts)
                } label: {
                    Text("menu.contacts".localized)
                        .font(.system(.headline))
                        .fontWeight(.bold)
                        .foregroundColor(colorFor(.contacts))
                }

                Spacer(minLength: 10)

                // MARK: Version
                Text("menu.version".localized)
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .padding(.trailing, 120)
            .padding()
            .padding(.top, getSafeArea().top)
            .padding(.bottom, getSafeArea().bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .clipShape(MenuShape(value: 0))
        .background(
            MenuShape(value: 0)
                .stroke(
                    .linearGradient(.init(colors: [
                        Color("ForestGreen"),
                        Color("Mustard").opacity(0.7),
                        Color("Mustard").opacity(0.7),
                    ]), startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
                .padding(.leading, -50)
        )
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func colorFor(_ item: MenuItem) -> Color {
        let selected = settingsManager.selectedMenuItem == item
        return selected ? Color("Mustard").opacity(0.9) : Color.white.opacity(0.9)
    }

    private func selectItem(_ item: MenuItem) {
        settingsManager.selectedMenuItem = item
        withAnimation(.spring()) {
            settingsManager.showMenu = false
        }
    }
}

// MARK: - Curve Shape
struct MenuShape: Shape {

    var value: CGFloat

    var animatableData: CGFloat {
        get { return value }
        set { value = newValue }
    }

    func path(in rect: CGRect) -> Path {
        return Path { path in
            let width = rect.width - 100
            let height = rect.height

            path.move(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))

            path.move(to: CGPoint(x: width, y: 0))
            path.addCurve(to: CGPoint(x: width, y: height),
                          control1: CGPoint(x: width + value, y: height / 3),
                          control2: CGPoint(x: width - value, y: height / 2))
        }
    }
}

// MARK: - Menu Button (hamburger)
struct MenuButtonView: View {

    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        Button {
            withAnimation(.spring()) {
                settingsManager.showMenu.toggle()
            }
        } label: {
            Image("Menu")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: - Extensions

extension View {

    func getSafeArea() -> UIEdgeInsets {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .zero
        }
        guard let safeArea = screen.windows.first?.safeAreaInsets else {
            return .zero
        }
        return safeArea
    }

    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
}

// MARK: - BlurView
struct BlurView: UIViewRepresentable {

    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
    }
}

// MARK: - Preview
struct TestView: View {

    @StateObject var settingsManager = SettingsManager()

    var body: some View {
        ZStack {
            if settingsManager.showMenu {
                MenuView()
                    .environmentObject(settingsManager)
                    .transition(.move(edge: .leading))
            }
        }
        .background(
            Image("Forest")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        )
    }
}

#Preview {
    TestView()
}
