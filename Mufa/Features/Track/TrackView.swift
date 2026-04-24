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
            let data = try await APIClient.shared.postTrack(trackingId: q)
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            let t = obj["tracking"] as? [String: Any] ?? [:]
            if let pretty = try? JSONSerialization.data(withJSONObject: t, options: [.prettyPrinted]),
               let s = String(data: pretty, encoding: .utf8) {
                result = s
            } else {
                result = String(data: data, encoding: .utf8) ?? ""
            }
        } catch {
            result = error.localizedDescription
        }
    }
}
