# Markdown Reader - iOS App 开发文档

> **项目目标**：开发一个仅用于个人使用的 iOS/iPadOS Markdown 阅读与编辑 App，支持从微信/飞书/Telegram/WhatsApp 等社交平台以及 Files App 打开 `.md` 文件，提供类似 Notion/Obsidian 的阅读体验。

---

## 一、项目概述

### 1.1 核心功能需求

- ✅ 以原生 iOS App 形式运行于 iPhone 和 iPad
- ✅ 支持通过"用其他 App 打开"从任意应用导入 Markdown 文件
- ✅ 支持从 Files App 浏览并打开本地 `.md` 文件
- ✅ 首页显示 Files App 中所有本地 `.md` 文件列表
- ✅ 阅读模式：渲染 Markdown 为富文本（标题、列表、代码块、引用等可视化呈现）
- ✅ 编辑模式：支持 Markdown 源码编辑，带语法高亮
- ✅ 遵循 iOS 设计规范，界面风格与系统原生 App 一致
- ✅ 不上架 App Store，仅个人使用（通过 Xcode 直接安装到设备）

### 1.2 技术选型

| 组件 | 技术选型 | 理由 |
|------|----------|------|
| UI 框架 | SwiftUI 6.0+ | Apple 官方推荐，与 iOS 系统风格一致，开发效率高 |
| 文档架构 | `DocumentGroup` + `FileDocument` | Apple 官方文档型 App 架构，原生支持文件打开/分享 |
| Markdown 渲染 | [Textual](https://github.com/gonzalezreal/textual) | GitHub 最成熟的 SwiftUI Markdown 渲染库，支持 GitHub 风格、代码高亮、LaTeX、Mermaid |
| 代码高亮 | Textual 内置（基于 Highlight.js） | 支持 100+ 编程语言，性能优秀 |
| 数据存储 | SwiftData | Apple 官方数据持久化方案，存储最近打开记录、书签等 |
| 最低系统版本 | iOS 17.0+ | 确保 SwiftUI 6.0 和 Textual 兼容性 |

---

## 二、项目结构

```
MarkdownReader/
├── MarkdownReaderApp.swift          # App 入口，配置 DocumentGroup
├── Info.plist                       # 配置 UTType.markdown 文档类型支持
├── Models/
│   ├── MarkdownDocument.swift       # FileDocument 协议实现
│   └── RecentFile.swift             # SwiftData 模型，存储最近打开记录
├── Views/
│   ├── ContentView.swift            # 首页，显示文件列表
│   ├── DocumentView.swift           # 文档查看/编辑主界面
│   ├── ReadingView.swift            # 阅读模式（Textual 渲染）
│   ├── EditingView.swift            # 编辑模式（TextEditor + 语法高亮）
│   ├── FileListItem.swift           # 文件列表项组件
│   └── SettingsView.swift           # 设置界面
├── ViewModels/
│   └── DocumentViewModel.swift      # 文档状态管理
├── Services/
│   ├── FileService.swift            # 文件操作服务
│   └── RecentFilesService.swift     # 最近打开记录管理
├── Extensions/
│   └── String+Markdown.swift        # Markdown 相关扩展
└── Assets/
    ├── AppIcon.appiconset           # App 图标
    └── AccentColor.colorset         # 主题色
```

---

## 三、详细实现方案

### 3.1 Info.plist 配置（关键：支持"用其他 App 打开"）

在 `Info.plist` 中添加以下配置，注册 `.md` 和 `.markdown` 文件类型：

```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Markdown Document</string>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>LSHandlerRank</key>
        <string>Default</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>net.daringfireball.markdown</string>
            <string>org.plain-text</string>
            <string>public.data</string>
            <string>public.content</string>
        </array>
    </dict>
</array>

<key>UISupportsDocumentBrowser</key>
<true/>

<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>

<key>UIFileSharingEnabled</key>
<true/>

<key>UISupportsImplicitDocumentOpening</key>
<true/>
```

### 3.2 App 入口：MarkdownReaderApp.swift

```swift
import SwiftUI
import SwiftData

@main
struct MarkdownReaderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RecentFile.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            DocumentView(document: file.$document)
                .environment(\.managedObjectContext, sharedModelContainer.mainContext)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
        Settings {
            SettingsView()
        }
    }
}
```

### 3.3 文档模型：MarkdownDocument.swift

```swift
import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.plainText, .markdown, .data, .content]
    }
    
    static var writableContentTypes: [UTType] {
        [.plainText, .markdown]
    }
    
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: text.data(using: .utf8)!)
    }
}

// UTType 扩展
extension UTType {
    static var markdown: UTType {
        UTType(filenameExtension: "md", conformingTo: .plainText) ?? .plainText
    }
}
```

### 3.4 首页：ContentView.swift（显示本地 .md 文件列表）

```swift
import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecentFile.openedDate, order: .reverse) private var recentFiles: [RecentFile]
    @State private var localFiles: [URL] = []
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationStack {
            List {
                // 最近打开
                if !recentFiles.isEmpty {
                    Section("最近打开") {
                        ForEach(recentFiles) { recentFile in
                            FileListItem(
                                url: recentFile.fileURL,
                                onTap: { openFile(at: recentFile.fileURL) }
                            )
                        }
                    }
                }
                
                // 本地文件（Files App）
                Section("本地文件") {
                    ForEach(localFiles, id: \.self) { url in
                        FileListItem(
                            url: url,
                            onTap: { openFile(at: url) }
                        }
                    }
                    
                    Button(action: { showingFilePicker = true }) {
                        Label("从 Files 选择", systemImage: "folder.badge.plus")
                    }
                }
            }
            .navigationTitle("Markdown Reader")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.markdown, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    // 复制到 App 沙盒
                    let destination = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.copyItem(at: url, to: destination)
                    localFiles.append(destination)
                    saveRecentFile(url: destination)
                case .failure(let error):
                    print("文件选择失败：\(error)")
                }
            }
            .onAppear {
                loadLocalFiles()
            }
        }
    }
    
    private func loadLocalFiles() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let enumerator = FileManager.default.enumerator(
            at: documents,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        var files: [URL] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == "md" || 
               fileURL.pathExtension.lowercased() == "markdown" {
                files.append(fileURL)
            }
        }
        localFiles = files.sorted {
            ($0.lastModifiedDate ?? .distantPast) > ($1.lastModifiedDate ?? .distantPast)
        }
    }
    
    private func openFile(at url: URL) {
        // DocumentGroup 会自动处理文件打开
    }
    
    private func saveRecentFile(url: URL) {
        let recentFile = RecentFile(fileURL: url, openedDate: Date())
        modelContext.insert(recentFile)
    }
}

extension URL {
    var lastModifiedDate: Date? {
        try? resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
}
```

### 3.5 文件列表项：FileListItem.swift

```swift
import SwiftUI

struct FileListItem: View {
    let url: URL
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(url.deletingPathExtension().lastPathComponent)
                        .font(.body)
                        .lineLimit(1)
                    
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
```

### 3.6 文档视图：DocumentView.swift（阅读/编辑切换）

```swift
import SwiftUI

struct DocumentView: View {
    @Binding var document: MarkdownDocument
    @State private var isEditing = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            ToolbarView(
                isEditing: $isEditing,
                onToggle: { isEditing.toggle() }
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // 内容区域
            if isEditing {
                EditingView(text: $document.text)
            } else {
                ReadingView(markdown: document.text)
            }
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ToolbarView: View {
    @Binding var isEditing: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: onToggle) {
                Label(
                    isEditing ? "阅读模式" : "编辑模式",
                    systemImage: isEditing ? "eye" : "pencil"
                )
            }
            .buttonStyle(.bordered)
        }
    }
}
```

### 3.7 阅读视图：ReadingView.swift（使用 Textual 渲染）

```swift
import SwiftUI
import Textual

struct ReadingView: View {
    let markdown: String
    
    var body: some View {
        ScrollView {
            TextualText(markdown)
                .textualStyle(.gitHub)
                .textualTheme(.light)
                .padding()
        }
        .background(Color(.systemBackground))
    }
}

// TextualText 是 Textual 库提供的核心组件
// 支持：标题、列表、引用、代码块、表格、链接、图片、LaTeX、Mermaid
```

### 3.8 编辑视图：EditingView.swift（带语法高亮）

```swift
import SwiftUI

struct EditingView: View {
    @Binding var text: String
    @State private var scrollPosition = Int.zero
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .onChange(of: text) { oldValue, newValue in
                        // 可选：实现 Markdown 语法高亮（需要自定义 TextStorage）
                    }
            }
            .background(Color(.systemBackground))
        }
    }
}

// 高级方案：使用 UITextView + NSTextStorage 实现语法高亮
// 参考：https://github.com/mattt/TextFormat
```

### 3.9 设置界面：SettingsView.swift

```swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultViewMode") private var defaultViewMode = "reading"
    @AppStorage("theme") private var theme = "system"
    @AppStorage("fontSize") private var fontSize = 16.0
    
    var body: some View {
        Form {
            Section("阅读") {
                Picker("默认视图", selection: $defaultViewMode) {
                    Text("阅读模式").tag("reading")
                    Text("编辑模式").tag("editing")
                }
                
                Picker("主题", selection: $theme) {
                    Text("跟随系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
                
                Stepper("字体大小：\(Int(fontSize))", value: $fontSize, in: 12...24, step: 1)
            }
            
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Text("Markdown Reader 是一个个人使用的 Markdown 阅读与编辑工具。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("设置")
    }
}
```

### 3.10 SwiftData 模型：RecentFile.swift

```swift
import Foundation
import SwiftData

@Model
final class RecentFile {
    var fileURL: URL
    var openedDate: Date
    var title: String
    
    init(fileURL: URL, openedDate: Date = Date(), title: String = "") {
        self.fileURL = fileURL
        self.openedDate = openedDate
        self.title = title.isEmpty ? fileURL.deletingPathExtension().lastPathComponent : title
    }
}
```

---

## 四、依赖管理

### 4.1 Package.swift（Swift Package Manager）

在 Xcode 中添加以下依赖：

```swift
// Textual - Markdown 渲染
dependencies: [
    .package(url: "https://github.com/gonzalezreal/textual", from: "1.0.0")
]
```

**添加步骤：**
1. Xcode → File → Add Package Dependencies
2. 输入：`https://github.com/gonzalezreal/textual`
3. 选择最新版本（1.0.0+）

---

## 五、构建与部署

### 5.1 Xcode 项目配置

1. **创建项目**
   - File → New → Project
   - 选择 "App"（iOS）
   - Interface: SwiftUI
   - Language: Swift
   - 勾选 "Include Tests"（可选）

2. **配置签名**
   - Signing & Capabilities → 选择你的 Apple ID
   - Team: Personal Team（免费）
   - Bundle Identifier: `com.yourname.MarkdownReader`

3. **配置 Info.plist**
   - 添加上述 `CFBundleDocumentTypes` 等配置

4. **添加 Textual 依赖**
   - File → Add Package Dependencies
   - 输入：`https://github.com/gonzalezreal/textual`

### 5.2 安装到设备（无需 App Store）

1. 连接 iPhone/iPad 到 Mac
2. Xcode → 选择你的设备作为运行目标
3. 点击 Run（⌘R）
4. App 将安装到你的设备上

**注意**：使用免费 Apple ID 时，App 每 7 天需要重新签名（重新连接 Xcode 运行一次即可）。

---

## 六、高级功能扩展（可选）

### 6.1 Markdown 语法高亮（编辑模式）

使用 `NSTextStorage` 实现实时语法高亮：

```swift
import UIKit

class MarkdownTextStorage: NSTextStorage {
    private let storage = NSMutableAttributedString()
    
    override var string: String {
        get { storage.string }
    }
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return storage.attributes(at: location, effectiveRange: range)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        storage.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        endEditing()
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()
        storage.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
    func highlight() {
        // 实现 Markdown 语法高亮逻辑
        // 参考：https://github.com/mattt/TextFormat
    }
}
```

### 6.2 LaTeX 数学公式支持

Textual 已内置 LaTeX 支持，无需额外配置：

```swift
// 行内公式：$E = mc^2$
// 块级公式：$$\int_{a}^{b} f(x)dx$$
```

### 6.3 Mermaid 图表支持

Textual 支持 Mermaid 语法：

````markdown
```mermaid
graph TD
    A[开始] --> B[结束]
```
````

### 6.4 目录/大纲导航（TOC）

```swift
struct TableOfContentsView: View {
    let markdown: String
    
    var headings: [Heading] {
        // 解析 Markdown 提取标题
        let lines = markdown.components(separatedBy: "\n")
        return lines.compactMap { line -> Heading? in
            if line.hasPrefix("## ") {
                return Heading(level: 2, text: String(line.dropFirst(3)))
            } else if line.hasPrefix("### ") {
                return Heading(level: 3, text: String(line.dropFirst(4)))
            }
            return nil
        }
    }
    
    var body: some View {
        List(headings) { heading in
            Text(heading.text)
                .padding(.leading, CGFloat(heading.level - 2) * 16)
        }
    }
}

struct Heading: Identifiable {
    let id = UUID()
    let level: Int
    let text: String
}
```

---

## 七、测试清单

### 7.1 文件打开测试

- [ ] 从微信选择 .md 文件 → "用其他 App 打开" → 能看到 Markdown Reader
- [ ] 从飞书选择 .md 文件 → "用其他 App 打开" → 能看到 Markdown Reader
- [ ] 从 Telegram/WhatsApp 选择 .md 文件 → 能正常打开
- [ ] 从 Files App 浏览 → 能看到并打开 .md 文件
- [ ] 从 Safari 下载 .md 文件 → Files App → 能用 Markdown Reader 打开

### 7.2 阅读模式测试

- [ ] 各级标题（# 到 ######）正确渲染
- [ ] 粗体（**text**）、斜体（*text*）正确显示
- [ ] 列表（有序/无序）正确渲染
- [ ] 引用块（> text）正确显示
- [ ] 代码块（```language ... ```）带语法高亮
- [ ] 表格正确渲染
- [ ] 链接可点击
- [ ] 图片（本地/网络）正常显示
- [ ] LaTeX 公式正确渲染
- [ ] Mermaid 图表正确渲染

### 7.3 编辑模式测试

- [ ] 可以编辑文本
- [ ] 编辑后保存正确
- [ ] 文件内容实时更新
- [ ] 撤销/重做功能正常

### 7.4 性能测试

- [ ] 打开大文件（1MB+）无明显卡顿
- [ ] 滚动流畅（60 FPS）
- [ ] 内存占用合理（< 100MB）

---

## 八、常见问题与解决方案

### Q1: "用其他 App 打开"列表中看不到 Markdown Reader

**解决方案**：
1. 检查 `Info.plist` 中 `CFBundleDocumentTypes` 配置是否正确
2. 确保 `UTType.markdown` 已正确定义
3. 重启设备或重新安装 App
4. 在 Files App 中长按 .md 文件 → 分享 → 查看是否有 Markdown Reader

### Q2: Textual 渲染效果与预期不符

**解决方案**：
1. 检查是否使用了 `.textualStyle(.gitHub)`
2. 确认 Textual 版本为最新（1.0.0+）
3. 参考 Textual 文档：https://github.com/gonzalezreal/textual

### Q3: 编辑模式没有语法高亮

**解决方案**：
1. 基础方案：使用 `TextEditor` + 等宽字体（`.monospaced`）
2. 高级方案：使用 `UITextView` + `NSTextStorage` 自定义高亮（参考第 6.1 节）

### Q4: App 每 7 天过期

**解决方案**：
- 这是免费 Apple Developer 账号的正常限制
- 每 7 天连接 Xcode 重新运行一次即可重新签名
- 如需永久使用，需购买付费开发者账号（$99/年）

---

## 九、参考资源

### 9.1 核心依赖

- **Textual**: https://github.com/gonzalezreal/textual
- **Apple 文档 - DocumentGroup**: https://developer.apple.com/documentation/swiftui/documentgroup
- **Apple 文档 - FileDocument**: https://developer.apple.com/documentation/swiftui/filedocument
- **Apple 文档 - UTType**: https://developer.apple.com/documentation/uniformtypeidentifiers/uttype

### 9.2 参考项目

- **Marklit**: https://apps.apple.com/us/app/marklit-markdown-file-viewer/id6760291417
- **Read.md**: https://apps.apple.com/us/app/read-md/id6760943472
- **Markdownr**: https://apps.apple.com/us/app/markdownr/id6448853807
- **Peek (macOS)**: https://github.com/rsdrahat/peek
- **QuickMD (macOS)**: https://github.com/b451c/quickmd

### 9.3 教程与文章

- **Crafting document-based apps in SwiftUI**: https://www.createwithswift.com/crafting-document-based-apps-in-swiftui/
- **Rendering Markdown in SwiftUI**: https://artemnovichkov.com/blog/rendering-markdown-in-swiftui
- **iOS Markdown File Opening Friction**: https://www.lzwjava.com/ios-markdown-file-opening-friction-en

---

## 十、下一步行动

1. **创建 Xcode 项目**（约 5 分钟）
2. **添加 Textual 依赖**（约 2 分钟）
3. **复制上述代码到对应文件**（约 30 分钟）
4. **配置 Info.plist**（约 5 分钟）
5. **连接设备并运行**（约 5 分钟）
6. **测试文件打开功能**（约 10 分钟）
7. **测试阅读/编辑模式**（约 15 分钟）

**预计总时间**：约 1-2 小时即可完成 MVP 版本。

---

## 附录 A：完整代码文件清单

| 文件名 | 行数 | 说明 |
|--------|------|------|
| MarkdownReaderApp.swift | ~40 | App 入口 |
| Info.plist | ~30 | 文档类型配置 |
| MarkdownDocument.swift | ~30 | FileDocument 实现 |
| ContentView.swift | ~100 | 首页文件列表 |
| FileListItem.swift | ~30 | 文件列表项 |
| DocumentView.swift | ~40 | 文档主视图 |
| ReadingView.swift | ~15 | 阅读模式 |
| EditingView.swift | ~25 | 编辑模式 |
| SettingsView.swift | ~40 | 设置界面 |
| RecentFile.swift | ~15 | SwiftData 模型 |

**总计**：约 365 行核心代码（不含注释和空行）。

---

**文档版本**：1.0.0  
**创建日期**：2026-09-11  
**适用系统**：iOS 17.0+, iPadOS 17.0+  
**开发工具**：Xcode 16+, Swift 6.0+
