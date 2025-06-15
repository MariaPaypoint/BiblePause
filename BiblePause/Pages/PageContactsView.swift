//
//  PageContactsView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI

struct PageContactsView: View {
    var body: some View {
        VStack {
            Text("Контакты")
                .font(.largeTitle)
                .padding()

            Link("Написать в Telegram", destination: URL(string: "https://t.me/your_telegram")!)
                .padding()
                .foregroundColor(.blue)

            Link("Написать на email", destination: URL(string: "mailto:your_email@example.com")!)
                .padding()
                .foregroundColor(.blue)
        }
        .padding()
    }
}

struct TestPageContactsView: View {

    var body: some View {
        PageContactsView()
            .environmentObject(SettingsManager())
    }
}

#Preview {
    TestPageContactsView()
}
