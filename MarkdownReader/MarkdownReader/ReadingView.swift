import SwiftUI
import Textual

struct ReadingView: View {
    let markdown: String
    @AppStorage("fontSize") private var fontSize = 17.0

    var body: some View {
        ScrollView {
            StructuredText(markdown: markdown, syntaxExtensions: [.math])
                .textual.structuredTextStyle(.gitHub)
                .textual.textSelection(.enabled)
                // Textual 的间距/字号度量均为 font-relative，设置环境字体即整体等比缩放
                .font(.system(size: fontSize))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .background(Color(.systemBackground))
    }
}
