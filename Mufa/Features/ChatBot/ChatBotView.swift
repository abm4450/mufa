import SwiftUI

private enum BotStage: String {
    case senderName, senderPhone, senderCity, senderDistrict, senderAddress, senderNationalAddress
    case receiverName, receiverPhone, receiverCity, receiverDistrict, receiverAddress, receiverNationalAddress
    case itemDescription, orderTotal, weight, noOfBox, carrier, payment, done
}

private struct BotDraft {
    var senderName = ""
    var senderPhone = ""
    var senderCity = ""
    var senderCityId: Int?
    var senderDistrict = ""
    var senderDistrictId: Int?
    var senderAddress = ""
    var senderNationalAddress = ""
    var receiverName = ""
    var receiverPhone = ""
    var receiverCity = ""
    var receiverCityId: Int?
    var receiverDistrict = ""
    var receiverDistrictId: Int?
    var receiverAddress = ""
    var receiverNationalAddress = ""
    var itemDescription = ""
    var orderTotal: Double?
    var weight: Double?
    var noOfBox: Int?
    var carrierId: Int?
    var carrierName: String?
    var carrierCost: Double?
    var shippingPrice: Double?
}

struct ChatBotView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var messages: [(bot: Bool, text: String)] = []
    @State private var stage: BotStage = .senderName
    @State private var draft = BotDraft()
    @State private var input = ""
    @State private var cities: [City] = []
    @State private var senderDistricts: [District] = []
    @State private var receiverDistricts: [District] = []
    @State private var carriers: [CarrierQuote] = []
    @State private var busy = false
    @State private var showMoyasar = false
    @State private var moyasarCfg: MoyasarConfig?
    @State private var payOrderId: Int?
    @State private var payRef: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { _, m in
                            HStack {
                                if m.bot { bubble(m.text, alignRight: true) }
                                else { Spacer(); bubble(m.text, alignRight: false) }
                            }
                        }
                    }
                    .padding()
                }
                pickers
                HStack {
                    TextField(promptForStage, text: $input)
                        .textFieldStyle(.roundedBorder)
                    Button("إرسال") { send() }
                        .disabled(!textStage || busy)
                }
                .padding()
            }
            .navigationTitle("المساعد")
            .task {
                await loadCities()
                greet()
            }
            .fullScreenCover(isPresented: $showMoyasar) {
                if let cfg = moyasarCfg {
                    NavigationStack {
                        MoyasarCheckoutView(config: cfg) { oid in
                            Task { await onPayReturn(oid) }
                        }
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("إغلاق") { showMoyasar = false }
                            }
                        }
                    }
                }
            }
        }
    }

    private var textStage: Bool {
        switch stage {
        case .senderCity, .senderDistrict, .receiverCity, .receiverDistrict, .carrier, .payment, .done:
            return false
        default:
            return true
        }
    }

    private var promptForStage: String {
        switch stage {
        case .senderName: return "اسم المرسل"
        case .senderPhone: return "جوال المرسل"
        case .senderAddress: return "عنوان المرسل"
        case .senderNationalAddress: return "العنوان الوطني للمرسل"
        case .receiverName: return "اسم المستلم"
        case .receiverPhone: return "جوال المستلم"
        case .receiverAddress: return "عنوان المستلم"
        case .receiverNationalAddress: return "العنوان الوطني للمستلم (4حروف+4أرقام)"
        case .itemDescription: return "وصف المحتوى"
        case .orderTotal: return "قيمة الشحنة"
        case .weight: return "الوزن كجم"
        case .noOfBox: return "عدد الصناديق"
        default: return ""
        }
    }

    @ViewBuilder private var pickers: some View {
        switch stage {
        case .senderCity:
            cityPicker(title: "مدينة المرسل") { c in
                draft.senderCityId = c.id
                draft.senderCity = c.nameAr ?? c.name
                Task {
                    await loadSenderDistricts()
                    bot("تم اختيار المدينة. اختر الحي.")
                    stage = .senderDistrict
                }
            }
        case .senderDistrict:
            districtPicker(items: senderDistricts, title: "حي المرسل") { d in
                draft.senderDistrictId = d.id
                draft.senderDistrict = d.nameAr ?? d.name
                bot("الآن عنوان المرسل النصي:")
                stage = .senderAddress
            }
        case .receiverCity:
            cityPicker(title: "مدينة المستلم") { c in
                draft.receiverCityId = c.id
                draft.receiverCity = c.nameAr ?? c.name
                Task {
                    receiverDistricts = try await CarriersService.districts(cityId: c.id)
                    bot("اختر حي المستلم")
                    stage = .receiverDistrict
                }
            }
        case .receiverDistrict:
            districtPicker(items: receiverDistricts, title: "حي المستلم") { d in
                draft.receiverDistrictId = d.id
                draft.receiverDistrict = d.nameAr ?? d.name
                bot("عنوان المستلم:")
                stage = .receiverAddress
            }
        case .carrier:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(carriers) { c in
                        Button("\(c.nameAr ?? c.name)\n\(c.price, specifier: "%.0f") ر.س") {
                            draft.carrierId = c.id
                            draft.carrierName = c.name
                            draft.carrierCost = c.carrierCost
                            draft.shippingPrice = c.price
                            userPickedCarrier()
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(MufaTheme.primary))
                    }
                }
            }
            .padding(.horizontal)
        default:
            EmptyView()
        }
    }

    private func cityPicker(title: String, onPick: @escaping (City) -> Void) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(MufaTheme.muted)
            Menu(title) {
                ForEach(cities) { c in
                    Button(c.nameAr ?? c.name) { onPick(c) }
                }
            }
            .padding()
        }
    }

    private func districtPicker(items: [District], title: String, onPick: @escaping (District) -> Void) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(MufaTheme.muted)
            Menu(title) {
                ForEach(items) { d in
                    Button(d.nameAr ?? d.name) { onPick(d) }
                }
            }
            .padding()
        }
    }

    private func greet() {
        messages = []
        bot("أهلاً 👋 سأساعدك بإنشاء شحنة حتى الدفع. ابدأ باسم المرسل.")
    }

    private func bot(_ t: String) { messages.append((true, t)) }
    private func user(_ t: String) { messages.append((false, t)) }

    private func loadCities() async {
        do { cities = try await CarriersService.cities() } catch { bot(error.localizedDescription) }
    }

    private func loadSenderDistricts() async {
        guard let id = draft.senderCityId else { return }
        do { senderDistricts = try await CarriersService.districts(cityId: id) } catch { bot(error.localizedDescription) }
    }

    private func send() {
        let t = input.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        input = ""
        user(t)
        switch stage {
        case .senderName:
            draft.senderName = t
            bot("جوال المرسل:")
            stage = .senderPhone
        case .senderPhone:
            draft.senderPhone = t
            bot("اختر مدينة المرسل من القائمة")
            stage = .senderCity
        case .senderAddress:
            draft.senderAddress = t
            bot("العنوان الوطني للمرسل (اختياري) أو اكتب - لتخطي")
            stage = .senderNationalAddress
        case .senderNationalAddress:
            draft.senderNationalAddress = t == "-" ? "" : t
            bot("اسم المستلم:")
            stage = .receiverName
        case .receiverName:
            draft.receiverName = t
            bot("جوال المستلم:")
            stage = .receiverPhone
        case .receiverPhone:
            draft.receiverPhone = t
            bot("اختر مدينة المستلم")
            stage = .receiverCity
        case .receiverAddress:
            draft.receiverAddress = t
            bot("العنوان الوطني للمستلم:")
            stage = .receiverNationalAddress
        case .receiverNationalAddress:
            draft.receiverNationalAddress = t.uppercased()
            bot("وصف محتويات الشحنة:")
            stage = .itemDescription
        case .itemDescription:
            draft.itemDescription = t
            bot("قيمة الشحنة بالريال:")
            stage = .orderTotal
        case .orderTotal:
            draft.orderTotal = Double(t.replacingOccurrences(of: ",", with: "."))
            bot("الوزن بالكيلو:")
            stage = .weight
        case .weight:
            draft.weight = Double(t.replacingOccurrences(of: ",", with: "."))
            bot("عدد الصناديق:")
            stage = .noOfBox
        case .noOfBox:
            draft.noOfBox = max(1, Int(t) ?? 1)
            Task { await fetchCarriers() }
        default:
            break
        }
    }

    private func fetchCarriers() async {
        guard let sc = draft.senderCityId, let rc = draft.receiverCityId,
              let w = draft.weight, let v = draft.orderTotal else {
            bot("بيانات ناقصة للأسعار")
            return
        }
        busy = true
        defer { busy = false }
        do {
            carriers = try await CarriersService.quote(
                shipperCityId: sc,
                customerCityId: rc,
                weight: w,
                orderTotal: v,
                noOfBox: draft.noOfBox ?? 1
            )
            if carriers.isEmpty {
                bot("لا توجد شركات لهذه البيانات.")
                stage = .done
            } else {
                bot("اختر شركة الشحن:")
                stage = .carrier
            }
        } catch {
            bot(error.localizedDescription)
        }
    }

    private func userPickedCarrier() {
        bot("جاري تجهيز الدفع…")
        stage = .payment
        Task { await startPay() }
    }

    private func buildPayload() -> CreateOrderPayload {
        CreateOrderPayload(
            senderName: draft.senderName,
            senderPhone: normalizePhone(draft.senderPhone),
            senderCountry: "Saudi Arabia",
            senderCity: draft.senderCity,
            senderCityId: draft.senderCityId,
            senderDistrict: draft.senderDistrict,
            senderDistrictId: draft.senderDistrictId,
            senderAddress: draft.senderAddress,
            senderNationalAddress: draft.senderNationalAddress.isEmpty ? nil : draft.senderNationalAddress,
            receiverName: draft.receiverName,
            receiverPhone: normalizePhone(draft.receiverPhone),
            receiverCountry: "Saudi Arabia",
            receiverCity: draft.receiverCity,
            receiverCityId: draft.receiverCityId,
            receiverDistrict: draft.receiverDistrict,
            receiverDistrictId: draft.receiverDistrictId!,
            receiverAddress: draft.receiverAddress,
            receiverNationalAddress: draft.receiverNationalAddress,
            itemDescription: draft.itemDescription,
            orderTotal: draft.orderTotal ?? 0,
            weight: draft.weight ?? 0,
            noOfBox: draft.noOfBox ?? 1,
            paymentType: "Prepaid",
            carrierId: draft.carrierId,
            carrierName: draft.carrierName,
            carrierCost: draft.carrierCost,
            shippingPrice: draft.shippingPrice
        )
    }

    private func startPay() async {
        guard let rd = draft.receiverDistrictId, rd > 0, draft.carrierId != nil else {
            bot("بيانات ناقصة للدفع")
            return
        }
        do {
            let res = try await PaymentsService.initiate(buildPayload(), token: session.token)
            guard let m = res.moyasar else {
                bot("تعذر تجهيز الدفع")
                return
            }
            payOrderId = res.orderId
            payRef = res.referenceId
            moyasarCfg = MoyasarConfig(
                amount: m.amount,
                currency: m.currency,
                description: m.description,
                publishable_api_key: res.publicKey,
                callback_url: m.callbackUrl,
                metadata: m.metadata ?? [:]
            )
            showMoyasar = true
        } catch {
            bot(error.localizedDescription)
        }
    }

    private func onPayReturn(_ orderId: Int?) async {
        showMoyasar = false
        let oid = orderId ?? payOrderId
        guard let oid else { return }
        for _ in 0 ..< 40 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if let t = session.token, let s = try? await PaymentsService.status(orderId: oid, token: t), s.paymentStatus == "paid" {
                bot("تم الدفع بنجاح ✅ \(s.referenceId)")
                stage = .done
                return
            }
            if let r = payRef, let o = try? await PublicOrdersService.byId(orderId: oid, referenceId: r), o.paymentStatus == "paid" {
                bot("تم الدفع بنجاح ✅")
                stage = .done
                return
            }
        }
        bot("لم يُؤكد الدفع بعد.")
    }

    private func normalizePhone(_ p: String) -> String {
        var s = p.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("+966") { s = "0" + s.dropFirst(4) }
        else if s.hasPrefix("966") { s = "0" + s.dropFirst(3) }
        return s
    }

    private func bubble(_ text: String, alignRight: Bool) -> some View {
        Text(text)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(alignRight ? Color.blue.opacity(0.12) : MufaTheme.primary.opacity(0.15))
            )
            .frame(maxWidth: 280, alignment: alignRight ? .leading : .trailing)
    }
}
