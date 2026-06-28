import SwiftUI

@main
struct DetourApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                AnalyticsService.shared.track("app_opened")
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase
}
