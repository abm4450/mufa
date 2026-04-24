import Foundation
import SwiftUI

@MainActor
final class CreateShipmentViewModel: ObservableObject {
    @Published var step = 1
    @Published var senderName = ""
    @Published var senderPhone = ""
    @Published var senderCityId: Int?
    @Published var senderCityLabel = ""
    @Published var senderAddress = ""

    @Published var receiverName = ""
    @Published var receiverPhone = ""
    @Published var receiverCityId: Int?
    @Published var receiverCityLabel = ""
    @Published var receiverDistrictId: Int?
    @Published var receiverDistrictLabel = ""
    @Published var receiverAddress = ""
    @Published var receiverNationalAddress = ""

    @Published var shipmentContent = ""
    @Published var shipmentValue = ""
    @Published var shipmentWeight = ""
    @Published var noOfBox = "1"

    @Published var cities: [City] = []
    @Published var receiverDistricts: [District] = []
    @Published var carriers: [CarrierQuote] = []
    @Published var selectedCarrier: CarrierQuote?

    @Published var isBusy = false
    @Published var alertMessage: String?
    @Published var showMoyasar = false
    @Published var moyasarBridge: MoyasarConfig?
    @Published var pendingOrderId: Int?
    @Published var pendingReferenceId: String?
    @Published var paymentFinishedSuccess = false
    @Published var paymentFinishedRef: String?

    private let nationalRegex = try! NSRegularExpression(pattern: "^[A-Z]{4}[0-9]{4}$")

    func loadCities() async {
        do {
            cities = try await CarriersService.cities()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func onReceiverCityChange() async {
        receiverDistricts = []
        receiverDistrictId = nil
        receiverDistrictLabel = ""
        guard let id = receiverCityId else { return }
        do {
            receiverDistricts = try await CarriersService.districts(cityId: id)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func loadCarriers() async {
        guard let sc = senderCityId, let rc = receiverCityId,
              let w = Double(shipmentWeight), let v = Double(shipmentValue),
              let boxes = Int(noOfBox), boxes >= 1 else {
            alertMessage = "أكمل المدن والوزن والقيمة أولاً"
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            carriers = try await CarriersService.quote(
                shipperCityId: sc,
                customerCityId: rc,
                weight: w,
                orderTotal: v,
                noOfBox: boxes
            )
            selectedCarrier = nil
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func validationErrors() -> [String] {
        var e: [String] = []
        if senderName.trimmingCharacters(in: .whitespaces).isEmpty { e.append("اسم المرسل") }
        if !isValidPhone(senderPhone) { e.append("جوال المرسل (05xxxxxxxx)") }
        if senderCityId == nil { e.append("مدينة المرسل") }
        if senderAddress.trimmingCharacters(in: .whitespaces).isEmpty { e.append("عنوان المرسل") }

        if receiverName.trimmingCharacters(in: .whitespaces).isEmpty { e.append("اسم المستلم") }
        if !isValidPhone(receiverPhone) { e.append("جوال المستلم") }
        if receiverCityId == nil { e.append("مدينة المستلم") }
        if receiverDistrictId == nil { e.append("حي المستلم") }
        if receiverAddress.trimmingCharacters(in: .whitespaces).isEmpty { e.append("عنوان المستلم") }
        let nat = receiverNationalAddress.uppercased().trimmingCharacters(in: .whitespaces)
        if nationalRegex.firstMatch(in: nat, range: NSRange(nat.startIndex..., in: nat)) == nil {
            e.append("العنوان الوطني (4 أحرف + 4 أرقام)")
        }

        if shipmentContent.trimmingCharacters(in: .whitespaces).isEmpty { e.append("وصف المحتوى") }
        if Double(shipmentValue) == nil || (Double(shipmentValue) ?? 0) <= 0 { e.append("قيمة الشحنة") }
        if Double(shipmentWeight) == nil || (Double(shipmentWeight) ?? 0) <= 0 { e.append("الوزن") }
        if Int(noOfBox) == nil || (Int(noOfBox) ?? 0) < 1 { e.append("عدد الصناديق") }
        if selectedCarrier == nil { e.append("شركة الشحن") }
        return e
    }

    func buildPayload() -> CreateOrderPayload {
        let sc = senderCityId
        let rc = receiverCityId
        let rd = receiverDistrictId!
        let c = selectedCarrier!
        return CreateOrderPayload(
            senderName: senderName.trimmingCharacters(in: .whitespaces),
            senderPhone: normalizePhone(senderPhone),
            senderCountry: "Saudi Arabia",
            senderCity: senderCityLabel,
            senderCityId: sc,
            senderDistrict: "",
            senderDistrictId: nil,
            senderAddress: senderAddress.trimmingCharacters(in: .whitespaces),
            senderNationalAddress: nil,
            receiverName: receiverName.trimmingCharacters(in: .whitespaces),
            receiverPhone: normalizePhone(receiverPhone),
            receiverCountry: "Saudi Arabia",
            receiverCity: receiverCityLabel,
            receiverCityId: rc,
            receiverDistrict: receiverDistrictLabel,
            receiverDistrictId: rd,
            receiverAddress: receiverAddress.trimmingCharacters(in: .whitespaces),
            receiverNationalAddress: receiverNationalAddress.uppercased().trimmingCharacters(in: .whitespaces),
            itemDescription: shipmentContent.trimmingCharacters(in: .whitespaces),
            orderTotal: Double(shipmentValue) ?? 0,
            weight: Double(shipmentWeight) ?? 0,
            noOfBox: Int(noOfBox) ?? 1,
            paymentType: "Prepaid",
            carrierId: c.id,
            carrierName: c.name,
            carrierCost: c.carrierCost,
            shippingPrice: c.price
        )
    }

    func startPayment(token: String?) async {
        let errs = validationErrors()
        guard errs.isEmpty else {
            alertMessage = "ناقص: " + errs.joined(separator: "، ")
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let res = try await PaymentsService.initiate(buildPayload(), token: token)
            guard let m = res.moyasar else {
                alertMessage = "تعذر تجهيز الدفع"
                return
            }
            pendingOrderId = res.orderId
            pendingReferenceId = res.referenceId
            moyasarBridge = MoyasarConfig(
                amount: m.amount,
                currency: m.currency,
                description: m.description,
                publishable_api_key: res.publicKey,
                callback_url: m.callbackUrl,
                metadata: m.metadata ?? [:]
            )
            showMoyasar = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func handleMoyasarReturn(orderId: Int?) async {
        showMoyasar = false
        let oid = orderId ?? pendingOrderId
        let ref = pendingReferenceId
        guard let oid else {
            alertMessage = "تعذر تأكيد الطلب"
            return
        }
        isBusy = true
        defer { isBusy = false }
        for _ in 0 ..< 45 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if let t = SessionStore.shared.token {
                if let s = try? await PaymentsService.status(orderId: oid, token: t) {
                    if s.paymentStatus == "paid" {
                        paymentFinishedSuccess = true
                        paymentFinishedRef = s.referenceId
                        resetAfterSuccess()
                        return
                    }
                    if s.paymentStatus == "failed" {
                        alertMessage = "فشل الدفع"
                        return
                    }
                }
            } else if let r = ref {
                if let o = try? await PublicOrdersService.byId(orderId: oid, referenceId: r), o.paymentStatus == "paid" {
                    paymentFinishedSuccess = true
                    paymentFinishedRef = o.referenceId
                    resetAfterSuccess()
                    return
                }
            }
        }
        alertMessage = "لم يتم تأكيد الدفع بعد. تحقق من شحناتي لاحقاً."
    }

    private func resetAfterSuccess() {
        step = 1
        clearForm()
        moyasarBridge = nil
        pendingOrderId = nil
        pendingReferenceId = nil
    }

    private func clearForm() {
        senderName = ""
        senderPhone = ""
        senderCityId = nil
        senderCityLabel = ""
        senderAddress = ""
        receiverName = ""
        receiverPhone = ""
        receiverCityId = nil
        receiverCityLabel = ""
        receiverDistrictId = nil
        receiverDistrictLabel = ""
        receiverAddress = ""
        receiverNationalAddress = ""
        shipmentContent = ""
        shipmentValue = ""
        shipmentWeight = ""
        noOfBox = "1"
        carriers = []
        selectedCarrier = nil
    }

    private func normalizePhone(_ phone: String) -> String {
        var s = phone.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("+966") { s = "0" + s.dropFirst(4) }
        else if s.hasPrefix("966") { s = "0" + s.dropFirst(3) }
        return s
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let p = normalizePhone(phone)
        guard p.count == 10, p.hasPrefix("05") else { return false }
        return p.allSatisfy(\.isNumber)
    }
}
