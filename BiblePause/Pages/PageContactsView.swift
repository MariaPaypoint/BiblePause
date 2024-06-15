//
//  PageContactsView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI

struct PageContactsView: View {
    var body: some View {
        ScrollView {
            LazyVStack {
                Text("A List Item")
                Text("A Second List Item")
                Text("A Third List Item")
            }
            .padding()
        }
    }
}

#Preview {
    PageContactsView()
}
