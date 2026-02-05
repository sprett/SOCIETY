//
//  RichTextEditorView.swift
//  SOCIETY
//

import SwiftUI
import UIKit

struct RichTextEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @State private var formatAction: RichTextFormatAction?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                RichTextEditorRepresentable(text: $text, formatAction: $formatAction)
                    .frame(minHeight: 200)
                RichTextToolbar(formatAction: $formatAction)
                    .padding(.vertical, 8)
                    .background(AppColors.elevatedSurface)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.primaryText)
                }
            }
        }
    }
}

enum RichTextFormatAction: Equatable {
    case h1, h2, h3, bullet, bold, italic
}

private struct RichTextEditorRepresentable: UIViewRepresentable {
    @Binding var text: String
    @Binding var formatAction: RichTextFormatAction?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 17)
        textView.textColor = UIColor(AppColors.primaryText)
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.text = text
        context.coordinator.lastBoundValue = text
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if let action = formatAction {
            apply(action, to: uiView) { newText in
                text = newText
                context.coordinator.lastBoundValue = newText
            }
            DispatchQueue.main.async { formatAction = nil }
        }
        guard context.coordinator.lastBoundValue != text else { return }
        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor(AppColors.primaryText),
            ]
        )
        uiView.attributedText = attributed
        context.coordinator.lastBoundValue = text
    }

    private func apply(
        _ action: RichTextFormatAction, to textView: UITextView, onTextChange: (String) -> Void
    ) {
        guard let range = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: range.start)
        let end = textView.offset(from: textView.beginningOfDocument, to: range.end)
        let nsRange = NSRange(location: start, length: end - start)

        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        let fullRange = NSRange(location: 0, length: mutable.length)
        let rangeToApply = nsRange.length > 0 ? nsRange : fullRange
        guard rangeToApply.location >= 0,
            rangeToApply.location + rangeToApply.length <= mutable.length
        else { return }

        switch action {
        case .h1:
            mutable.addAttribute(
                .font, value: UIFont.systemFont(ofSize: 22, weight: .bold), range: rangeToApply)
        case .h2:
            mutable.addAttribute(
                .font, value: UIFont.systemFont(ofSize: 20, weight: .semibold), range: rangeToApply)
        case .h3:
            mutable.addAttribute(
                .font, value: UIFont.systemFont(ofSize: 18, weight: .medium), range: rangeToApply)
        case .bullet:
            let lineRange = (textView.text as NSString).lineRange(
                for: NSRange(location: start, length: 0))
            let lineStart = lineRange.location
            mutable.insert(
                NSAttributedString(
                    string: "• ", attributes: [.font: UIFont.systemFont(ofSize: 17)]), at: lineStart
            )
            textView.attributedText = mutable
            onTextChange(mutable.string)
            return
        case .bold:
            toggleFontTrait(.traitBold, in: mutable, range: rangeToApply)
        case .italic:
            toggleFontTrait(.traitItalic, in: mutable, range: rangeToApply)
        }

        textView.attributedText = mutable
        onTextChange(mutable.string)
    }

    private func toggleFontTrait(
        _ trait: UIFontDescriptor.SymbolicTraits, in mutable: NSMutableAttributedString,
        range: NSRange
    ) {
        mutable.enumerateAttribute(.font, in: range) { value, range, _ in
            let font = (value as? UIFont) ?? .systemFont(ofSize: 17)
            var traits = font.fontDescriptor.symbolicTraits
            if traits.contains(trait) {
                traits.remove(trait)
            } else {
                traits.insert(trait)
            }
            guard let newDescriptor = font.fontDescriptor.withSymbolicTraits(traits) else { return }
            let newFont = UIFont(descriptor: newDescriptor, size: font.pointSize)
            mutable.addAttribute(.font, value: newFont, range: range)
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        var lastBoundValue: String = ""

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            let newText = textView.attributedText.string
            guard newText != text else { return }
            lastBoundValue = newText
            text = newText
        }
    }
}

private struct RichTextToolbar: View {
    @Binding var formatAction: RichTextFormatAction?

    var body: some View {
        HStack(spacing: 16) {
            Button("H1") { formatAction = .h1 }
            Button("H2") { formatAction = .h2 }
            Button("H3") { formatAction = .h3 }
            Button {
                formatAction = .bullet
            } label: {
                Image(systemName: "list.bullet")
            }
            Button {
                formatAction = .bold
            } label: {
                Image(systemName: "bold")
            }
            Button {
                formatAction = .italic
            } label: {
                Image(systemName: "italic")
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AppColors.primaryText)
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

#Preview {
    RichTextEditorView(text: .constant("Sample description"))
}
