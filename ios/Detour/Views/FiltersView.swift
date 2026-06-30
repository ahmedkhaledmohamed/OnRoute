import SwiftUI

struct CategoryBar: View {
    @Bindable var viewModel: RouteViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RouteViewModel.Category.allCases) { category in
                    Button {
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

    var body: some View {
        if !viewModel.additionalQueries.isEmpty || showAddStop {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Stops:")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(Array(viewModel.additionalQueries.enumerated()), id: \.offset) { index, query in
                        HStack(spacing: 4) {
                            Text(query)
                                .font(.caption2.weight(.medium))
                            Button {
                                viewModel.removeStop(at: index)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                        .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal, 16)

                if showAddStop {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(RouteViewModel.Category.allCases) { cat in
                                if cat.query != viewModel.searchQuery && !viewModel.additionalQueries.contains(cat.query) {
                                    Button {
                                        viewModel.addStop(cat)
                                        showAddStop = false
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 10))
                                            Text(cat.rawValue)
                                                .font(.caption2)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
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

        Button {
            showAddStop.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                Text("Add stop")
                    .font(.caption2.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.systemGray5), in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
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
