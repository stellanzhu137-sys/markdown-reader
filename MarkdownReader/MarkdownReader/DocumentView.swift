import SwiftUI

struct DocumentView: View {
    enum Mode {
        case reading, editing
    }

    @Binding var document: MarkdownDocument
    let fileURL: URL?

    @State private var mode: Mode
    @State private var showingSettings = false

    init(document: Binding<MarkdownDocument>, fileURL: URL?) {
        _document = document
        self.fileURL = fileURL
        // @AppStorage 无法在 init 中读取自身，直接读 UserDefaults（同一 key，行为一致）
        let saved = UserDefaults.standard.string(forKey: "defaultViewMode") ?? "reading"
        _mode = State(initialValue: saved == "editing" ? .editing : .reading)
    }

    var body: some View {
        Group {
            switch mode {
            case .reading:
                ReadingView(markdown: document.text)
            case .editing:
                EditingView(text: $document.text)
            }
        }
        .navigationTitle(fileURL?.deletingPathExtension().lastPathComponent ?? "Markdown")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mode = (mode == .reading) ? .editing : .reading
                } label: {
                    Image(systemName: mode == .reading ? "pencil" : "eye")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}
