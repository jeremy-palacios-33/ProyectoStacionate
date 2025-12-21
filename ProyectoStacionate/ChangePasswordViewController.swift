import UIKit
import FirebaseAuth

class ChangePasswordViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var backButton: UIButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserEmail()
    }

    // MARK: - Setup UI
    private func setupUI() {
        // Email (solo lectura)
        emailTextField.text = Auth.auth().currentUser?.email
        emailTextField.isUserInteractionEnabled = false
        emailTextField.textColor = .secondaryLabel
        emailTextField.backgroundColor = UIColor.systemGray6
        emailTextField.layer.cornerRadius = 8
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor.systemGray4.cgColor


        // Passwords
        newPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true

        // Botones
        [saveButton, backButton].forEach {
            $0?.layer.cornerRadius = 10
        }
    }

    // MARK: - Load Email
    private func loadUserEmail() {
        emailTextField.text = Auth.auth().currentUser?.email
    }

    // MARK: - Actions
    @IBAction func saveTapped(_ sender: UIButton) {
        guard let newPassword = newPasswordTextField.text,
              let confirmPassword = confirmPasswordTextField.text,
              !newPassword.isEmpty,
              !confirmPassword.isEmpty else {
            showAlert("Campos incompletos", "Completa todos los campos")
            return
        }

        guard newPassword == confirmPassword else {
            showAlert("Error", "Las contraseñas no coinciden")
            return
        }

        guard newPassword.count >= 6 else {
            showAlert("Contraseña débil", "Debe tener al menos 6 caracteres")
            return
        }

        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                self.showAlert("Error", error.localizedDescription)
            } else {
                self.showAlert("Éxito", "Contraseña actualizada correctamente") {
                    self.dismiss(animated: true)
                }
            }
        }
    }

    @IBAction func backTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    // MARK: - Alert Helper
    private func showAlert(_ title: String,
                           _ message: String,
                           completion: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
