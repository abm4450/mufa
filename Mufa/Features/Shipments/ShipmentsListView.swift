import SwiftUI

struct ShipmentsListView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var orders: [Order] = []
    @State private var page = 1
    @State private var totalPages = 1
    @State private var loading = false
    @State private var error: String?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if loading && orders.isEmpty {
                    ProgressView("جاري التحميل...")
                } else if let error {
                    ContentUnavailableView("خطأ", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if orders.isEmpty {
                    ContentUnavailableView("لا شحنات", systemImage: "shippingbox", description: Text("أنشئ شحنة من التبويب الأول"))
                } else {
                    List(orders) { o in
                        NavigationLink(value: o.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(o.referenceId).font(.headline)
                                Text(o.receiverCity).font(.caption).foregroundStyle(MufaTheme.muted)
                                Text(statusArabic(o.status)).font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.gray.opacity(0.15)))
                            }
                        }
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("شحناتي")
            .navigationDestination(for: Int.self) { id in
                ShipmentDetailView(orderId: id)
            }
            .task { await load() }
        }
    }

    private func load() async {
        guard let t = session.token else { return }
        loading = true
        error = nil
        defer { loading = false }
        do {
            let r = try await OrdersService.myOrders(token: t, page: page)
            orders = r.orders
            totalPages = max(1, r.pages)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func statusArabic(_ s: String) -> String {
        let m: [String: String] = [
            "pending": "قيد المعالجة", "created": "بانتظار البوليصة", "shipped": "تم الشحن",
            "delivered": "تم التسليم", "cancelled": "ملغي", "failed": "فشل",
        ]
        return m[s.lowercased()] ?? s
    }
}
