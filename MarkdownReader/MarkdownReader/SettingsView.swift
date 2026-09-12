import SwiftUI

struct SettingsView: View {
    // 三个 key 与 App/DocumentView/ReadingView/EditingView 中使用的完全一致
    @AppStorage("defaultViewMode") private var defaultViewMode = "reading"
    @AppStorage("theme") private var theme = "system"
    @AppStorage("fontSize") private var fontSize = 17.0
    @Environment(\.dismiss) private var dismiss

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
                Stepper("字体大小：\(Int(fontSize))", value: $fontSize, in: 12 ... 28, step: 1)
            }

            Section("关于") {
                LabeledContent("版本", value: "1.0")
                Text("Markdown Reader 是一个个人使用的 Markdown 阅读与编辑工具。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }
}
