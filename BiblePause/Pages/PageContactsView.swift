//
//  PageContactsView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI
//import AVFoundation
//import Combine
//import OpenAPIClient
import OpenAPIRuntime
import OpenAPIURLSession

struct PageContactsView: View {
    
    @ObservedObject var windowsDataManager: WindowsDataManager
    
    var body: some View {
        
        Text("dsdf")
        
        //let greeting = GreetingClient().getGreeting(name: "App")
        
    }
    
    //let client: Client = Client(serverURL: URL(string: "http://localhost:8080/api")!, transport: URLSessionTransport())
    
}

public struct GreetingClient {


    public init() {}


    public func getGreeting(name: String?) async throws -> String {
        let client = Client(
            serverURL: try Servers.server1(),
            transport: URLSessionTransport()
        )
        let response = try await client.read_languages_languages_get()
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(_):
                return "greeting.message"
            }
        case .undocumented(statusCode: let statusCode, _):
            return "🙉 \(statusCode)"
        }
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
