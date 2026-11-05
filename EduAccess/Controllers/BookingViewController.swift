//
//  BookingViewController.swift
//  EduAccess
//
//  Created by Lakshya Mehta on 04/11/25.
//
import UIKit

final class BookingViewController: UIViewController {

    @IBOutlet weak var professorLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var confirmButton: UIButton!

    var selectedProfessor: Professor?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Book Appointment"
        view.backgroundColor = .systemBackground

        // setup
        professorLabel.text = selectedProfessor?.name
        datePicker.minimumDate = Date()
        datePicker.preferredDatePickerStyle = .wheels

        confirmButton.layer.cornerRadius = 8
        confirmButton.setTitle("Confirm Booking", for: .normal)
        confirmButton.backgroundColor = UIColor(red: 47/255, green: 191/255, blue: 154/255, alpha: 1.0)
        confirmButton.setTitleColor(.white, for: .normal)
    }

    @IBAction func confirmBookingTapped(_ sender: Any) {
        guard let professor = selectedProfessor else { return }
        let selectedDate = datePicker.date.formatted(date: .abbreviated, time: .shortened)
        let alert = UIAlertController(
            title: "Booking Confirmed 🎉",
            message: "You booked a meeting with \(professor.name) on \(selectedDate).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
