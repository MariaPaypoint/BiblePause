import SwiftUI

struct PageContactsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Binding var showFromRead: Bool
    
    init(showFromRead: Binding<Bool> = .constant(false)) {
        self._showFromRead = showFromRead
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: Header
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
                    
                    Text("page.contacts.title".localized)
                        .fontWeight(.bold)
                        .padding(.trailing, 32) // compensate menu so title stays centered
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, globalBasePadding)
                
                ScrollView {
                    VStack(spacing: 20) {
                        viewGroupHeader(text: "contacts.contact_us".localized)
                        
                        Button {
                            if let url = URL(string: "https://t.me/your_telegram") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                Text("contacts.telegram".localized)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("DarkGreen-light").opacity(0.6))
                            .cornerRadius(8)
                        }
                        
                        Button {
                            if let url = URL(string: "mailto:your_email@example.com") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.white)
                                Text("contacts.email".localized)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("DarkGreen-light").opacity(0.6))
                            .cornerRadius(8)
                        }
                        
                        viewGroupHeader(text: "contacts.about".localized)
                        
                        Text("contacts.about.text".localized)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("DarkGreen-light").opacity(0.6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, globalBasePadding)
                    .padding(.vertical, 10)
                }
            }
            
            // Background layer
            .background(
                Color("DarkGreen")
            )
            
            // Menu layer
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
        }
    }
}

struct TestPageContactsView: View {
    @State private var showFromRead: Bool = false
    
    var body: some View {
        PageContactsView(showFromRead: $showFromRead)
            .environmentObject(SettingsManager())
    }
}

#Preview {
    TestPageContactsView()
}
