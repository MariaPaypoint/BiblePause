//  Created by Maria Novikova on 24.12.2022.

import Foundation
import SwiftUI

enum FancyToastStyle {
    case error
    case warning
    case success
    case info
}

extension FancyToastStyle {
    var themeLeftColor: Color {
        switch self {
        case .error: return Color.red
        case .warning: return Color.orange
        case .info: return Color.blue
        case .success: return Color.green
        }
    }
    
    var themeBgColor: Color {
        switch self {
        case .error: return Color("ErrorBg")
        case .warning: return Color("WarningBg")
        case .info: return Color("InfoBg")
        case .success: return Color("SuccessBg")
        }
    }
    
    var themeTextColor: Color {
        switch self {
        case .error: return Color("ErrorText")
        case .warning: return Color("WarningText")
        case .info: return Color("InfoText")
        case .success: return Color("SuccessText")
        }
    }
    
    var themeBorderColor: Color {
        switch self {
        case .error: return Color("ErrorBorder")
        case .warning: return Color("WarningBorder")
        case .info: return Color("InfoBorder")
        case .success: return Color("SuccessBorder")
        }
    }
    
    var iconFileName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}
