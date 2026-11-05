import UIKit

final class LoginViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!

    @IBOutlet weak var cardCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var roleSwitch: UISwitch!            // ✅ New outlet
    @IBOutlet weak var studentLabel: UILabel!           // ✅ Label before the switch
    @IBOutlet weak var professorLabel: UILabel!         // ✅ Label after the switch

    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        addLeftIconsToFields()
        setupKeyboardNotifications()
        setupKeyboardDismissal()
        usernameField.textColor = .black
        passwordField.textColor = .black
        usernameField.tintColor = .black   // cursor color
        passwordField.tintColor = .black
        usernameField.attributedPlaceholder = NSAttributedString(string: "Username", attributes: [.foregroundColor: UIColor(white: 0.6, alpha: 1)])
        passwordField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [.foregroundColor: UIColor(white: 0.6, alpha: 1)])
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateCardEntrance()
    }
    
    
    
    private func animateCardEntrance() {
        // Start with card hidden and slightly below center
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(translationX: 0, y: 50)
        
        UIView.animate(
            withDuration: 0.6,
            delay: 0.1,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut],
            animations: {
                self.cardView.alpha = 1
                self.cardView.transform = .identity
            }
        )
    }

    private func configureUI() {
        [usernameField, passwordField].forEach { tf in
            tf?.textColor = .white
            tf?.backgroundColor = UIColor(white: 1, alpha: 0.06)
            tf?.layer.cornerRadius = 8
            tf?.borderStyle = .none
        }

        passwordField.isSecureTextEntry = true

        loginButton.layer.cornerRadius = 10
//        loginButton.backgroundColor = UIColor(red: 47/255, green: 191/255, blue: 154/255, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)

        // Optional: set switch tint colors
        roleSwitch.onTintColor = UIColor(red: 47/255, green: 191/255, blue: 154/255, alpha: 1.0)
        roleSwitch.thumbTintColor = .white
    }
    
    private func addLeftIconsToFields() {
        func makeLeftView(systemName: String) -> UIView {
            let iv = UIImageView(image: UIImage(systemName: systemName))
            iv.contentMode = .scaleAspectFit
            iv.tintColor = UIColor(white: 0.25, alpha: 1.0)
            iv.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            iv.center = CGPoint(x: container.bounds.midX, y: container.bounds.midY)
            container.addSubview(iv)
            return container
        }

        if usernameField?.leftView == nil {
            usernameField.leftView = makeLeftView(systemName: "person.fill")
            usernameField.leftViewMode = .always
        }
        if passwordField?.leftView == nil {
            passwordField.leftView = makeLeftView(systemName: "lock.fill")
            passwordField.leftViewMode = .always
        }

        // ensure corner radius and clipping for visual polish
        [usernameField, passwordField].forEach { tf in
            tf?.layer.cornerRadius = 10
            tf?.clipsToBounds = true
            tf?.borderStyle = .none
        }
    }

    // MARK: - Actions
    @IBAction func roleSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            print("Professor selected")
        } else {
            print("Student selected")
        }
    }

    @IBAction func loginTapped(_ sender: Any) {
        view.endEditing(true)

        // Trimmed username/password
        let username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Validate: both fields must be non-empty
        guard !username.isEmpty, !password.isEmpty else {
            let alert = UIAlertController(
                title: "Missing Information",
                message: "Please enter both username and password before logging in.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Determine role from switch
        let isProfessor = roleSwitch?.isOn ?? false

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let storyboardID = isProfessor ? "ProfessorNav" : "StudentNav"

        guard let nav = sb.instantiateViewController(withIdentifier: storyboardID) as? UINavigationController else {
            let alert = UIAlertController(title: "Error", message: "Navigation controller not found.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Present chosen flow
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        // Move card up by a fraction of keyboard height
        UIView.animate(withDuration: animationDuration) {
            self.cardCenterYConstraint.constant = -keyboardFrame.height / 3
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        UIView.animate(withDuration: animationDuration) {
            self.cardCenterYConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // allows buttons to still work
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
}
