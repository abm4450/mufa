import SwiftUI

struct TrackView: View {
    @State private var trackingId = ""
    @State private var result: String?
    @State private var loading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("رقم التتبع أو المرجع") {
                    TextField("MUF-… أو رقم التتبع", text: $trackingId)
                        .textInputAutocapitalization(.characters)
                }
                Button("تتبع") { Task { await run() } }
                    .disabled(trackingId.trimmingCharacters(in: .whitespaces).isEmpty || loading)
                if loading { ProgressView() }
                if let result {
                    Section("النتيجة") {
                        Text(result).font(.caption).textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("تتبع شحنة")
        }
    }

    private func run() async {
        let q = trackingId.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        loading = true
        result = nil
        defer { loading = false }
        do {
            let (_, t) = try await APIClient.shared.postTrack(trackingId: q)
            if let data = try? JSONSerialization.data(withJSONObject: t, options: [.prettyPrinted]),
               let s = String(data: data, encoding: .utf8) {
                result = s
            } else {
                result = "\(t)"
            }
        } catch {
            result = error.localizedDescription
        }
    }
}
