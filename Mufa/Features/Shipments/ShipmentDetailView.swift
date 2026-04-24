import SwiftUI

struct ShipmentDetailView: View {
    let orderId: Int
    @EnvironmentObject private var session: SessionStore
    @State private var order: Order?
    @State private var trackingText = ""
    @State private var loading = false
    @State private var error: String?
    @State private var pdfData: Data?
    @State private var showShare = false

    var body: some View {
        Group {
            if loading && order == nil {
                ProgressView()
            } else if let error {
                Text(error).foregroundStyle(MufaTheme.destructive)
            } else if let order {
                List {
                    Section("المرجع") {
                        Text(order.referenceId)
                        Text("الحالة: \(order.status)")
                        if let ps = Optional(order.paymentStatus) { Text("الدفع: \(ps)") }
                    }
                    Section("المستلم") {
                        Text(order.receiverName)
                        Text(order.receiverPhone)
                        Text("\(order.receiverCity) — \(order.receiverDistrict)")
                        Text(order.receiverAddress)
                    }
                    if let tid = order.torodTrackingId, !tid.isEmpty {
                        Section("التتبع") {
                            Text(tid)
                            if !trackingText.isEmpty {
                                Text(trackingText).font(.caption).textSelection(.enabled)
                            }
                            Button("تحديث التتبع") { Task { await refreshTrack() } }
                        }
                    }
                    Section("البوليصة") {
                        Button("تحميل PDF") { Task { await downloadLabel() } }
                    }
                }
            }
        }
        .navigationTitle("تفاصيل الشحنة")
        .task { await load() }
        .sheet(isPresented: $showShare) {
            if let pdfData {
                ShareSheet(items: [pdfData])
            }
        }
    }

    private func load() async {
        guard let t = session.token else { return }
        loading = true
        defer { loading = false }
        do {
            order = try await OrdersService.order(id: orderId, token: t)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func refreshTrack() async {
        guard let t = session.token else { return }
        do {
            let raw = try await OrdersService.trackAuthenticated(orderId: orderId, token: t)
            if let data = try? JSONSerialization.data(withJSONObject: raw, options: [.prettyPrinted]),
               let s = String(data: data, encoding: .utf8) {
                trackingText = s
            } else {
                trackingText = "\(raw)"
            }
        } catch {
            trackingText = error.localizedDescription
        }
    }

    private func downloadLabel() async {
        guard let t = session.token else { return }
        do {
            pdfData = try await OrdersService.labelFile(orderId: orderId, token: t)
            showShare = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
