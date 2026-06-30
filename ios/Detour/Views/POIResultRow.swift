import SwiftUI

struct POIResultRow: View {
    let poi: POIResult
    let isSelected: Bool
    var onNavigate: ((POIResult) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            photoView

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

                    if poi.visited {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                            Text("Visited")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.blue)
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

                    if let price = poi.priceLevelDisplay {
                        Text(price)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let hours = poi.todayHours {
                        Text(hours)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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

    @ViewBuilder
    private var photoView: some View {
        if let ref = poi.photoReference {
            AsyncImage(url: URL(string: "\(APIService.baseURL)/api/photo?ref=\(ref)&maxWidth=200")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                default:
                    photoPlaceholder
                }
            }
        } else {
            photoPlaceholder
        }
    }

    private var photoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.tertiary)
            }
    }
}
