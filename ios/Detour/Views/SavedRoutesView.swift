import SwiftUI

struct SavedRoutesView: View {
    let routes: [SavedRoute]
    let onSelect: (SavedRoute) -> Void
    let onDelete: (SavedRoute) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(routes) { route in
                    savedRouteCard(route)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func savedRouteCard(_ route: SavedRoute) -> some View {
        Button {
            onSelect(route)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                    Text(route.destinationName)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDelete(route)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
