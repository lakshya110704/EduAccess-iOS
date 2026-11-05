import SwiftUI

struct OpenTimeView: View {
    @State private var viewModel: OpenTimeViewModel

    init(api: any APIClient) {
        _viewModel = State(initialValue: OpenTimeViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("From", selection: $viewModel.start, displayedComponents: .hourAndMinute)
                    DatePicker("Until", selection: $viewModel.end, displayedComponents: .hourAndMinute)
                    Button("Add Walk-In Time") {
                        Task { await viewModel.add() }
                    }
                    .disabled(viewModel.isSaving)
                } header: {
                    Text("Add for today")
                } footer: {
                    if let error = viewModel.errorMessage {
                        Text(error).foregroundStyle(.red)
                    } else {
                        Text("Students can walk in during this time and cannot book it. Pending requests it covers are declined. Times round up to the quarter hour.")
                    }
                }
                if !viewModel.windows.isEmpty {
                    Section("Today") {
                        ForEach(viewModel.windows) { window in
                            HStack {
                                Text("\(window.start.formatted(date: .omitted, time: .shortened)) to \(window.end.formatted(date: .omitted, time: .shortened))")
                                Spacer()
                                Button("Remove", role: .destructive) {
                                    Task { await viewModel.remove(window) }
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Walk-In Time")
            .task { await viewModel.load() }
        }
    }
}
