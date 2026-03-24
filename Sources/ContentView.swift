import SwiftUI

struct ContentView: View {
    var body: some View {
        Button("OK") {
            print("OK tapped")
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

#Preview {
    ContentView()
}
