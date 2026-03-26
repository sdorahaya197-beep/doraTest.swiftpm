import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RaceMemoView()
                .tabItem {
                    Label("メモ帳", systemImage: "note.text")
                }
            PDFReaderView()
                .tabItem {
                    Label("出馬表", systemImage: "doc.richtext")
                }
        }
    }
}
