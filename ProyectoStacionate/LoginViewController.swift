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
    var selectedOption = "Número Telefónico"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Iniciar Sesión"
        setupUI()
        updateLoginPlaceholder()
        
        // Contraseña oculta
        txtPassword.isSecureTextEntry = true
    }

    // MARK: - UI Setup
    func setupUI() {
        loginSegmented.selectedSegmentIndex = 0
        styleTextField(txtLogin)
        styleTextField(txtPassword)

        btnLogin.layer.cornerRadius = 12
        btnLogin.setTitle("Continuar", for: .normal)
        btnNewUser.setTitle("Crear cuenta", for: .normal)
    }

    func styleTextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.backgroundColor = .systemBackground
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftView = padding
        textField.leftViewMode = .always
    }

    // MARK: - Segmented Control
    @IBAction func loginTypeChanged(_ sender: UISegmentedControl) {
        selectedOption = sender.selectedSegmentIndex == 0
            ? "Número Telefónico"
            : "Correo Electrónico"
        updateLoginPlaceholder()
    }

    func updateLoginPlaceholder() {
        txtLogin.text = ""

        UIView.animate(withDuration: 0.25) {
            if self.selectedOption == "Número Telefónico" {
                self.txtLogin.placeholder = "Número telefónico (9 dígitos)"
                self.txtLogin.keyboardType = .numberPad
                self.txtPassword.alpha = 0
            } else {
                self.txtLogin.placeholder = "Correo electrónico"
                self.txtLogin.keyboardType = .emailAddress
                self.txtPassword.alpha = 1
            }
            self.view.layoutIfNeeded()
        }

        txtPassword.isHidden = selectedOption == "Número Telefónico"
    }

    // MARK: - Login
    @IBAction func loginPressed(_ sender: UIButton) {
        let identifier = txtLogin.text ?? ""
        let password = txtPassword.text ?? ""

        if selectedOption == "Número Telefónico" {
            loginWithPhone(identifier)
        } else {
            loginWithEmail(identifier, password)
        }
    }

    func loginWithPhone(_ phone: String) {
        // Para pruebas con código fake
        guard phone.count == 9, phone.allSatisfy({ $0.isNumber }) else {
            showAlert(title: "Número inválido", message: "Debe tener 9 dígitos")
            return
        }

        UserDefaults.standard.set("123456", forKey: "fakeVerificationCode")
        UserDefaults.standard.set(phone, forKey: "fakePhoneNumber")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let verifyVC = storyboard.instantiateViewController(withIdentifier: "VerifyCodeViewController") as? VerifyCodeViewController {
            verifyVC.phoneNumber = "+51" + phone
            present(verifyVC, animated: true)
        }
    }

    func loginWithEmail(_ email: String, _ password: String) {
        guard isValidEmail(email) else {
            showAlert(title: "Correo inválido", message: "Formato incorrecto")
            return
        }

        guard !password.isEmpty else {
            showAlert(title: "Contraseña vacía", message: "Ingresa tu contraseña")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }

                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let accessVC = storyboard.instantiateViewController(withIdentifier: "LoginAccessVC") as? LoginAccessViewController {
                    accessVC.modalPresentationStyle = .fullScreen
                    self.present(accessVC, animated: true)
                }
            }
        }
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

    // MARK: - Ir a crear cuenta
    @IBAction func newUserPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController {
            self.present(registerVC, animated: true)
        }
    }
}
