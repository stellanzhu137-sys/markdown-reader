import SwiftUI

@main
struct MarkdownReaderApp: App {
    @AppStorage("theme") private var theme = "system"

    private var preferredScheme: ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // 跟随系统
        }
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            DocumentView(document: file.$document, fileURL: file.fileURL)
                .preferredColorScheme(preferredScheme)
        }
    }
}
