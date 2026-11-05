import SwiftUI

struct ProfessorStatusView: View {
    let api: any APIClient
    let onLogout: () -> Void
    @State private var viewModel: ProfessorStatusViewModel

    init(api: any APIClient, onLogout: @escaping () -> Void) {
        self.api = api
        self.onLogout = onLogout
        _viewModel = State(initialValue: ProfessorStatusViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Availability") {
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(AvailabilityStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                if viewModel.status != .free {
                    noteSection
                }
                Section {
                    Button("Update Status") {
                        Task { await viewModel.save() }
                    }
                    .disabled(viewModel.isSaving || !viewModel.hasLoaded)
                } footer: {
                    if let error = viewModel.errorMessage {
                        Text(error).foregroundStyle(.red)
                    } else if viewModel.didSave {
                        Text("Status updated. Students see it now.")
                    }
                }
                cabinSection
            }
            .navigationTitle("My Status")
            .toolbar {
                Button("Log Out", action: onLogout)
            }
            .task { await viewModel.load() }
        }
    }

    private var noteSection: some View {
        Section("Note for students") {
            Picker("Reason", selection: $viewModel.pick) {
                Text("None").tag("")
                ForEach(viewModel.status.notePicks, id: \.self) { Text($0).tag($0) }
            }
            TextField("Add a short note (optional)", text: $viewModel.text)
            Toggle("Say when you'll be back", isOn: $viewModel.hasUntil)
            if viewModel.hasUntil {
                if viewModel.status == .busy {
                    DatePicker("Back at", selection: $viewModel.until, displayedComponents: .hourAndMinute)
                } else {
                    DatePicker("Back on", selection: $viewModel.until, in: Date()..., displayedComponents: .date)
                }
            }
        }
    }

    private var cabinSection: some View {
        Section {
            if viewModel.hasLoaded && viewModel.cabinLabel.isEmpty {
                Text("Set your cabin before changing anything else.")
            } else {
                LabeledContent("Cabin", value: viewModel.cabinLabel)
            }
            Link("Set Cabin on the Web App", destination: api.webURL("professor/cabin/"))
        } footer: {
            Text("Cabin changes are only available on the web app, which asks you to log in again.")
        }
    }
}
