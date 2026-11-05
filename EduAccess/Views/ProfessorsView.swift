import SwiftUI

struct ProfessorsView: View {
    let api: any APIClient
    let onLogout: () -> Void
    @State private var viewModel: ProfessorsViewModel

    init(api: any APIClient, onLogout: @escaping () -> Void) {
        self.api = api
        self.onLogout = onLogout
        _viewModel = State(initialValue: ProfessorsViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List(viewModel.professors) { professor in
                NavigationLink(value: professor) {
                    ProfessorRow(professor: professor)
                }
            }
            .navigationTitle("Professors")
            .navigationDestination(for: Professor.self) { professor in
                BookingView(professor: professor, api: api)
            }
            .toolbar {
                Button("Log Out", action: onLogout)
            }
            .searchable(text: $viewModel.query, prompt: "Search name, cabin or block")
            .autocorrectionDisabled()
            .refreshable { await viewModel.load() }
            .task(id: viewModel.query) {
                // Wait for a pause in typing. The first load has an empty query and runs at once.
                if !viewModel.query.isEmpty {
                    try? await Task.sleep(for: .milliseconds(300))
                    if Task.isCancelled { return }
                }
                await viewModel.load()
            }
            .overlay { placeholder }
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if let error = viewModel.errorMessage {
            ContentUnavailableView("Could Not Load Professors", systemImage: "wifi.exclamationmark", description: Text(error))
        } else if viewModel.professors.isEmpty && !viewModel.isLoading {
            if viewModel.isSearching {
                ContentUnavailableView.search(text: viewModel.query)
            } else {
                ContentUnavailableView(
                    "No Saved Professors",
                    systemImage: "magnifyingglass",
                    description: Text("Search above to find a professor and see their availability.")
                )
            }
        }
    }
}

private struct ProfessorRow: View {
    let professor: Professor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(professor.displayName)
                .font(.headline)
            HStack(spacing: 6) {
                Circle()
                    .fill(professor.availabilityStatus.color)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(professor.availabilityStatus.rawValue)
                if !professor.cabinLabel.isEmpty {
                    Text("·").accessibilityHidden(true)
                    Text(professor.cabinLabel)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
