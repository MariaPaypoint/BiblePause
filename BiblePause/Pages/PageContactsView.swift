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
            ForEach(getAllUserDefaults().sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text("\(key):")
                        .bold()
                    Spacer()
                    Text("\(String(describing: value))")
                }
                .padding(.vertical, 2)
            }
        }
        .padding()

    }
    
    
    func getAllUserDefaults() -> [String: Any] {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        return dictionary
    }
}

#Preview {
    PageContactsView()
}
