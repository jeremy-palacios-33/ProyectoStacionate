import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var logoImageView: UIImageView!
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
    private func setupUI() {

        view.backgroundColor = .systemBackground

        logoImageView.image = UIImage(named: "stacionate_logo")
        logoImageView.contentMode = .scaleAspectFit

        loginSegmented.selectedSegmentIndex = 1
        txtPassword.isSecureTextEntry = true

        btnLogin.setTitle("👤 Continuar", for: .normal)
        btnNewUser.setTitle("📝 Crear cuenta", for: .normal)

        btnLogin.layer.cornerRadius = 10
        btnNewUser.layer.cornerRadius = 10
    }

    // MARK: - Segmented
    @IBAction func loginTypeChanged(_ sender: UISegmentedControl) {
        selectedOption = sender.selectedSegmentIndex == 0
            ? "Número Telefónico"
            : "Correo Electrónico"

        txtLogin.text = ""
        txtPassword.text = ""

        if selectedOption == "Número Telefónico" {
            txtLogin.placeholder = "Ingresa tu número telefónico"
            txtPassword.isHidden = true
        } else {
            txtLogin.placeholder = "Ingresa tu correo electrónico"
            txtPassword.isHidden = false
        }
    }


    // MARK: - Login
    @IBAction func loginPressed(_ sender: UIButton) {

        let loginText = txtLogin.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = txtPassword.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if selectedOption == "Número Telefónico" {
            handleFakePhoneLogin(phone: loginText)
            return
        }

        guard isValidEmail(loginText) else {
            showAlert("📧 Correo inválido", "Ingresa un correo válido")
            return
        }

        guard !password.isEmpty else {
            showAlert("🔒 Contraseña vacía", "Ingresa tu contraseña")
            return
        }

        Auth.auth().signIn(withEmail: loginText, password: password) { [weak self] _, error in
            guard let self = self else { return }

            if error != nil {
                self.showAlert("❌ Error", "Correo o contraseña incorrectos")
                return
            }

            self.showSuccessAndGoPanel()
        }
    }

    // MARK: - Fake Phone Login
    private func handleFakePhoneLogin(phone: String) {

        guard phone == "985680767" else {
            showAlert("❌ Número inválido", "Ingrese un número registrado")
            return
        }

        UserDefaults.standard.set("123456", forKey: "fakeVerificationCode")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let verifyVC = storyboard.instantiateViewController(
            withIdentifier: "VerifyCodeViewController"
        ) as! VerifyCodeViewController

        verifyVC.phoneNumber = phone
        verifyVC.modalPresentationStyle = .fullScreen
        present(verifyVC, animated: true)
    }

    // MARK: - Navegación
    private func showSuccessAndGoPanel() {
        let alert = UIAlertController(
            title: "Bienvenido 🎉",
            message: "Inicio de sesión exitoso",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Continuar 👤", style: .default) { _ in
            self.goToPanel()
        })

        present(alert, animated: true)
    }

    private func goToPanel() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let panelVC = storyboard.instantiateViewController(
            withIdentifier: "LoginAccessViewController"
        ) as! LoginAccessViewController

        panelVC.modalPresentationStyle = .fullScreen
        present(panelVC, animated: true)
    }

    // MARK: - Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    private func showAlert(_ title: String, _ message: String) {
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
        registerVC.modalPresentationStyle = .fullScreen
        present(registerVC, animated: true)
    }
}
