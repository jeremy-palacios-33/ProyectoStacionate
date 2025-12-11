import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var pickerLogin: UIPickerView!
    @IBOutlet weak var txtLogin: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnNewUser: UIButton!

    let loginOptions = ["Número Telefónico", "Correo Electrónico"]
    var selectedOption = "Número Telefónico"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerLogin.delegate = self
        pickerLogin.dataSource = self
        pickerLogin.selectRow(0, inComponent: 0, animated: false)
        updateLoginPlaceholder()
        title = "Iniciar Sesión"
    }

    // MARK: - PickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return loginOptions.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { return loginOptions[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedOption = loginOptions[row]
        updateLoginPlaceholder()
    }

    func updateLoginPlaceholder() {
        txtLogin.text = ""
        if selectedOption == "Número Telefónico" {
            txtLogin.placeholder = "Ingresa tu número (9 dígitos)"
            txtLogin.keyboardType = .numberPad
            txtPassword.isHidden = true
        } else {
            txtLogin.placeholder = "Ingresa tu correo electrónico"
            txtLogin.keyboardType = .emailAddress
            txtPassword.isHidden = false
        }
    }

    // MARK: - Botón Login
    @IBAction func loginPressed(_ sender: Any) {
        let identifier = txtLogin.text ?? ""
        let password = txtPassword.text ?? ""

        if selectedOption == "Número Telefónico" {
            // Validar número telefónico
            if !identifier.allSatisfy({ $0.isNumber }) || identifier.count != 9 {
                showAlert(title: "Número inválido", message: "Debe tener 9 dígitos")
                return
            }

            // Código falso para prueba
            let fakeCode = "123456"
            UserDefaults.standard.set(fakeCode, forKey: "fakeVerificationCode")
            UserDefaults.standard.set(identifier, forKey: "fakePhoneNumber")

            // Navegar al controlador de verificación
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let verifyVC = storyboard.instantiateViewController(withIdentifier: "VerifyCodeViewController") as? VerifyCodeViewController {
                verifyVC.phoneNumber = "+51" + identifier
                self.present(verifyVC, animated: true)
            }

        } else {
            // LOGIN CON CORREO (Firebase)
            if !isValidEmail(identifier) {
                showAlert(title: "Correo inválido", message: "Formato incorrecto")
                return
            }
            if password.isEmpty {
                showAlert(title: "Contraseña vacía", message: "Ingresa tu contraseña")
                return
            }

            Auth.auth().signIn(withEmail: identifier, password: password) { [weak self] authResult, error in
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
    }

    // MARK: - Validación de correo
    func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    // MARK: - Alertas
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
