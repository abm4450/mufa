import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MufaTheme.backgroundTop, MufaTheme.backgroundMid, MufaTheme.backgroundTop],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [MufaTheme.primary.opacity(0.04), Color.clear, MufaTheme.accent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}
