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
    
    @State private var greeting: String = "Hello, Stranger!"
    @State private var languages: [Components.Schemas.LanguageModel] = []
    
    @ObservedObject var windowsDataManager: WindowsDataManager
    let client: any APIProtocol
    
    init(windowsDataManager: WindowsDataManager) {
        self.windowsDataManager = windowsDataManager
        self.client = Client(serverURL: URL(string: "http://helper-vm-maria:8000")!, transport: URLSessionTransport())
    }
    
    func updateGreeting() async {
            do {
                let response = try await client.get_languages()
                let json = try response.ok.body.json
                self.languages = json
                greeting = "\(String(describing: json[0].alias))"
                
            } catch { greeting = "Error: \(error.localizedDescription)" }
        }
    
    var body: some View {
        
        Text(greeting)
        
        Button {
            Task { await updateGreeting() }
            
            
        } label: {
            Text("print 123")
        }
        
        List {
                            ForEach(languages, id: \.alias) { language in
                                Text("\(language.name_national) (\(language.name_en))")
                            }
                        }
        
        
        //let greeting = GreetingClient().getGreeting(name: "App")
        
    }
    
    //let client: Client = Client(serverURL: URL(string: "http://localhost:8080/api")!, transport: URLSessionTransport())
    
}

/*
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
*/

struct TestPageContactsView: View {
    
    @StateObject var windowsDataManager = WindowsDataManager()
    
    var body: some View {
        PageContactsView(windowsDataManager: windowsDataManager)
    }
}

#Preview {
    TestPageContactsView()
}
