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

        // iOS 18+ 新版文档启动场景：走新的系统实现路径，
        // 规避 iOS 18 上"用其他应用打开"只跳转 App 却不打开文档的已知问题
        DocumentGroupLaunchScene {
            NewDocumentButton("新建 Markdown 文档")
        } background: {
            Color(.systemBackground)
        }
    }
}
