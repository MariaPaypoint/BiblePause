//
//  advExcerpt.swift
//  cep
//
//  Created by Maria Novikova on 31.12.2022.
//

import SwiftUI

// MARK: Готовое отображение

@ViewBuilder func viewExcerpt(verses: [BibleTextualVerseFull], fontIncreasePercent: Double, selectedId: Int=0) -> some View {
    
    let formattedText = verses.reduce(Text("")) { partialResult, verse in
        partialResult
        +
        Text("\(verse.id). ") // Номер стиха
            .font(.system(size: 7 * (1 + fontIncreasePercent / 100)))
            .foregroundColor(.white.opacity(0.5))
            //.id("verse_number_\(verse.id)")
        +
        Text(verse.text) // Текст стиха
            .foregroundColor(selectedId == verse.id ? Color("DarkGreen-accent") : .white)
            .font(.system(size: 10 * (1 + fontIncreasePercent / 100)))
        +
        Text(" ")
    }

    VStack {
        formattedText
            .lineSpacing(10.0)
    }
}

func getCSSColor(named colorName: String) -> String {
    if let selectedUIColor = UIColor(named: colorName) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if selectedUIColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return String(format: "rgba(%d, %d, %d, %.2f)", Int(red * 255), Int(green * 255), Int(blue * 255), alpha)
        }
    }
    return "yellow" // Значение по умолчанию
}


func generateHTMLContent(verses: [BibleTextualVerseFull], fontIncreasePercent: Double) -> String {
    let fontSize = 10 * (1 + fontIncreasePercent / 100)
    let selectedColor = getCSSColor(named: "DarkGreen-accent")
    let jesusColor = getCSSColor(named: "Jesus")
    
    var htmlString = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                html {
                    font-size: \(fontSize)px; /* Базовый размер шрифта */
                    scroll-behavior: smooth;
                }

                body {
                    background-color: transparent;
                    color: #ffffff;
                    font-family: -apple-system, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                }

                h1 {
                    font-size: 1.3rem; 
                }

                p {
                    margin-bottom: 1rem;
                    font-size: 1rem; 
                }

                .verse-number {
                    font-size: 0.7rem; 
                    color: gray;
                    margin-right: 0.3rem;
                }
                                    
                .quote {
                    display: block;
                    padding-left: 1rem;
                }
                .jesus {
                    color: \(jesusColor);
                }
                .highlighted-verse {
                    color: \(selectedColor);
                }
                .highlighted-verse .jesus {
                    color: \(selectedColor);
                    font-weight: bold;
                }
            </style>
        </head>
        <body>
    """

    for verse in verses {
        let elem = verse.startParagraph ? "p" : "span"
        
        htmlString += """
            <\(elem) id="verse-\(verse.id)"><span class="verse-number">\(verse.id).</span>\(verse.text)</\(elem)>
        """
    }

    htmlString += """
        </body>
        </html>
    """

    return htmlString
}
