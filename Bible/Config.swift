import Foundation

enum Config {
    private static let configFileName = "Configuration"
    
    private static var configDictionary: [String: Any] {
        guard let path = Bundle.main.path(forResource: configFileName, ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Configuration.plist file not found. Please copy Configuration.plist.example to Configuration.plist and configure it.")
        }
        return dict
    }
    
    static var baseURL: String {
        guard let url = configDictionary["BaseURL"] as? String else {
            fatalError("BaseURL not found in Configuration.plist")
        }
        return url
    }
    
    static var apiKey: String {
        guard let key = configDictionary["APIKey"] as? String else {
            fatalError("APIKey not found in Configuration.plist")
        }
        return key
    }
}
