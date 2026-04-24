import SwiftUI

struct LoginRegisterView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    var onSuccess: () -> Void

    @State private var mode: Bool = true // true = login
    @State private var phone = ""
    @State private var password = ""
    @State private var name = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("", selection: $mode) {
                    Text("دخول").tag(true)
                    Text("تسجيل").tag(false)
                }
                .pickerStyle(.segmented)
                TextField("الجوال 05xxxxxxxx", text: $phone)
                    .keyboardType(.phonePad)
                SecureField("كلمة المرور", text: $password)
                if !mode {
                    TextField("الاسم", text: $name)
                }
                if let error {
                    Text(error).foregroundStyle(MufaTheme.destructive)
                }
                Button(mode ? "دخول" : "إنشاء حساب") { Task { await submit() } }
                    .disabled(busy)
            }
            .navigationTitle(mode ? "تسجيل الدخول" : "حساب جديد")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            if mode {
                let r = try await AuthService.login(phone: phone, password: password)
                session.setSession(token: r.token, user: r.user)
            } else {
                let r = try await AuthService.register(phone: phone, name: name, password: password)
                session.setSession(token: r.token, user: r.user)
            }
            onSuccess()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
