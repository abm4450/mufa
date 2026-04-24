import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var profile: UserProfile?
    @State private var name = ""
    @State private var email = ""
    @State private var city = ""
    @State private var district = ""
    @State private var address = ""
    @State private var nationalAddress = ""
    @State private var busy = false
    @State private var message: String?
    @State private var infoSheet: InfoPageKey?

    var body: some View {
        NavigationStack {
            Form {
                if let u = session.user {
                    Section("الحساب") {
                        Text(u.name)
                        Text(u.phone)
                    }
                }
                Section("تعديل الملف") {
                    TextField("الاسم", text: $name)
                    TextField("البريد", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("المدينة", text: $city)
                    TextField("الحي", text: $district)
                    TextField("العنوان", text: $address, axis: .vertical)
                    TextField("العنوان الوطني", text: $nationalAddress)
                        .textInputAutocapitalization(.characters)
                }
                Button("حفظ") { Task { await save() } }
                    .disabled(busy || session.token == nil)
                Section("معلومات") {
                    Button("الخدمات والأسعار") { infoSheet = .pricing }
                    Button("الشروط والأحكام") { infoSheet = .terms }
                    Button("سياسة الخصوصية") { infoSheet = .privacy }
                    Button("سياسة الاسترجاع") { infoSheet = .refund }
                }
                Button("تسجيل الخروج", role: .destructive) {
                    session.clearSession()
                }
            }
            .navigationTitle("حسابي")
            .task { await load() }
            .alert("تم", isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("حسناً", role: .cancel) {}
            } message: { Text(message ?? "") }
            .sheet(item: $infoSheet) { key in
                NavigationStack {
                    InfoPagesView(pageKey: key, onDismiss: { infoSheet = nil })
                }
            }
        }
    }

    private func load() async {
        guard let t = session.token else { return }
        do {
            let p = try await AuthService.profile(token: t)
            profile = p
            name = p.name
            email = p.email ?? ""
            city = p.city ?? ""
            district = p.district ?? ""
            address = p.address ?? ""
            nationalAddress = p.nationalAddress ?? ""
        } catch {}
    }

    private func save() async {
        guard let t = session.token else { return }
        busy = true
        defer { busy = false }
        do {
            var body: [String: String] = [:]
            body["name"] = name
            if !email.isEmpty { body["email"] = email }
            body["city"] = city
            body["district"] = district
            body["address"] = address
            if !nationalAddress.isEmpty { body["national_address"] = nationalAddress }
            let p = try await AuthService.updateProfile(token: t, body: body)
            profile = p
            if let u = session.user {
                session.setSession(token: t, user: AuthUser(id: u.id, phone: u.phone, name: p.name, email: p.email))
            }
            message = "تم الحفظ"
        } catch {
            message = error.localizedDescription
        }
    }
}
