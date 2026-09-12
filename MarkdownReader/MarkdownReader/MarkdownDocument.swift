import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// Markdown 文档类型（非本 App 所有，Info.plist 中通过 UTImportedTypeDeclarations 声明）
    static let markdown = UTType(importedAs: "net.daringfireball.markdown")
}

struct MarkdownDocument: FileDocument {
    // .markdown 放第一位：文档浏览器新建文件时默认存为 .md
    static var readableContentTypes: [UTType] { [.markdown, .plainText] }
    static var writableContentTypes: [UTType] { [.markdown, .plainText] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        if let string = String(data: data, encoding: .utf8) {
            text = string
        } else if let string = String(data: data, encoding: .utf16) {
            text = string
        } else {
            // 容错：替换非法字节，避免打开失败
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
