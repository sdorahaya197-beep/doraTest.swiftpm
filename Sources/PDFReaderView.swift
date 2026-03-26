import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - PDF Reader メイン画面
struct PDFReaderView: View {
    @State private var pdfDocument: PDFDocument?
    @State private var selectedMark = "◎"
    @State private var showFilePicker = false
    @State private var showShare = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if let document = pdfDocument {
                    VStack(spacing: 0) {
                        markSelector
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.bar)
                        Divider()
                        PDFKitView(document: document, selectedMark: $selectedMark)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("出馬表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("PDF読み込み", systemImage: "doc.badge.plus")
                    }
                }
                if pdfDocument != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            prepareExport()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf]
            ) { result in
                if case .success(let url) = result {
                    loadPDF(from: url)
                }
            }
            .sheet(isPresented: $showShare) {
                if let url = exportURL {
                    ActivityView(items: [url])
                }
            }
        }
    }

    // MARK: - 印選択ツールバー
    var markSelector: some View {
        HStack(spacing: 6) {
            ForEach(horseMark, id: \.self) { mark in
                Button {
                    selectedMark = mark
                } label: {
                    Text(mark)
                        .font(.title3.bold())
                        .frame(width: 44, height: 36)
                        .background(
                            selectedMark == mark
                                ? markSwiftUIColor(mark).opacity(0.15)
                                : Color.clear
                        )
                        .foregroundStyle(markSwiftUIColor(mark))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedMark == mark ? markSwiftUIColor(mark) : Color.gray.opacity(0.3),
                                    lineWidth: selectedMark == mark ? 2 : 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("タップ: 印を追加")
                Text("印をタップ: 削除")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }

    // MARK: - 空の状態
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("出馬表PDFを読み込む")
                .font(.title2.bold())
            Text("JRAや競馬サイトからダウンロードした\n出馬表PDFに印を打てます")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("PDFを選択") {
                showFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    func markSwiftUIColor(_ mark: String) -> Color {
        switch mark {
        case "◎": return .red
        case "○": return .blue
        case "▲": return .green
        case "△": return .orange
        default: return .gray
        }
    }

    func loadPDF(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if let data = try? Data(contentsOf: url),
           let document = PDFDocument(data: data) {
            pdfDocument = document
        }
    }

    func prepareExport() {
        guard let document = pdfDocument,
              let data = document.dataRepresentation() else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("出馬表_印付き.pdf")
        do {
            try data.write(to: url)
            exportURL = url
            showShare = true
        } catch {}
    }
}

// MARK: - PDFKit ラッパー
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var selectedMark: String

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.delegate = context.coordinator
        pdfView.addGestureRecognizer(tap)
        context.coordinator.pdfView = pdfView
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        context.coordinator.selectedMark = selectedMark
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedMark: selectedMark)
    }

    // MARK: Coordinator
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var selectedMark: String
        weak var pdfView: PDFView?

        init(selectedMark: String) {
            self.selectedMark = selectedMark
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let pdfView else { return }
            let location = gesture.location(in: pdfView)
            guard let page = pdfView.page(for: location, nearest: true) else { return }
            let pagePoint = pdfView.convert(location, to: page)

            // 既存の印をタップ → 削除
            for annotation in page.annotations {
                if annotation.bounds.insetBy(dx: -4, dy: -4).contains(pagePoint) {
                    page.removeAnnotation(annotation)
                    return
                }
            }

            // 新しい印を追加
            let size: CGFloat = 24
            let bounds = CGRect(
                x: pagePoint.x - size / 2,
                y: pagePoint.y - size / 2,
                width: size,
                height: size
            )
            let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
            annotation.contents = selectedMark
            annotation.font = UIFont.boldSystemFont(ofSize: 17)
            annotation.color = .clear
            annotation.fontColor = markUIColor(selectedMark)
            annotation.alignment = .center
            page.addAnnotation(annotation)
        }

        func markUIColor(_ mark: String) -> UIColor {
            switch mark {
            case "◎": return .systemRed
            case "○": return .systemBlue
            case "▲": return .systemGreen
            case "△": return .systemOrange
            default: return .darkGray
            }
        }

        // PDFViewの既存ジェスチャーと共存
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool { true }
    }
}

// MARK: - 共有シート
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
