import Foundation
import Observation

@MainActor
@Observable
final class ProfessorStatusViewModel {
    var status = AvailabilityStatus.unavailable {
        didSet {
            if !status.notePicks.contains(pick) { pick = "" }
            if status != oldValue { resetUntil() }
        }
    }
    var pick = ""
    var text = ""
    var hasUntil = false
    var until = Date()
    private(set) var cabinLabel = ""
    private(set) var hasLoaded = false
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func load() async {
        do {
            apply(try await api.me())
            hasLoaded = true
            errorMessage = nil
        } catch where error.isCancellation {
            // The screen went away.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cabinChanged(to label: String) {
        cabinLabel = label
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        didSave = false
        defer { isSaving = false }
        do {
            apply(try await api.updateAvailability(update))
            didSave = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var update: AvailabilityUpdate {
        guard status != .free else {
            return AvailabilityUpdate(availabilityStatus: .free, statusPick: "", statusText: "", statusUntil: nil)
        }
        // Busy means back at a time today; Unavailable means back from the start of a day.
        let back = status == .busy ? until : Calendar.current.startOfDay(for: until)
        return AvailabilityUpdate(
            availabilityStatus: status,
            statusPick: pick,
            statusText: text.trimmingCharacters(in: .whitespacesAndNewlines),
            statusUntil: hasUntil ? back : nil
        )
    }

    private func resetUntil() {
        hasUntil = false
        until = status == .busy
            ? Date().addingTimeInterval(60 * 60)
            : Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    private func apply(_ me: Me) {
        status = me.availabilityStatus
        pick = me.statusNote?.pick ?? ""
        text = me.statusNote?.text ?? ""
        if let back = me.statusNote?.until {
            hasUntil = true
            until = back
        }
        cabinLabel = me.cabinLabel
    }
}
