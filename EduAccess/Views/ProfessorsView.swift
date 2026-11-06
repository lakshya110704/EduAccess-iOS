import SwiftUI

struct ProfessorsView: View {
    let api: any APIClient
    let welcomeName: String?
    let onLogout: () -> Void
    @State private var viewModel: ProfessorsViewModel

    init(api: any APIClient, welcomeName: String?, onLogout: @escaping () -> Void) {
        self.api = api
        self.welcomeName = welcomeName
        self.onLogout = onLogout
        _viewModel = State(initialValue: ProfessorsViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List(viewModel.professors) { professor in
                NavigationLink(value: professor) {
                    ProfessorRow(professor: professor) {
                        Task { await viewModel.toggleSaved(professor) }
                    }
                }
            }
            .navigationTitle("Professors")
            .navigationDestination(for: Professor.self) { professor in
                BookingView(professor: professor, api: api)
            }
            .toolbar {
                if let welcomeName {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Welcome, \(welcomeName)")
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Log Out", action: onLogout)
                }
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
            .task { await viewModel.autoRefresh() }
            .overlay { placeholder }
            .safeAreaInset(edge: .top) { errorBanner }
        }
    }

    /// With rows on screen a failed refresh keeps them visible, under a message.
    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage, !viewModel.professors.isEmpty {
            Text(error)
                .font(.footnote)
                .foregroundStyle(.red)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if let error = viewModel.errorMessage, viewModel.professors.isEmpty {
            ContentUnavailableView("Could Not Load Professors", systemImage: "wifi.exclamationmark", description: Text(error))
        } else if viewModel.professors.isEmpty && viewModel.hasLoaded {
            if viewModel.isSearching {
                ContentUnavailableView.search(text: viewModel.query)
            } else {
                ContentUnavailableView(
                    "No Saved Professors",
                    systemImage: "magnifyingglass",
                    description: Text("Search above to find a professor, then tap the star to save them here.")
                )
            }
        }
    }
}

private struct ProfessorRow: View {
    let professor: Professor
    let onToggleSaved: () -> Void

    var body: some View {
        HStack {
            details
            Spacer()
            Button(action: onToggleSaved) {
                Image(systemName: professor.isMine ? "star.fill" : "star")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(professor.isMine ? "Remove \(professor.displayName) from saved" : "Save \(professor.displayName)")
        }
    }

    private var details: some View {
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
            if let note = professor.noteSummary {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let open = professor.openTodaySummary {
                Text(open)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
