import SwiftUI

struct EditReasonView: View {
    let appointment: Appointment
    let viewModel: AppointmentsViewModel
    @State private var topic: Appointment.Topic
    @State private var details: String
    @State private var isSaving = false
    @State private var failed = false
    @Environment(\.dismiss) private var dismiss

    init(appointment: Appointment, viewModel: AppointmentsViewModel) {
        self.appointment = appointment
        self.viewModel = viewModel
        _topic = State(initialValue: appointment.topic)
        _details = State(initialValue: appointment.details)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Reason", selection: $topic) {
                        ForEach(Appointment.Topic.allCases) { Text($0.rawValue).tag($0) }
                    }
                    TextField("Details (optional)", text: $details)
                } footer: {
                    if failed, let error = viewModel.errorMessage {
                        Text(error).foregroundStyle(.red)
                    } else {
                        Text("You can change this until the professor confirms.")
                    }
                }
            }
            .navigationTitle("Edit Reason")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        Task {
                            let saved = await viewModel.saveReason(appointment, topic: topic, details: details)
                            isSaving = false
                            failed = !saved
                            if saved { dismiss() }
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
}
