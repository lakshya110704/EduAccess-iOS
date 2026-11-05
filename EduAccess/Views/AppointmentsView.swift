import SwiftUI

struct AppointmentsView: View {
    @State private var viewModel: AppointmentsViewModel
    @State private var appointmentToCancel: Appointment?

    init(api: any APIClient) {
        _viewModel = State(initialValue: AppointmentsViewModel(api: api))
    }

    var body: some View {
        NavigationStack {
            List(viewModel.appointments) { appointment in
                row(appointment)
            }
            .navigationTitle("Appointments")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .overlay { placeholder }
            .alert("Cancel Appointment?", isPresented: isConfirmingCancel, presenting: appointmentToCancel) { appointment in
                Button("Cancel Appointment", role: .destructive) {
                    Task { await viewModel.cancel(appointment) }
                }
                Button("Keep", role: .cancel) {}
            } message: { appointment in
                Text("With \(appointment.professorName). This cannot be undone.")
            }
        }
    }

    private var isConfirmingCancel: Binding<Bool> {
        Binding(get: { appointmentToCancel != nil }, set: { if !$0 { appointmentToCancel = nil } })
    }

    private func row(_ appointment: Appointment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.professorName)
                    .font(.headline)
                Text(appointment.appointmentTime.formatted(date: .abbreviated, time: .shortened))
                Text("\(appointment.topic.rawValue) · \(appointment.status.rawValue)")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            Spacer()
            if appointment.canCancel {
                Button("Cancel", role: .destructive) { appointmentToCancel = appointment }
                    .buttonStyle(.borderless)
            }
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if let error = viewModel.errorMessage {
            ContentUnavailableView("Could Not Load Appointments", systemImage: "wifi.exclamationmark", description: Text(error))
        } else if viewModel.appointments.isEmpty && !viewModel.isLoading {
            ContentUnavailableView(
                "No Appointments",
                systemImage: "calendar",
                description: Text("Pick a professor to request one.")
            )
        }
    }
}
