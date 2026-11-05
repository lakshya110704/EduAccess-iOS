//
//  StudentDashboardViewController.swift
//  EduAccess
//
//  Created by Lakshya Mehta on 14/10/25.
//
import UIKit
import CoreData

final class StudentDashboardViewController: UITableViewController {

    private var professors: [Professor] = []

    private var context: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Professors"

        // If you used a prototype cell in storyboard with identifier "ProfessorCell" and style Subtitle,
        // no need to register. If using programmatic cell, uncomment the line below:
        // tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfessorCell")

        tableView.tableFooterView = UIView() // removes empty separators
        loadProfessors()
    }

    private func loadProfessors() {
        let request: NSFetchRequest<Professor> = Professor.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        professors = (try? context.fetch(request)) ?? []
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        professors.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // make sure storyboard cell identifier is "ProfessorCell" and style is Subtitle
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfessorCell", for: indexPath)

        let prof = professors[indexPath.row]
        cell.textLabel?.text = prof.name
        cell.detailTextLabel?.text = "\(prof.department ?? "") • \(prof.status.displayText) • \(prof.availability ?? "")"
        cell.imageView?.image = prof.status.indicatorImage
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let prof = professors[indexPath.row]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let bookingVC = storyboard.instantiateViewController(withIdentifier: "BookingVC") as? BookingViewController else {
            print("⚠️ BookingVC not found or wrong class in storyboard (check Storyboard ID and Module)")
            return
        }
        bookingVC.selectedProfessor = prof
        navigationController?.pushViewController(bookingVC, animated: true)
    }}
