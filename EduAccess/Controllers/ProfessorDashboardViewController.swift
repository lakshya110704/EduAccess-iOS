//
//  ProfessorDashboardViewController.swift
//  EduAccess
//
//  Created by Lakshya Mehta on 14/10/25.
//
import UIKit
import CoreData

final class ProfessorDashboardViewController: UIViewController {

    /// The professor this dashboard edits. Until real per-user auth exists,
    /// this is a stand-in: the first professor alphabetically.
    private var professor: Professor?

    private var context: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    private var currentStatus: AvailabilityStatus = .unavailable {
        didSet { updateStatusDisplay() }
    }

    private let statusDotView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 7
        return v
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let items = AvailabilityStatus.allCases.map { $0.displayText }
        let sc = UISegmentedControl(items: items)
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.addTarget(self, action: #selector(statusChanged(_:)), for: .valueChanged)
        return sc
    }()

    private let captionLabel: UILabel = {
        let l = UILabel()
        l.text = "Let students know whether you're free for a visit."
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutTapped))
        title = "Dashboard"
        view.backgroundColor = .systemBackground

        setupAvailabilityCard()
        loadProfessor()
        currentStatus = professor?.status ?? .unavailable
        segmentedControl.selectedSegmentIndex = AvailabilityStatus.allCases.firstIndex(of: currentStatus) ?? 0
    }

    private func loadProfessor() {
        let request: NSFetchRequest<Professor> = Professor.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.fetchLimit = 1
        professor = try? context.fetch(request).first
    }

    private func setupAvailabilityCard() {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 14

        let headerLabel = UILabel()
        headerLabel.text = "Your Availability"
        headerLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headerLabel.textColor = .secondaryLabel
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        let statusRow = UIStackView(arrangedSubviews: [statusDotView, statusLabel])
        statusRow.axis = .horizontal
        statusRow.alignment = .center
        statusRow.spacing = 8
        statusRow.translatesAutoresizingMaskIntoConstraints = false

        [headerLabel, statusRow, segmentedControl, captionLabel].forEach { card.addSubview($0) }
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            headerLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            statusDotView.widthAnchor.constraint(equalToConstant: 14),
            statusDotView.heightAnchor.constraint(equalToConstant: 14),

            statusRow.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            statusRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            statusRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            segmentedControl.topAnchor.constraint(equalTo: statusRow.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            captionLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            captionLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            captionLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    private func updateStatusDisplay() {
        statusDotView.backgroundColor = currentStatus.color
        statusLabel.text = "You're currently \(currentStatus.displayText)"
    }

    @objc private func statusChanged(_ sender: UISegmentedControl) {
        currentStatus = AvailabilityStatus.allCases[sender.selectedSegmentIndex]
        persistStatus()
    }

    private func persistStatus() {
        guard let professor else { return }
        professor.status = currentStatus
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    @objc private func logoutTapped() {
        dismiss(animated: true)
    }
}
