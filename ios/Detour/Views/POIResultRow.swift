import SwiftUI

struct POIResultRow: View {
    let poi: POIResult
    let isSelected: Bool
    var onNavigate: ((POIResult) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(poi.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(poi.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if poi.rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", poi.rating))
                                .font(.caption)
                            Text("(\(poi.userRatingCount))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if poi.isOpenNow {
                        Text("Open")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.green)
                    } else {
                        Text("Closed")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()

            if onNavigate != nil {
                Button {
                    onNavigate?(poi)
                } label: {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            DetourBadge(poi: poi, isSelected: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
    }
}
