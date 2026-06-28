import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 12) {
                Text("OnRoute")
                    .font(.largeTitle.weight(.bold))

                Text("Find what's worth the stop")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 20) {
                featureRow(
                    icon: "mappin.and.ellipse",
                    title: "Search along your route",
                    description: "Enter where you're going and what you're looking for"
                )
                featureRow(
                    icon: "clock.badge.checkmark",
                    title: "Ranked by detour time",
                    description: "Every result shows how many minutes it adds to your trip"
                )
                featureRow(
                    icon: "slider.horizontal.3",
                    title: "Set your max detour",
                    description: "Only see places within your time budget"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                hasSeenOnboarding = true
                AnalyticsService.shared.track("onboarding_completed")
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.tint)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
