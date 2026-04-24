import SwiftUI

@main
struct MufaApp: App {
    var body: some Scene {
        WindowGroup {
            MainShellView()
                .environmentObject(SessionStore.shared)
                .environment(\.locale, Locale(identifier: "ar"))
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}
