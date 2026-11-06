import SwiftUI

struct AppointmentsView: View {
    let role: UserRole
    @State private var viewModel: AppointmentsViewModel
    @State private var appointmentToCancel: Appointment?
    @State private var appointmentToEdit: Appointment?

    init(api: any APIClient, role: UserRole) {
        self.role = role
        _viewModel = State(initialValue: AppointmentsViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List(viewModel.appointments) { appointment in
                row(appointment)
            }
            .navigationTitle(role == .student ? "Appointments" : "Requests")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .task { await viewModel.autoRefresh() }
            .overlay { placeholder }
            .safeAreaInset(edge: .top) { errorBanner }
            .sheet(item: $appointmentToEdit) { appointment in
                EditReasonView(appointment: appointment, viewModel: viewModel)
            }
            .alert("Cancel Appointment?", isPresented: isConfirmingCancel, presenting: appointmentToCancel) { appointment in
                Button("Cancel Appointment", role: .destructive) {
                    Task { await viewModel.cancel(appointment) }
                }
                Button("Keep", role: .cancel) {}
            } message: { appointment in
                Text("With \(otherPerson(appointment)). This cannot be undone.")
            }
        }
    }

    private var isConfirmingCancel: Binding<Bool> {
        Binding(get: { appointmentToCancel != nil }, set: { if !$0 { appointmentToCancel = nil } })
    }

    private func otherPerson(_ appointment: Appointment) -> String {
        role == .student ? appointment.professorName : appointment.studentName
    }

    private func row(_ appointment: Appointment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(otherPerson(appointment))
                    .font(.headline)
                Text(appointment.appointmentTime.formatted(date: .abbreviated, time: .shortened))
                Text("\(appointment.topic.rawValue) · \(appointment.status.rawValue)")
                    .foregroundStyle(.secondary)
                if !appointment.details.isEmpty {
                    Text(appointment.details)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            Spacer()
            VStack(alignment: .trailing, spacing: 12) {
                if role == .professor && appointment.canConfirm {
                    Button("Confirm") {
                        Task { await viewModel.confirm(appointment) }
                    }
                    .buttonStyle(.borderless)
                }
                if role == .student && appointment.canEditReason {
                    Button("Edit") { appointmentToEdit = appointment }
                        .buttonStyle(.borderless)
                }
                if appointment.canCancel {
                    Button("Cancel", role: .destructive) { appointmentToCancel = appointment }
                        .buttonStyle(.borderless)
                }
            }
        }
    }

    /// With rows on screen a failed action or refresh keeps them visible, under a message.
    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage, !viewModel.appointments.isEmpty {
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
        if let error = viewModel.errorMessage, viewModel.appointments.isEmpty {
            ContentUnavailableView("Could Not Load Appointments", systemImage: "wifi.exclamationmark", description: Text(error))
        } else if viewModel.appointments.isEmpty && viewModel.hasLoaded {
            ContentUnavailableView(
                role == .student ? "No Appointments" : "No Requests",
                systemImage: "calendar",
                description: Text(role == .student ? "Pick a professor to request one." : "Student requests appear here.")
            )
        }
    }
}
