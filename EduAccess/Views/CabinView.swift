import SwiftUI

struct CabinView: View {
    let currentLabel: String
    let isFirstTime: Bool
    let onSaved: (Me) -> Void
    let onLogout: () -> Void
    @State private var viewModel: CabinViewModel
    @Environment(\.dismiss) private var dismiss

    init(api: any APIClient, currentLabel: String, isFirstTime: Bool, onSaved: @escaping (Me) -> Void, onLogout: @escaping () -> Void = {}) {
        self.currentLabel = currentLabel
        self.isFirstTime = isFirstTime
        self.onSaved = onSaved
        self.onLogout = onLogout
        _viewModel = State(initialValue: CabinViewModel(api: api, currentLabel: currentLabel))
    }

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.hasLoaded && viewModel.blocks.isEmpty {
                    Text("No campus blocks are set up yet. Please ask the EduAccess admin to add them.")
                        .foregroundStyle(.red)
                } else {
                    fields
                }
            }
            .navigationTitle(isFirstTime ? "Where's Your Cabin?" : "Your Cabin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isFirstTime {
                        Button("Log Out", action: onLogout)
                    } else {
                        Button("Close") { dismiss() }
                    }
                }
            }
            .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var fields: some View {
        Section {
            Picker("Academic block", selection: $viewModel.academicBlockID) {
                Text("Choose").tag(Int?.none)
                ForEach(viewModel.blocks) { Text($0.name).tag(Int?.some($0.id)) }
            }
            errors("academic_block")
            Picker("Faculty block", selection: $viewModel.facultyBlockID) {
                Text("Choose").tag(Int?.none)
                ForEach(viewModel.facultyOptions) { Text($0.title).tag(Int?.some($0.id)) }
            }
            .disabled(viewModel.academicBlockID == nil)
            errors("faculty_block")
            TextField("Cabin number", text: $viewModel.cabin)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            errors("cabin")
        } footer: {
            if isFirstTime {
                Text("Students use this to find you and get directions. You can change it later.")
            } else if !currentLabel.isEmpty {
                Text("Currently \(currentLabel). Students see the change right away.")
            }
        }
        Section {
            Button("Save Cabin") {
                Task {
                    if let me = await viewModel.save() {
                        onSaved(me)
                        if !isFirstTime { dismiss() }
                    }
                }
            }
            .disabled(viewModel.isSaving || !viewModel.hasLoaded)
        } footer: {
            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private func errors(_ field: String) -> some View {
        ForEach(viewModel.fieldErrors[field] ?? [], id: \.self) {
            Text($0)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }
}
