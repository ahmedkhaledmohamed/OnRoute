import SwiftUI
import FirebaseCore

@main
struct DetourApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseApp.configure()
    }

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
}
