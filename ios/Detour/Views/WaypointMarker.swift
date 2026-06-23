import SwiftUI

struct WaypointMarker: View {
    let letter: String
    let color: Color
    let label: String?

    init(_ letter: String, color: Color, label: String? = nil) {
        self.letter = letter
        self.color = color
        self.label = label
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)

                Text(letter)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            if let label {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .lineLimit(1)
            }
        }
    }
}
