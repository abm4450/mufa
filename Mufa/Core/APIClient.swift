import Foundation

enum APIClientError: LocalizedError {
    case invalidURL
    case httpStatus(Int, String)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "عنوان الخادم غير صالح"
        case let .httpStatus(_, msg): return msg
        case let .decoding(err): return err.localizedDescription
        case let .network(err): return err.localizedDescription
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    private func url(_ path: String) throws -> URL {
        let base = APIConfiguration.baseURL
        let tail = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard let u = URL(string: tail, relativeTo: base)?.absoluteURL else { throw APIClientError.invalidURL }
        return u
    }

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: Encodable? = nil,
        token: String? = nil
    ) async throws -> T {
        let u = try url(path)
        var req = URLRequest(url: u)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        let (data, res): (Data, URLResponse)
        do {
            (data, res) = try await session.data(for: req)
        } catch {
            throw APIClientError.network(error)
        }
        let http = res as? HTTPURLResponse
        let status = http?.statusCode ?? 0
        if !(200 ... 299).contains(status) {
            let msg = APIClient.parseErrorMessage(data: data) ?? "HTTP \(status)"
            throw APIClientError.httpStatus(status, msg)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIClientError.decoding(error)
        }
    }

    func requestData(
        _ method: String,
        path: String,
        body: Encodable? = nil,
        token: String? = nil
    ) async throws -> Data {
        let u = try url(path)
        var req = URLRequest(url: u)
        req.httpMethod = method
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        let (data, res) = try await session.data(for: req)
        let status = (res as? HTTPURLResponse)?.statusCode ?? 0
        if !(200 ... 299).contains(status) {
            let msg = APIClient.parseErrorMessage(data: data) ?? "HTTP \(status)"
            throw APIClientError.httpStatus(status, msg)
        }
        return data
    }

    /// جسم الاستجابة خام؛ يُفسَّر في الواجهة لتفادي إرجاع `[String: Any]` عبر حدود الـ actor (غير Sendable في Swift 6).
    func postTrack(trackingId: String, shippingType: String? = nil) async throws -> Data {
        struct Body: Encodable {
            let tracking_id: String
            let shipping_type: String?
        }
        return try await requestData("POST", path: "/track", body: Body(tracking_id: trackingId, shipping_type: shippingType))
    }

    private static func parseErrorMessage(data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let e = obj["error"] as? String { return e }
        if let m = obj["message"] as? String { return m }
        return nil
    }
}

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) {
        encodeFunc = wrapped.encode
    }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}
