import SwiftUI

struct EditingView: View {
    @Binding var text: String
    @AppStorage("fontSize") private var fontSize = 17.0

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: fontSize, design: .monospaced))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 8)
    }
}
