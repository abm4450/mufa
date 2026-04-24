import SwiftUI

struct CreateShipmentView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var vm = CreateShipmentViewModel()
    @State private var infoSheet: InfoPageKey?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    stepHeader
                    Group {
                        switch vm.step {
                        case 1: senderStep
                        case 2: receiverStep
                        case 3: shipmentStep
                        case 4: carrierStep
                        default: paymentStep
                        }
                    }
                    .padding()
                    .background(MufaTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MufaTheme.cornerRadius))
                }
                .padding()
            }
            .navigationTitle("إنشاء شحنة")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("الخدمات والأسعار") { infoSheet = .pricing }
                        Button("الشروط والأحكام") { infoSheet = .terms }
                        Button("الخصوصية") { infoSheet = .privacy }
                        Button("الاسترجاع") { infoSheet = .refund }
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(MufaTheme.primary)
                    }
                }
            }
        }
        .task { await vm.loadCities() }
        .alert("تنبيه", isPresented: Binding(
            get: { vm.alertMessage != nil },
            set: { if !$0 { vm.alertMessage = nil } }
        )) {
            Button("حسناً", role: .cancel) { vm.alertMessage = nil }
        } message: {
            Text(vm.alertMessage ?? "")
        }
        .alert("تم الدفع بنجاح", isPresented: Binding(
            get: { vm.paymentFinishedSuccess },
            set: { if !$0 { vm.paymentFinishedSuccess = false } }
        )) {
            Button("ممتاز", role: .cancel) { vm.paymentFinishedSuccess = false }
        } message: {
            Text("المرجع: \(vm.paymentFinishedRef ?? "")")
        }
        .fullScreenCover(isPresented: $vm.showMoyasar) {
            if let cfg = vm.moyasarBridge {
                NavigationStack {
                    MoyasarCheckoutView(config: cfg) { oid in
                        Task { await vm.handleMoyasarReturn(orderId: oid) }
                    }
                    .navigationTitle("الدفع")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("إغلاق") {
                                vm.showMoyasar = false
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $infoSheet) { key in
            NavigationStack {
                InfoPagesView(pageKey: key, onDismiss: { infoSheet = nil })
            }
        }
    }

    private var stepHeader: some View {
        HStack {
            ForEach(1 ... 5, id: \.self) { s in
                Text("\(s)")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(vm.step == s ? MufaTheme.primary : Color.gray.opacity(0.2))
                    .foregroundStyle(vm.step == s ? Color.white : MufaTheme.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var senderStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("بيانات المرسل").font(.headline)
            TextField("الاسم", text: $vm.senderName)
                .textFieldStyle(.roundedBorder)
            TextField("الجوال 05xxxxxxxx", text: $vm.senderPhone)
                .keyboardType(.phonePad)
                .textFieldStyle(.roundedBorder)
            Picker("المدينة", selection: Binding(
                get: { vm.senderCityId ?? -1 },
                set: { id in
                    if id == -1 {
                        vm.senderCityId = nil
                        vm.senderCityLabel = ""
                    } else {
                        vm.senderCityId = id
                        vm.senderCityLabel = vm.cities.first { $0.id == id }?.nameAr ?? vm.cities.first { $0.id == id }?.name ?? ""
                    }
                }
            )) {
                Text("اختر").tag(-1)
                ForEach(vm.cities) { c in
                    Text(c.nameAr ?? c.name).tag(c.id)
                }
            }
            TextField("العنوان", text: $vm.senderAddress, axis: .vertical)
                .lineLimit(3 ... 6)
                .textFieldStyle(.roundedBorder)
            stepNav(next: { vm.step = 2 })
        }
    }

    private var receiverStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("بيانات المستلم").font(.headline)
            TextField("الاسم", text: $vm.receiverName)
                .textFieldStyle(.roundedBorder)
            TextField("الجوال 05xxxxxxxx", text: $vm.receiverPhone)
                .keyboardType(.phonePad)
                .textFieldStyle(.roundedBorder)
            Picker("المدينة", selection: Binding(
                get: { vm.receiverCityId ?? -1 },
                set: { id in
                    if id == -1 {
                        vm.receiverCityId = nil
                        vm.receiverCityLabel = ""
                    } else {
                        vm.receiverCityId = id
                        vm.receiverCityLabel = vm.cities.first { $0.id == id }?.nameAr ?? vm.cities.first { $0.id == id }?.name ?? ""
                    }
                    Task { await vm.onReceiverCityChange() }
                }
            )) {
                Text("اختر").tag(-1)
                ForEach(vm.cities) { c in
                    Text(c.nameAr ?? c.name).tag(c.id)
                }
            }
            Picker("الحي", selection: Binding(
                get: { vm.receiverDistrictId ?? -1 },
                set: { id in
                    if id == -1 {
                        vm.receiverDistrictId = nil
                        vm.receiverDistrictLabel = ""
                    } else {
                        vm.receiverDistrictId = id
                        vm.receiverDistrictLabel = vm.receiverDistricts.first { $0.id == id }?.nameAr ?? vm.receiverDistricts.first { $0.id == id }?.name ?? ""
                    }
                }
            )) {
                Text("اختر الحي").tag(-1)
                ForEach(vm.receiverDistricts) { d in
                    Text(d.nameAr ?? d.name).tag(d.id)
                }
            }
            TextField("العنوان", text: $vm.receiverAddress, axis: .vertical)
                .lineLimit(3 ... 6)
                .textFieldStyle(.roundedBorder)
            TextField("العنوان الوطني (مثال: RRRD2929)", text: $vm.receiverNationalAddress)
                .textInputAutocapitalization(.characters)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("السابق") { vm.step = 1 }
                Spacer()
                Button("التالي") { vm.step = 3 }
                    .buttonStyle(.borderedProminent)
                    .tint(MufaTheme.primary)
            }
        }
    }

    private var shipmentStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("الشحنة").font(.headline)
            TextField("وصف المحتوى", text: $vm.shipmentContent, axis: .vertical)
                .lineLimit(2 ... 5)
                .textFieldStyle(.roundedBorder)
            TextField("القيمة (ر.س)", text: $vm.shipmentValue)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            TextField("الوزن (كجم)", text: $vm.shipmentWeight)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            TextField("عدد الصناديق", text: $vm.noOfBox)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("السابق") { vm.step = 2 }
                Spacer()
                Button("التالي") {
                    vm.step = 4
                    Task { await vm.loadCarriers() }
                }
                .buttonStyle(.borderedProminent)
                .tint(MufaTheme.primary)
            }
        }
    }

    private var carrierStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("شركة الشحن").font(.headline)
            if vm.isBusy { ProgressView() }
            ForEach(vm.carriers) { c in
                Button {
                    vm.selectedCarrier = c
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(c.nameAr ?? c.name).font(.subheadline.bold())
                            Text("\(c.price, specifier: "%.2f") ر.س")
                                .font(.caption)
                                .foregroundStyle(MufaTheme.muted)
                        }
                        Spacer()
                        if vm.selectedCarrier?.id == c.id {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(MufaTheme.primary)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke(vm.selectedCarrier?.id == c.id ? MufaTheme.primary : Color.gray.opacity(0.3)))
                }
                .buttonStyle(.plain)
            }
            HStack {
                Button("السابق") { vm.step = 3 }
                Spacer()
                Button("متابعة للدفع") {
                    vm.step = 5
                    Task { await vm.startPayment(token: session.token) }
                }
                .disabled(vm.selectedCarrier == nil || vm.isBusy)
                .buttonStyle(.borderedProminent)
                .tint(MufaTheme.primary)
            }
        }
    }

    private var paymentStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("الدفع عبر Moyasar").font(.headline)
            if vm.isBusy && !vm.showMoyasar {
                ProgressView("جاري تجهيز الدفع...")
            }
            Text("افتح نموذج الدفع من الزر أدناه إذا لم يظهر تلقائياً.")
            Button("فتح الدفع") {
                Task { await vm.startPayment(token: session.token) }
            }
            .buttonStyle(.borderedProminent)
            .tint(MufaTheme.primary)
            Button("السابق") { vm.step = 4 }
        }
    }

    private func stepNav(next: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button("التالي", action: next)
                .buttonStyle(.borderedProminent)
                .tint(MufaTheme.primary)
        }
    }
}
