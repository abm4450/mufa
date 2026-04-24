import Foundation
import Security

@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    private let tokenKey = "app.mufa.auth.token"
    private let userKey = "app.mufa.auth.user.json"

    @Published private(set) var token: String?
    @Published private(set) var user: AuthUser?

    private init() {
        token = KeychainHelper.read(service: tokenKey, account: "default")
        if let data = UserDefaults.standard.data(forKey: userKey),
           let u = try? JSONDecoder().decode(AuthUser.self, from: data) {
            user = u
        }
    }

    var isLoggedIn: Bool { token != nil && user != nil }

    func setSession(token: String, user: AuthUser) {
        self.token = token
        self.user = user
        KeychainHelper.save(service: tokenKey, account: "default", data: Data(token.utf8))
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    func clearSession() {
        token = nil
        user = nil
        KeychainHelper.delete(service: tokenKey, account: "default")
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}

enum KeychainHelper {
    static func save(service: String, account: String, data: Data) {
        delete(service: service, account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
