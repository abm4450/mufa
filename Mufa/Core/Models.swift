import Foundation

struct AuthUser: Codable, Equatable, Sendable {
    let id: Int
    let phone: String
    let name: String
    let email: String?
}

struct AuthResponse: Codable, Sendable {
    let token: String
    let user: AuthUser
}

struct UserProfile: Codable, Sendable {
    let id: Int
    let phone: String
    let name: String
    let email: String?
    let city: String?
    let district: String?
    let address: String?
    let nationalAddress: String?

    enum CodingKeys: String, CodingKey {
        case id, phone, name, email, city, district, address
        case nationalAddress = "national_address"
    }
}

struct CreateOrderPayload: Encodable, Sendable {
    var senderName: String
    var senderPhone: String
    var senderCountry: String?
    var senderCity: String
    var senderCityId: Int?
    var senderDistrict: String?
    var senderDistrictId: Int?
    var senderAddress: String
    var senderNationalAddress: String?

    var receiverName: String
    var receiverPhone: String
    var receiverCountry: String?
    var receiverCity: String
    var receiverCityId: Int?
    var receiverDistrict: String
    var receiverDistrictId: Int?
    var receiverAddress: String
    var receiverNationalAddress: String?

    var itemDescription: String
    var orderTotal: Double
    var weight: Double
    var noOfBox: Int
    var paymentType: String?

    var carrierId: Int?
    var carrierName: String?
    var carrierCost: Double?
    var shippingPrice: Double?
}

struct Order: Codable, Identifiable, Sendable {
    let id: Int
    let referenceId: String
    let senderName: String
    let senderPhone: String
    let senderCity: String
    let senderCityId: Int?
    let senderDistrict: String?
    let senderDistrictId: Int?
    let senderAddress: String
    let receiverName: String
    let receiverPhone: String
    let receiverCity: String
    let receiverCityId: Int?
    let receiverDistrict: String
    let receiverDistrictId: Int?
    let receiverAddress: String
    let itemDescription: String
    let orderTotal: Double
    let weight: Double
    let noOfBox: Int
    let paymentType: String
    let carrierId: Int?
    let carrierName: String?
    let carrierCost: Double?
    let shippingPrice: Double?
    let warehouseCode: String?
    let torodOrderId: String?
    let torodTrackingId: String?
    let torodLabelUrl: String?
    let torodTrackingUrl: String?
    let status: String
    let shipmentStatus: String?
    let paymentStatus: String
    let paymentMethod: String?
    let paymentReference: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case referenceId = "reference_id"
        case senderName = "sender_name"
        case senderPhone = "sender_phone"
        case senderCity = "sender_city"
        case senderCityId = "sender_city_id"
        case senderDistrict = "sender_district"
        case senderDistrictId = "sender_district_id"
        case senderAddress = "sender_address"
        case receiverName = "receiver_name"
        case receiverPhone = "receiver_phone"
        case receiverCity = "receiver_city"
        case receiverCityId = "receiver_city_id"
        case receiverDistrict = "receiver_district"
        case receiverDistrictId = "receiver_district_id"
        case receiverAddress = "receiver_address"
        case itemDescription = "item_description"
        case orderTotal = "order_total"
        case weight
        case noOfBox = "no_of_box"
        case paymentType = "payment_type"
        case carrierId = "carrier_id"
        case carrierName = "carrier_name"
        case carrierCost = "carrier_cost"
        case shippingPrice = "shipping_price"
        case warehouseCode = "warehouse_code"
        case torodOrderId = "torod_order_id"
        case torodTrackingId = "torod_tracking_id"
        case torodLabelUrl = "torod_label_url"
        case torodTrackingUrl = "torod_tracking_url"
        case status
        case shipmentStatus = "shipment_status"
        case paymentStatus = "payment_status"
        case paymentMethod = "payment_method"
        case paymentReference = "payment_reference"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct City: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let nameAr: String?
    let regionId: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case nameAr = "name_ar"
        case regionId = "region_id"
    }
}

struct District: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let nameAr: String?
    let cityId: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case nameAr = "name_ar"
        case cityId = "city_id"
    }
}

struct CarrierQuote: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let nameAr: String?
    let slug: String?
    let image: String?
    let price: Double
    let carrierCost: Double?
    let deliveryDays: Int?
    let deliveryTime: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case nameAr = "name_ar"
        case slug, image, price
        case carrierCost = "carrier_cost"
        case deliveryDays = "delivery_days"
        case deliveryTime = "delivery_time"
    }
}

struct MoyasarInitPayload: Codable, Sendable {
    let amount: Int
    let currency: String
    let description: String
    let callbackUrl: String
    let metadata: [String: String]?
}

struct InitiatePaymentResponse: Codable, Sendable {
    let success: Bool
    let orderId: Int
    let referenceId: String
    let paymentStatus: String
    let paymentUrl: String
    let clientSecret: String
    let publicKey: String
    let moyasar: MoyasarInitPayload?
}

struct PaymentStatusResponse: Codable, Sendable {
    let id: Int
    let referenceId: String
    let paymentStatus: String
    let paymentMethod: String?
    let paymentReference: String?

    enum CodingKeys: String, CodingKey {
        case id
        case referenceId = "reference_id"
        case paymentStatus = "payment_status"
        case paymentMethod = "payment_method"
        case paymentReference = "payment_reference"
    }
}

struct ShipOrderBody: Encodable, Sendable {
    let courierPartnerId: Int
}

struct OrdersListResponse: Decodable, Sendable {
    let orders: [Order]
    let total: Int
    let pages: Int
}

struct OrderWrapper: Decodable, Sendable {
    let order: Order
}

struct LabelUrlResponse: Decodable, Sendable {
    let labelUrl: String

    enum CodingKeys: String, CodingKey {
        case labelUrl = "label_url"
    }
}

