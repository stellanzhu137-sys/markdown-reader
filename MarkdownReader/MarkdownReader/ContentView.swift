import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var files: [URL] = []
    @State private var path = NavigationPath()
    @State private var showingImporter = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if files.isEmpty {
                    ContentUnavailableView(
                        "没有 Markdown 文件",
                        systemImage: "doc.text",
                        description: Text("点右上角 + 新建，或从微信/文件 App 用「Markdown Reader」打开 .md 文件")
                    )
                } else {
                    List {
                        ForEach(files, id: \.self) { url in
                            NavigationLink(value: url) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(url.deletingPathExtension().lastPathComponent)
                                        .lineLimit(1)
                                    Text(Self.dateFormatter.string(from: modificationDate(of: url)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Markdown Reader")
            .navigationDestination(for: URL.self) { url in
                DocumentView(fileURL: url)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            createDocument()
                        } label: {
                            Label("新建文档", systemImage: "doc.badge.plus")
                        }
                        Button {
                            showingImporter = true
                        } label: {
                            Label("从文件 App 导入", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.markdown, .plainText],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    _ = MarkdownFileStore.importFile(from: url)
                    reload()
                }
            }
            .onAppear(perform: reload)
            .refreshable {
                reload()
            }
            .onOpenURL(perform: openIncoming)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private func modificationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
    }

    private func reload() {
        files = MarkdownFileStore.listFiles()
    }

    private func delete(at offsets: IndexSet) {
        for url in offsets.map({ files[$0] }) {
            try? FileManager.default.removeItem(at: url)
        }
        reload()
    }

    private func createDocument() {
        if let url = MarkdownFileStore.createNew() {
            reload()
            path = NavigationPath()
            path.append(url)
        }
    }

    /// 微信/文件 App「用其他应用打开」的入口：复制进沙盒并打开
    private func openIncoming(_ url: URL) {
        guard let imported = MarkdownFileStore.importFile(from: url) else { return }
        reload()
        path = NavigationPath()
        path.append(imported)
    }
}
