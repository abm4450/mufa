import SwiftUI

enum AppTab: Hashable {
    case create, shipments, track, bot, profile
}

struct MainShellView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var tab: AppTab = .create
    @State private var showAuth = false
    @State private var authReturnTab: AppTab = .shipments

    var body: some View {
        ZStack {
            AppBackground()
            TabView(selection: $tab) {
                CreateShipmentView()
                    .tabItem { Label("إنشاء شحنة", systemImage: "shippingbox") }
                    .tag(AppTab.create)

                ShipmentsListView()
                    .tabItem { Label("شحناتي", systemImage: "list.bullet.rectangle") }
                    .tag(AppTab.shipments)

                TrackView()
                    .tabItem { Label("تتبع", systemImage: "location.circle") }
                    .tag(AppTab.track)

                ChatBotView()
                    .tabItem { Label("مساعد", systemImage: "bubble.left.and.bubble.right") }
                    .tag(AppTab.bot)

                ProfileView()
                    .tabItem { Label("حسابي", systemImage: "person.circle") }
                    .tag(AppTab.profile)
            }
            .tint(MufaTheme.primary)
        }
        .sheet(isPresented: $showAuth) {
            LoginRegisterView(onSuccess: {
                showAuth = false
                tab = authReturnTab
            })
            .environmentObject(session)
        }
        .onChange(of: tab) { _, newValue in
            if (newValue == .shipments || newValue == .profile), !session.isLoggedIn {
                authReturnTab = newValue
                showAuth = true
                tab = .create
            }
        }
    }
}
