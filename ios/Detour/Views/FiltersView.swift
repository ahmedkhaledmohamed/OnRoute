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
                }
            }
            .padding(.horizontal, 16)
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
            .padding(.horizontal, 16)
        }
    }
}
