import UIKit
import FirebaseAuth

class VerifyCodeViewController: UIViewController {

    @IBOutlet weak var txtCode: UITextField!
    @IBOutlet weak var btnVerify: UIButton!

    // Podemos opcionalmente pasar el número de teléfono desde LoginViewController
    var phoneNumber: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Verificar Código"
        view.backgroundColor = .white
    }

    @IBAction func verifyPressed(_ sender: Any) {
        guard let code = txtCode.text, !code.isEmpty else {
            showAlert(title: "Código vacío", message: "Ingresa el código recibido")
            return
        }

        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            showAlert(title: "Error", message: "No se encontró el ID de verificación")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }

                // Login exitoso → navegar a tu LoginAccessViewController
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let accessVC = storyboard.instantiateViewController(withIdentifier: "LoginAccessVC") as? LoginAccessViewController {
                    self?.navigationController?.pushViewController(accessVC, animated: true)
                }
            }
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
