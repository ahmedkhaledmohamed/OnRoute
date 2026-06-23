import SwiftUI
import MapKit

struct RouteInputSheet: View {
    @Bindable var viewModel: RouteViewModel
    var locationManager: LocationManager
    var onSearch: () -> Void

    @State private var activeField: Field?

    enum Field {
        case origin, destination
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

            if activeField != nil {
                suggestionsList
            }

            searchButton
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
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
            .onTapGesture { activeField = .origin }

            if viewModel.originQuery.isEmpty {
                Button {
                    locationManager.requestPermission()
                    locationManager.requestLocation()
                    if let loc = locationManager.currentLocation {
                        viewModel.useCurrentLocation(loc)
                        activeField = nil
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                }
            } else {
                Button {
                    viewModel.originQuery = ""
                    viewModel.originCoordinate = nil
                    viewModel.originName = nil
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
            .onTapGesture { activeField = .destination }

            if !viewModel.destinationQuery.isEmpty {
                Button {
                    viewModel.destinationQuery = ""
                    viewModel.destinationCoordinate = nil
                    viewModel.destinationName = nil
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
        let suggestions = activeField == .origin
            ? viewModel.originSuggestions
            : viewModel.destinationSuggestions

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        if activeField == .origin {
                            viewModel.selectOrigin(suggestion)
                        } else {
                            viewModel.selectDestination(suggestion)
                        }
                        activeField = nil
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

    private var searchButton: some View {
        Button(action: onSearch) {
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
