import SwiftUI

struct BookingView: View {
    @State private var viewModel: BookingViewModel
    @Environment(\.dismiss) private var dismiss

    init(professor: Professor, api: any APIClient) {
        _viewModel = State(initialValue: BookingViewModel(professor: professor, api: api))
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Status", value: viewModel.professor.availabilityStatus.rawValue)
                if !viewModel.professor.cabinLabel.isEmpty {
                    LabeledContent("Cabin", value: viewModel.professor.cabinLabel)
                }
            }
            Section {
                DatePicker("Time", selection: $viewModel.date, in: Date()...)
                Picker("Reason", selection: $viewModel.topic) {
                    ForEach(Appointment.Topic.allCases) { Text($0.rawValue).tag($0) }
                }
            } footer: {
                Text("Appointments start on the quarter hour. This request is for \(viewModel.slotStart.formatted(date: .abbreviated, time: .shortened)).")
            }
            if let error = viewModel.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
            Section {
                Button("Request Appointment") {
                    Task { await viewModel.book() }
                }
                .disabled(viewModel.isBooking)
            }
        }
        .navigationTitle(viewModel.professor.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Request Sent", isPresented: .constant(viewModel.didBook)) {
            Button("OK") { dismiss() }
        } message: {
            Text("It stays pending until the professor confirms it. See it under Appointments.")
        }
    }
}
