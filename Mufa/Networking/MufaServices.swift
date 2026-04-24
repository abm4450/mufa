import Foundation

enum AuthService {
    static func register(phone: String, name: String, password: String) async throws -> AuthResponse {
        struct B: Encodable { let phone, name, password: String }
        let r: AuthResponse = try await APIClient.shared.request("POST", path: "/user/register", body: B(phone: phone, name: name, password: password))
        return r
    }

    static func login(phone: String, password: String) async throws -> AuthResponse {
        struct B: Encodable { let phone, password: String }
        let r: AuthResponse = try await APIClient.shared.request("POST", path: "/user/login", body: B(phone: phone, password: password))
        return r
    }

    static func me(token: String) async throws -> AuthUser {
        struct R: Decodable { let user: AuthUser }
        let r: R = try await APIClient.shared.request("GET", path: "/user/me", token: token)
        return r.user
    }

    static func profile(token: String) async throws -> UserProfile {
        struct R: Decodable { let profile: UserProfile }
        let r: R = try await APIClient.shared.request("GET", path: "/user/profile", token: token)
        return r.profile
    }

    static func updateProfile(token: String, body: [String: String]) async throws -> UserProfile {
        struct R: Decodable { let profile: UserProfile }
        let r: R = try await APIClient.shared.request("PUT", path: "/user/profile", body: body, token: token)
        return r.profile
    }
}

enum CarriersService {
    static func cities() async throws -> [City] {
        struct R: Decodable { let cities: [City] }
        let r: R = try await APIClient.shared.request("GET", path: "/carriers/cities")
        return r.cities
    }

    static func districts(cityId: Int) async throws -> [District] {
        struct R: Decodable { let districts: [District] }
        let r: R = try await APIClient.shared.request("GET", path: "/carriers/districts/\(cityId)")
        return r.districts
    }

    static func quote(
        shipperCityId: Int?,
        customerCityId: Int,
        weight: Double,
        orderTotal: Double,
        noOfBox: Int,
        payment: String = "Prepaid"
    ) async throws -> [CarrierQuote] {
        struct B: Encodable {
            let shipperCityId: Int?
            let customerCityId: Int
            let weight: Double
            let orderTotal: Double
            let noOfBox: Int
            let payment: String
        }
        struct R: Decodable { let carriers: [CarrierQuote] }
        let r: R = try await APIClient.shared.request(
            "POST",
            path: "/carriers/quote",
            body: B(
                shipperCityId: shipperCityId,
                customerCityId: customerCityId,
                weight: weight,
                orderTotal: orderTotal,
                noOfBox: noOfBox,
                payment: payment
            )
        )
        return r.carriers
    }
}

enum OrdersService {
    static func create(_ payload: CreateOrderPayload, token: String?) async throws -> Order {
        struct R: Decodable { let order: Order }
        let r: R = try await APIClient.shared.request("POST", path: "/orders", body: payload, token: token)
        return r.order
    }

    static func myOrders(token: String, page: Int = 1, sync: Bool = true) async throws -> OrdersListResponse {
        let r: OrdersListResponse = try await APIClient.shared.request("GET", path: "/orders?page=\(page)\(sync ? "&sync=true" : "")", token: token)
        return r
    }

    static func order(id: Int, token: String?) async throws -> Order {
        let o: Order = try await APIClient.shared.request("GET", path: "/orders/\(id)", token: token)
        return o
    }

    static func carriersForOrder(orderId: Int) async throws -> [CarrierQuote] {
        struct R: Decodable { let carriers: [CarrierQuote] }
        let r: R = try await APIClient.shared.request("GET", path: "/orders/\(orderId)/carriers")
        return r.carriers
    }

    static func ship(orderId: Int, courierPartnerId: Int) async throws -> Order {
        struct R: Decodable { let order: Order }
        let r: R = try await APIClient.shared.request("POST", path: "/orders/\(orderId)/ship", body: ShipOrderBody(courierPartnerId: courierPartnerId))
        return r.order
    }

    static func trackAuthenticated(orderId: Int, token: String) async throws -> Data {
        try await APIClient.shared.requestData("POST", path: "/orders/\(orderId)/track", token: token)
    }

    static func labelUrl(orderId: Int, token: String) async throws -> String {
        let r: LabelUrlResponse = try await APIClient.shared.request("GET", path: "/orders/\(orderId)/label", token: token)
        return r.labelUrl
    }

    static func labelFile(orderId: Int, token: String) async throws -> Data {
        do {
            return try await APIClient.shared.requestData("GET", path: "/orders/\(orderId)/label/file", token: token)
        } catch let api as APIClientError {
            if case .httpStatus(404, _) = api {
                let urlString = try await labelUrl(orderId: orderId, token: token)
                guard let u = URL(string: urlString) else { throw APIClientError.invalidURL }
                let (data, res) = try await URLSession.shared.data(from: u)
                let http = res as? HTTPURLResponse
                guard (200 ... 299).contains(http?.statusCode ?? 0) else {
                    throw APIClientError.httpStatus(http?.statusCode ?? 0, "تعذر تنزيل البوليصة")
                }
                return data
            }
            throw api
        }
    }
}

enum PublicOrdersService {
    static func byReference(_ referenceId: String) async throws -> Order {
        let enc = referenceId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? referenceId
        let w: OrderWrapper = try await APIClient.shared.request("GET", path: "/orders/public/\(enc)")
        return w.order
    }

    static func byId(orderId: Int, referenceId: String) async throws -> Order {
        let enc = referenceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? referenceId
        let w: OrderWrapper = try await APIClient.shared.request("GET", path: "/orders/public/id/\(orderId)?reference_id=\(enc)")
        return w.order
    }
}

enum PaymentsService {
    static func initiate(_ payload: CreateOrderPayload, token: String?) async throws -> InitiatePaymentResponse {
        let r: InitiatePaymentResponse = try await APIClient.shared.request("POST", path: "/payments/initiate", body: payload, token: token)
        return r
    }

    static func status(orderId: Int, token: String) async throws -> PaymentStatusResponse {
        let r: PaymentStatusResponse = try await APIClient.shared.request("GET", path: "/payments/\(orderId)/status", token: token)
        return r
    }

    static func retry(orderId: Int, token: String) async throws -> InitiatePaymentResponse {
        struct EmptyJSON: Encodable {}
        let r: InitiatePaymentResponse = try await APIClient.shared.request("POST", path: "/payments/\(orderId)/retry", body: EmptyJSON(), token: token)
        return r
    }
}
