import SwiftUI
import MapKit

struct RouteInputSheet: View {
    @Bindable var viewModel: RouteViewModel
    var locationManager: LocationManager
    var onSearch: () -> Void

    @FocusState private var focusedField: Field?
    @State private var waitingForLocation = false

    enum Field: Hashable {
        case origin, destination
    }

    private var activeSuggestions: [MKLocalSearchCompletion] {
        switch focusedField {
        case .origin: return viewModel.originSuggestions
        case .destination: return viewModel.destinationSuggestions
        case nil: return []
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            handle

            VStack(spacing: 12) {
                originField
                destinationField
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            travelModePicker
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if !activeSuggestions.isEmpty {
                suggestionsList
            }

            if viewModel.travelMode != .drive {
                Text("Places shown along driving route")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            searchButton
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            if waitingForLocation, let loc = locationManager.currentLocation {
                viewModel.useCurrentLocation(loc)
                focusedField = nil
                waitingForLocation = false
            }
        }
    }

    private var handle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(.secondary.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
    }

    private var originField: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.green)

            TextField("From", text: Binding(
                get: { viewModel.originQuery },
                set: { viewModel.updateOriginQuery($0) }
            ))
            .textFieldStyle(.plain)
            .focused($focusedField, equals: .origin)
            .textContentType(.fullStreetAddress)
            .autocorrectionDisabled()

            if viewModel.originQuery.isEmpty {
                Button {
                    waitingForLocation = true
                    locationManager.requestPermission()
                    locationManager.requestLocation()
                } label: {
                    if waitingForLocation {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                Button {
                    viewModel.updateOriginQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
    }

    private var destinationField: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.red)

            TextField("To", text: Binding(
                get: { viewModel.destinationQuery },
                set: { viewModel.updateDestinationQuery($0) }
            ))
            .textFieldStyle(.plain)
            .focused($focusedField, equals: .destination)
            .textContentType(.fullStreetAddress)
            .autocorrectionDisabled()

            if !viewModel.destinationQuery.isEmpty {
                Button {
                    viewModel.updateDestinationQuery("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                viewModel.swapOriginDestination()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
    }

    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(activeSuggestions, id: \.self) { suggestion in
                    Button {
                        if focusedField == .origin {
                            viewModel.selectOrigin(suggestion)
                        } else {
                            viewModel.selectDestination(suggestion)
                        }
                        focusedField = nil
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    Divider().padding(.leading, 16)
                }
            }
        }
        .frame(maxHeight: 200)
    }

    private var travelModePicker: some View {
        HStack(spacing: 0) {
            ForEach(RouteViewModel.TravelMode.allCases) { mode in
                Button {
                    viewModel.travelMode = mode
                    viewModel.route = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))
                        Text(mode.label)
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.travelMode == mode
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .foregroundStyle(viewModel.travelMode == mode ? Color.accentColor : .secondary)
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
    }

    private var searchButton: some View {
        Button {
            focusedField = nil
            onSearch()
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Search Along Route")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isSearchReady)
    }
}
