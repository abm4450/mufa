import Foundation

enum APIConfiguration {
    static var baseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        var trimmed = (raw ?? "https://mufabackend.abdullah9.sa/api").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.hasSuffix("/") { trimmed += "/" }
        guard let url = URL(string: trimmed), url.scheme != nil else {
            fatalError("Invalid API_BASE_URL in Info.plist: \(String(describing: raw))")
        }
        return url
    }
}
