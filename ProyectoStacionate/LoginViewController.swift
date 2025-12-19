import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var loginSegmented: UISegmentedControl!
    @IBOutlet weak var txtLogin: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnNewUser: UIButton!

    // MARK: - Properties
    var selectedOption = "Correo Electrónico"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI
    func setupUI() {
        loginSegmented.selectedSegmentIndex = 1
        txtPassword.isSecureTextEntry = true
    }

    // MARK: - Segmented
    @IBAction func loginTypeChanged(_ sender: UISegmentedControl) {
        selectedOption = sender.selectedSegmentIndex == 0
            ? "Número Telefónico"
            : "Correo Electrónico"

        txtLogin.text = ""
        txtPassword.text = ""
        txtPassword.isHidden = selectedOption == "Número Telefónico"
    }

    // MARK: - Login
    @IBAction func loginPressed(_ sender: UIButton) {

        let email = txtLogin.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = txtPassword.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard selectedOption == "Correo Electrónico" else {
            showAlert(title: "Aviso", message: "Login por teléfono no implementado")
            return
        }

        guard isValidEmail(email) else {
            showAlert(title: "Correo inválido", message: "Ingresa un correo válido")
            return
        }

        guard !password.isEmpty else {
            showAlert(title: "Contraseña vacía", message: "Ingresa tu contraseña")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error login:", error.localizedDescription)
                self.showAlert(title: "Error", message: "Correo o contraseña incorrectos")
                return
            }

            // 🔐 Validación FINAL
            guard Auth.auth().currentUser != nil else {
                self.showAlert(title: "Error", message: "No hay usuario autenticado")
                return
            }

            print("✅ Login correcto")

            self.goToPanel()
        }
    }

    // MARK: - Navegación
    func goToPanel() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let panelVC = storyboard.instantiateViewController(
            withIdentifier: "LoginAccessViewController"
        ) as! LoginAccessViewController

        panelVC.modalPresentationStyle = .fullScreen
        present(panelVC, animated: true)
    }

    // MARK: - Helpers
    func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Registro
    @IBAction func newUserPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let registerVC = storyboard.instantiateViewController(
            withIdentifier: "RegisterViewController"
        )
        present(registerVC, animated: true)
    }
}
