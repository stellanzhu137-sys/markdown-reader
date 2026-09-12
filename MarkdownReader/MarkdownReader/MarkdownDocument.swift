import Foundation
import UniformTypeIdentifiers

extension UTType {
    /// Markdown 文档类型（非本 App 所有，Info.plist 中通过 UTImportedTypeDeclarations 声明）
    static let markdown = UTType(importedAs: "net.daringfireball.markdown")
}

/// App 沙盒内 Markdown 文件的读写与导入
enum MarkdownFileStore {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 列出沙盒 Documents 顶层的 .md/.markdown 文件，按修改时间倒序
    static func listFiles() -> [URL] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return urls
            .filter { ["md", "markdown"].contains($0.pathExtension.lowercased()) }
            .sorted {
                let d0 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let d1 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return d0 > d1
            }
    }

    /// 把外部文件（微信/文件 App 分享、fileImporter）复制进沙盒，返回沙盒内的 URL
    static func importFile(from url: URL) -> URL? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        let destination = uniqueURL(for: url.lastPathComponent)
        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    /// 新建空文档，返回 URL
    static func createNew() -> URL? {
        let url = uniqueURL(for: "未命名.md")
        do {
            try "# 未命名\n".write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// 重名时自动加序号：xx.md → xx 2.md → xx 3.md
    static func uniqueURL(for fileName: String) -> URL {
        let base = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        var candidate = documentsDirectory.appendingPathComponent(fileName)
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = documentsDirectory.appendingPathComponent("\(base) \(index).\(ext)")
            index += 1
        }
        return candidate
    }
}
