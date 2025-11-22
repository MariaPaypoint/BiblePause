import SwiftUI
import WebKit

struct HTMLTextView: UIViewRepresentable {
    let htmlContent: String
    let jsTemplate = """
        // Remove highlight class from the previous verse
        var previous = document.querySelector('.highlighted-verse');
        if (previous) {
            previous.classList.remove('highlighted-verse');
        }
    
        // Scroll to the current verse
        var target = document.getElementById('{elementId}');
        if (target) {
            target.scrollIntoView({ behavior: 'smooth' });
    
            // Add highlight class to the current verse
            target.classList.add('highlighted-verse');
        }
    """
    @Binding var scrollToVerse: Int?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.decelerationRate = .normal

        // Set transparent background
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear

        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        webView.scrollView.delaysContentTouches = false
        
        context.coordinator.webView = webView
        return webView
    }


    func updateUIView(_ webView: WKWebView, context: Context) {
        // If scrollToVerse changes and webView is loaded, execute JavaScript
        if let verse = scrollToVerse, context.coordinator.webViewLoaded {
            //print("updateUIView \(verse)")
            if verse <= 0 {
                webView.evaluateJavaScript(jsTemplate.replacingOccurrences(of: "{elementId}", with: "top"), completionHandler: nil)
            }
            else {
                webView.evaluateJavaScript(jsTemplate.replacingOccurrences(of: "{elementId}", with: "verse-\(verse)"), completionHandler: nil)
            }
            // Reset scrollToVerse to nil to prevent repeated scrolling
            DispatchQueue.main.async {
                scrollToVerse = nil
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLTextView
        var webViewLoaded = false
        weak var webView: WKWebView?

        init(_ parent: HTMLTextView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webViewLoaded = true

            // If scrollToVerse is set, execute JavaScript to scroll
            if let verse = parent.scrollToVerse {
                webView.evaluateJavaScript(parent.jsTemplate.replacingOccurrences(of: "{verse}", with: "\(verse)"), completionHandler: nil)

                DispatchQueue.main.async {
                    self.parent.scrollToVerse = nil
                }
            }
        }
    }
}
