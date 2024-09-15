//
//  PageContactsView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI

struct PageContactsView: View {
    
    @State private var scrollToVerse: Int?

        var body: some View {
            VStack {
                Button(action: {
                    scrollToVerse = 12
                }) {
                    Text("Прокрутить к третьему стиху")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                HTMLTextView(htmlContent: """
                        <html>
                        <head>
                            <style>
                                body {
                                    font-family: -apple-system, Helvetica, Arial, sans-serif;
                                    line-height: 1.6;
                                    font-size: 38px;
                                    color: #333333;
                                }
                                h1 {
                                    text-align: center;
                                    color: #2C3E50;
                                }
                                p {
                                    margin-bottom: 15px;
                                }
                                .verse-number {
                                    font-size: 0.8em;
                                    color: gray;
                                    vertical-align: super;
                                    margin-right: 5px;
                                }
        html77 {
                    scroll-behavior: smooth;
                }
                            </style>
                        </head>
                        <body>
                            <h1>Евангелие от Матфея, Глава 5</h1>
                            <p id="verse-1"><span class="verse-number">1</span>Увидев народ, Он взошел на гору; и, когда сел, приступили к Нему ученики Его.</p>
                            <p id="verse-2"><span class="verse-number">2</span>И Он, отверзши уста Свои, учил их, говоря:</p>
                            <p id="verse-3"><span class="verse-number">3</span>Блаженны нищие духом, ибо их есть Царство Небесное.</p>
        <p><span class="verse-number">4</span>Блаженны плачущие, ибо они утешатся.</p>
                            <p><span class="verse-number">5</span>Блаженны кроткие, ибо они наследуют землю.</p>
                            <p><span class="verse-number">6</span>Блаженны алчущие и жаждущие правды, ибо они насытятся.</p>
                            <p><span class="verse-number">7</span>Блаженны милостивые, ибо они помилованы будут.</p>
                            <p><span class="verse-number">8</span>Блаженны чистые сердцем, ибо они Бога узрят.</p>
                            <p><span class="verse-number">9</span>Блаженны миротворцы, ибо они нарекутся сынами Божиими.</p>
                            <p><span class="verse-number">10</span>Блаженны изгнанные за правду, ибо их есть Царство Небесное.</p>
                            <p><span class="verse-number">11</span>Блаженны вы, когда будут поносить вас и гнать, и всячески неправедно злословить за Меня.</p>
                            <p id="verse-12"><span class="verse-number">12</span>Радуйтесь и веселитесь, ибо велика ваша награда на небесах: так гнали и пророков, бывших прежде вас.</p>
        SwiftUI is awesome, but are still lacking features a lot of us have grown used to after using UIKit over the years. One of them is being able to render simple HTML text using NSAttributedString and UITextView.

        In this article we’ll have a quick look at how we can bridge SwiftUI with UIKit using UIViewRepresentable, and create our own custom SwiftUI View to render HTML.

        Update: Improvements to original article

        In the original version of this article we had a look at how to create a simple custom SwiftUI View that specialised in creating and rendering styled HTML using NSAttributedString and the AttributedText View mentioned further on in this article. This introduced some weird behaviours I’ve (so fart) not been able to find a proper solution for. So in this updated version of the article, the HTML View has been removed and replaced with a couple of convenience extensions on NSAttributedString instead. I’ve posted on both Apple Developer Forums and Stack Overflow in hopes of gaining a better understanding of the weird behaviours.
                        </body>
                        </html>
        """, scrollToVerse: $scrollToVerse)
                    .padding()
                }
            }
}

struct TestPageContactsView: View {
    
    @StateObject var windowsDataManager = WindowsDataManager()
    
    var body: some View {
        PageContactsView()
            .environmentObject(windowsDataManager)
    }
}

#Preview {
    TestPageContactsView()
}
