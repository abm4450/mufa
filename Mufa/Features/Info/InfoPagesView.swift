import SwiftUI

enum InfoPageKey: String, CaseIterable, Identifiable, Hashable {
    case pricing, terms, privacy, refund
    var id: String { rawValue }
}

struct InfoPagesView: View {
    let pageKey: InfoPageKey
    var onDismiss: (() -> Void)?

    private var content: InfoContent {
        InfoContent.pages[pageKey]!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content.title)
                    .font(.title2.bold())
                    .foregroundStyle(MufaTheme.primaryDark)
                if let intro = content.intro {
                    Text(intro)
                        .font(.body)
                        .foregroundStyle(MufaTheme.foreground)
                }
                ForEach(Array(content.sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 8) {
                        if let t = section.title {
                            Text(t).font(.headline)
                        }
                        if let text = section.text {
                            Text(text).font(.body).foregroundStyle(MufaTheme.muted)
                        }
                        if let list = section.list {
                            ForEach(list, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                    Text(item).font(.body)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: MufaTheme.cornerRadius)
                            .fill(section.highlight == true ? MufaTheme.primary.opacity(0.08) : MufaTheme.cardBackground)
                    )
                }
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle(content.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onDismiss {
                ToolbarItem(placement: .confirmationAction) {
                    Button("إغلاق") { onDismiss() }
                }
            }
        }
    }
}

struct InfoContent {
    let title: String
    let intro: String?
    let sections: [Section]

    struct Section {
        let title: String?
        let text: String?
        let list: [String]?
        let highlight: Bool?
    }

    static let pages: [InfoPageKey: InfoContent] = [
        .pricing: InfoContent(
            title: "الخدمات والأسعار",
            intro: "منصة MUFA هي منصة وسيطة لإدارة الشحنات تتيح للمستخدمين إنشاء الشحنات وربطها مع شركات الشحن المختلفة من خلال لوحة تحكم واحدة بسهولة.",
            sections: [
                .init(title: "الخدمات المتوفرة", text: nil, list: [
                    "إنشاء الشحنات بسهولة عبر المنصة",
                    "ربط الشحنات مع شركات الشحن المتاحة",
                    "إصدار رقم تتبع للشحنة",
                    "متابعة حالة الشحنة",
                    "إدارة جميع الشحنات من لوحة تحكم واحدة",
                ], highlight: nil),
                .init(title: "رسوم الخدمة", text: "تفرض منصة MUFA رسوم خدمة على كل شحنة يتم إنشاؤها عبر المنصة.", list: nil, highlight: nil),
                .init(title: "سعر الخدمة", text: "25 ريال سعودي لكل شحنة", list: nil, highlight: true),
                .init(title: "ملاحظة", text: "قد يختلف سعر الشحن النهائي حسب شركة الشحن ووزن الشحنة ومدينة التسليم.", list: nil, highlight: nil),
            ]
        ),
        .terms: InfoContent(
            title: "الشروط والأحكام",
            intro: "باستخدامك لمنصة MUFA فإنك توافق على الالتزام بالشروط والأحكام التالية.",
            sections: [
                .init(title: "مسؤولية المستخدم", text: nil, list: [
                    "إدخال بيانات الشحن بشكل صحيح",
                    "عدم استخدام المنصة لشحن مواد محظورة",
                    "استخدام المنصة للأغراض القانونية فقط",
                ], highlight: nil),
                .init(title: "دور المنصة", text: "تعمل منصة MUFA كوسيط تقني بين المستخدم وشركات الشحن.", list: nil, highlight: nil),
                .init(title: "مسؤولية الشحن", text: "تتحمل شركات الشحن مسؤولية نقل الشحنات وتسليمها وأي تأخير قد يحدث أثناء عملية الشحن.", list: nil, highlight: nil),
                .init(title: "إيقاف الحساب", text: "يحق للمنصة تعليق أو إيقاف حساب أي مستخدم في حال إساءة استخدام الخدمة.", list: nil, highlight: nil),
                .init(title: "تعديل الشروط", text: "تحتفظ منصة MUFA بحق تعديل هذه الشروط في أي وقت.", list: nil, highlight: nil),
            ]
        ),
        .privacy: InfoContent(
            title: "سياسة الخصوصية",
            intro: nil,
            sections: [
                .init(title: "المعلومات التي يتم جمعها", text: nil, list: ["الاسم", "رقم الهاتف", "البريد الإلكتروني", "عنوان الشحن", "بيانات الشحنة"], highlight: nil),
                .init(title: "استخدام المعلومات", text: nil, list: ["إنشاء الشحنات", "تحسين تجربة المستخدم", "تقديم الدعم الفني", "التواصل مع المستخدم"], highlight: nil),
                .init(title: "مشاركة المعلومات", text: "قد تتم مشاركة بعض البيانات مع شركات الشحن أو مزودي خدمات الدفع عند الحاجة لتنفيذ الخدمة.", list: nil, highlight: nil),
                .init(title: "حماية البيانات", text: "تستخدم المنصة تقنيات أمان حديثة لحماية بيانات المستخدمين.", list: nil, highlight: nil),
            ]
        ),
        .refund: InfoContent(
            title: "سياسة الاسترجاع",
            intro: nil,
            sections: [
                .init(title: "الحالات التي يمكن فيها طلب الاسترجاع", text: nil, list: ["فشل إنشاء الشحنة بسبب خطأ تقني", "الدفع المكرر عن طريق الخطأ", "عدم تنفيذ الخدمة"], highlight: nil),
                .init(title: "الحالات التي لا يمكن فيها الاسترجاع", text: nil, list: ["بعد تنفيذ الشحنة بنجاح", "في حال إدخال بيانات خاطئة من قبل المستخدم"], highlight: nil),
                .init(title: "مدة معالجة الطلب", text: "تتم معالجة طلبات الاسترجاع خلال: 5 إلى 14 يوم عمل", list: nil, highlight: nil),
                .init(title: "طريقة الاسترجاع", text: "يتم إعادة المبلغ إلى نفس وسيلة الدفع المستخدمة.", list: nil, highlight: nil),
            ]
        ),
    ]
}
