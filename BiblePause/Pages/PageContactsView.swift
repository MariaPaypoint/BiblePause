//
//  PageContactsView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI
import AVFoundation
import Combine

struct PageContactsView: View {
    
    @ObservedObject var windowsDataManager: WindowsDataManager
    
    var body: some View {
        Text("dsdf")
    }
    
}

struct TestPageContactsView: View {
    
    @StateObject var windowsDataManager = WindowsDataManager()
    
    var body: some View {
        PageContactsView(windowsDataManager: windowsDataManager)
    }
}

#Preview {
    TestPageContactsView()
}
