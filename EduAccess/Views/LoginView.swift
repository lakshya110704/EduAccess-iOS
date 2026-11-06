import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: LoginViewModel
    let signupURL: URL

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 96)
                    .accessibilityLabel("EduAccess")
                Picker("Role", selection: $viewModel.role) {
                    ForEach(UserRole.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                TextField("Username", text: $viewModel.username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await viewModel.login() } }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await viewModel.login() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Log In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit)

                // The backend has no sign-up API yet, so this opens the website's form.
                Link("New to EduAccess? Create an account", destination: signupURL)
                    .font(.footnote)
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
    }
}
