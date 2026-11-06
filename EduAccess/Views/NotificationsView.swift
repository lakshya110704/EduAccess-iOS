import SwiftUI

struct NotificationsView: View {
    @State private var viewModel: NotificationsViewModel

    init(api: any APIClient) {
        _viewModel = State(initialValue: NotificationsViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List(viewModel.notifications) { notification in
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.message)
                    Text(notification.sentAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .navigationTitle("Notifications")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .task { await viewModel.autoRefresh() }
            .overlay { placeholder }
            .safeAreaInset(edge: .top) { errorBanner }
        }
    }

    /// With rows on screen a failed refresh keeps them visible, under a message.
    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage, !viewModel.notifications.isEmpty {
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
        if let error = viewModel.errorMessage, viewModel.notifications.isEmpty {
            ContentUnavailableView("Could Not Load Notifications", systemImage: "wifi.exclamationmark", description: Text(error))
        } else if viewModel.notifications.isEmpty && viewModel.hasLoaded {
            ContentUnavailableView("No Notifications Yet", systemImage: "bell")
        }
    }
}
