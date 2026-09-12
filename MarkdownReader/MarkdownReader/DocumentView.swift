import SwiftUI

struct DocumentView: View {
    enum Mode {
        case reading, editing
    }

    let fileURL: URL

    @State private var text = ""
    @State private var mode: Mode
    @State private var showingSettings = false

    init(fileURL: URL) {
        self.fileURL = fileURL
        // @AppStorage 无法在 init 中读取自身，直接读 UserDefaults（同一 key，行为一致）
        let saved = UserDefaults.standard.string(forKey: "defaultViewMode") ?? "reading"
        _mode = State(initialValue: saved == "editing" ? .editing : .reading)
    }

    var body: some View {
        Group {
            switch mode {
            case .reading:
                ReadingView(markdown: text)
            case .editing:
                EditingView(text: $text)
            }
        }
        .navigationTitle(fileURL.deletingPathExtension().lastPathComponent)
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
        .onAppear(perform: load)
        .onChange(of: text) {
            save()
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let string = String(data: data, encoding: .utf8) {
            text = string
        } else if let string = String(data: data, encoding: .utf16) {
            text = string
        } else {
            // 容错：替换非法字节，避免打开失败
            text = String(decoding: data, as: UTF8.self)
        }
    }

    private func save() {
        try? text.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
