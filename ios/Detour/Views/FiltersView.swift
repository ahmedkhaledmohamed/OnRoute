import SwiftUI

struct CategoryBar: View {
    @Bindable var viewModel: RouteViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    viewModel.toggleTimeBudgetMode()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("Browse All")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        viewModel.timeBudgetMode
                            ? Color.orange
                            : Color(.systemGray5),
                        in: Capsule()
                    )
                    .foregroundStyle(viewModel.timeBudgetMode ? .white : .primary)
                }

                ForEach(RouteViewModel.Category.allCases) { category in
                    Button {
                        if viewModel.timeBudgetMode {
                            viewModel.toggleTimeBudgetMode()
                        }
                        viewModel.selectCategory(category)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.rawValue)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            viewModel.selectedCategory == category
                                ? Color.accentColor
                                : Color(.systemGray5),
                            in: Capsule()
                        )
                        .foregroundStyle(
                            viewModel.selectedCategory == category
                                ? .white
                                : .primary
                        )
                    }
                    .accessibilityLabel("Search for \(category.rawValue)")
                    .accessibilityAddTraits(viewModel.selectedCategory == category ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct MultiStopBar: View {
    @Bindable var viewModel: RouteViewModel
    @State private var showAddStop = false
    var onNavigateAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.selectedStops.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        Text("Your Route")
                            .font(.caption.weight(.bold))
                        Text("(\(viewModel.selectedStops.count) \(viewModel.selectedStops.count == 1 ? "stop" : "stops"))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if viewModel.selectedStops.count >= 2 {
                            Button {
                                onNavigateAll()
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.system(size: 9))
                                    Text("Navigate")
                                        .font(.caption2.weight(.semibold))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue, in: Capsule())
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ForEach(Array(viewModel.selectedStops.enumerated()), id: \.element.placeId) { idx, stop in
                        HStack(spacing: 6) {
                            Text("\(idx + 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .frame(width: 18, height: 18)
                                .background(.orange, in: Circle())
                                .foregroundStyle(.white)

                            Text(stop.name)
                                .font(.caption)
                                .lineLimit(1)

                            Text(stop.detourFormatted)
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                viewModel.selectedStops.removeAll { $0.placeId == stop.placeId }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    let totalDetour = viewModel.selectedStops.reduce(0) { $0 + $1.detourSeconds }
                    let totalMin = totalDetour / 60
                    Text("Total detour: +\(totalMin) min")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                }
                .padding(10)
                .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(RouteViewModel.Category.allCases) { cat in
                        if cat.query != viewModel.searchQuery && !viewModel.additionalQueries.contains(cat.query) {
                            Button {
                                viewModel.addStop(cat)
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 8, weight: .bold))
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 10))
                                    Text(cat.rawValue)
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color(.systemGray5), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct FiltersBar: View {
    @Bindable var viewModel: RouteViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Max detour: \(Int(viewModel.maxDetourMinutes)) min")
                    .font(.caption.weight(.medium))
                Spacer()
                Toggle("Open now", isOn: $viewModel.openNowOnly)
                    .font(.caption.weight(.medium))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
            }
            .padding(.horizontal, 16)

            Slider(
                value: $viewModel.maxDetourMinutes,
                in: 1...30,
                step: 1
            )
            .accessibilityLabel("Maximum detour time")
            .accessibilityValue("\(Int(viewModel.maxDetourMinutes)) minutes")
            .padding(.horizontal, 16)
        }
    }
}
