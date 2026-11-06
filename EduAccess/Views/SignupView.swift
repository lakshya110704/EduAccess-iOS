import SwiftUI

struct SignupView: View {
    @State private var viewModel: SignupViewModel
    @Environment(\.dismiss) private var dismiss

    init(api: any APIClient, role: UserRole) {
        let viewModel = SignupViewModel(api: api)
        viewModel.role = role
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.didSubmit {
                    confirmation
                } else {
                    form
                }
            }
            .navigationTitle(viewModel.didSubmit ? "Request Received" : "Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.didSubmit {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
            }
            .task { await viewModel.loadOptions() }
        }
    }

    private var confirmation: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Waiting for Approval",
                systemImage: "checkmark.circle",
                description: Text("Your account has been created and is waiting for an admin to activate it. You can log in once it's approved.")
            )
            Button("Back to Login") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Spacer()
        }
        .padding()
    }

    private var form: some View {
        Form {
            Section {
                Picker("Role", selection: $viewModel.role) {
                    ForEach(UserRole.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                errors("role")
            } footer: {
                Text("An admin activates your account before you can log in.")
            }
            Section {
                plainField("Username", text: $viewModel.username, content: .username)
                errors("username")
                nameField("First name", text: $viewModel.firstName, field: "first_name", content: .givenName)
                nameField("Middle name (optional)", text: $viewModel.middleName, field: "middle_name", content: .middleName)
                nameField("Last name", text: $viewModel.lastName, field: "last_name", content: .familyName)
                plainField(viewModel.emailPrompt, text: $viewModel.email, content: .emailAddress)
                    .keyboardType(.emailAddress)
                errors("email")
                plainField(viewModel.collegeIdPrompt, text: $viewModel.collegeId, content: nil)
                errors("college_id")
            }
            Section {
                SecureField("Password", text: $viewModel.password1)
                    .textContentType(.newPassword)
                errors("password1")
                SecureField("Re-enter password", text: $viewModel.password2)
                    .textContentType(.newPassword)
                errors("password2")
            }
            Section {
                Button("Request Account") {
                    Task { await viewModel.submit() }
                }
                .disabled(viewModel.isSubmitting)
            } footer: {
                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
    }

    private func plainField(_ title: String, text: Binding<String>, content: UITextContentType?) -> some View {
        TextField(title, text: text)
            .textContentType(content)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    @ViewBuilder
    private func nameField(_ title: String, text: Binding<String>, field: String, content: UITextContentType) -> some View {
        TextField(title, text: text)
            .textContentType(content)
        errors(field)
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
