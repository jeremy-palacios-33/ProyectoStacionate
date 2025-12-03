import UIKit

class LoginViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var pickerLogin: UIPickerView!
    @IBOutlet weak var lblLogin: UITextField!
    @IBOutlet weak var lblPassword: UITextField!
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
        
        // Título de esta pantalla
        title = "Iniciar Sesión"
        
        // Texto que aparecerá en el botón atrás en la próxima pantalla
        let backItem = UIBarButtonItem()
        backItem.title = "Atrás"
        navigationItem.backBarButtonItem = backItem
    }

    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return loginOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return loginOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                    inComponent component: Int) {
        selectedOption = loginOptions[row]
        updateLoginPlaceholder()
    }

    // MARK: - Placeholder dinámico
    func updateLoginPlaceholder() {
        if selectedOption == "Número Telefónico" {
            lblLogin.keyboardType = .numberPad
            lblLogin.placeholder = "Ingresa tu número telefónico (9 dígitos)"
        } else {
            lblLogin.keyboardType = .emailAddress
            lblLogin.placeholder = "Ingresa tu correo electrónico"
        }
        lblLogin.text = ""
    }

    // MARK: - Validaciones
    func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    // MARK: - Botón Ingresar
    @IBAction func loginPressed(_ sender: Any) {

        let identifier = lblLogin.text ?? ""
        let password = lblPassword.text ?? ""

        // Validación según picker
        if selectedOption == "Número Telefónico" {
            if !identifier.allSatisfy({ $0.isNumber }) || identifier.count != 9 {
                showAlert(title: "Número inválido", message: "Debe tener 9 dígitos")
                return
            }
        } else {
            if !isValidEmail(identifier) {
                showAlert(title: "Correo inválido", message: "Formato incorrecto")
                return
            }
        }

        if password.isEmpty {
            showAlert(title: "Contraseña vacía", message: "Ingresa tu contraseña")
            return
        }

    }

    // MARK: - Alertas
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
