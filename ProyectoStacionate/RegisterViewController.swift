import UIKit
import FirebaseAuth
import FirebaseFirestore

class RegisterViewController: UIViewController {

    @IBOutlet weak var NameTextField: UITextField!
    @IBOutlet weak var LastNameTextField: UITextField!
    @IBOutlet weak var PhoneTextField: UITextField!
    @IBOutlet weak var EmailTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!
    @IBOutlet weak var PasswordConfirmed: UITextField!
    @IBOutlet weak var RegisterButton: UIButton!
    @IBOutlet weak var ReturnButton: UIButton!

    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Crear Cuenta
    @IBAction func RegisterButtonTapped(_ sender: UIButton) {

        // 1. Leer valores
        guard let name = NameTextField.text, !name.isEmpty,
              let lastName = LastNameTextField.text, !lastName.isEmpty,
              let phone = PhoneTextField.text, !phone.isEmpty,
              let email = EmailTextField.text, !email.isEmpty,
              let password = PasswordTextField.text, !password.isEmpty,
              let confirmPassword = PasswordConfirmed.text, !confirmPassword.isEmpty else {

            showAlert(title: "Campos vacíos", message: "Completa todos los campos.")
            return
        }

        // 2. Validaciones
        if !isValidEmail(email) {
            showAlert(title: "Correo inválido", message: "Ingresa un correo válido.")
            return
        }

        if password != confirmPassword {
            showAlert(title: "Contraseña incorrecta", message: "Las contraseñas no coinciden.")
            return
        }

        if phone.count != 9 || !phone.allSatisfy({ $0.isNumber }) {
            showAlert(title: "Número inválido", message: "Debe tener 9 dígitos.")
            return
        }

        // 3. Crear usuario en Firebase
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }

            guard let uid = result?.user.uid else { return }

            // 4. Guardar datos adicionales en Firestore
            let userData: [String: Any] = [
                "uid": uid,
                "name": name,
                "lastName": lastName,
                "phone": phone,
                "email": email,
                "createdAt": Timestamp()
            ]

            self.db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: "No se pudo guardar datos: \(error.localizedDescription)")
                    return
                }

                self.showAlert(title: "Cuenta creada", message: "Tu cuenta fue registrada correctamente.") { _ in
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                        loginVC.modalPresentationStyle = .fullScreen
                        self.present(loginVC, animated: true)
                    }
                }

            }
        }
    }

    // MARK: - Botón volver
    @IBAction func ReturnButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }

    // MARK: - Validar correo
    func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    // MARK: - Alertas
    func showAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
        present(alert, animated: true)
    }
}
