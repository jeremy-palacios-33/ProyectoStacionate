import UIKit

class VerifyCodeViewController: UIViewController {

    @IBOutlet weak var txtCode: UITextField!
    @IBOutlet weak var verifyButton: UIButton!

    var phoneNumber: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Verificar número 📱"
        txtCode.keyboardType = .numberPad
        verifyButton.layer.cornerRadius = 10
    }

    @IBAction func verifyPressed(_ sender: UIButton) {
        let codeEntered = txtCode.text ?? ""
        let savedCode = UserDefaults.standard.string(forKey: "fakeVerificationCode") ?? ""

        guard codeEntered == savedCode else {
            showAlert("❌ Código incorrecto", "Intenta nuevamente")
            return
        }

        UserDefaults.standard.set(true, forKey: "fakeLogin")

        let alert = UIAlertController(
            title: "✅ Éxito",
            message: "Número \(phoneNumber ?? "") verificado correctamente",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Continuar 🚗", style: .default) { _ in
            self.goToPanel()
        })

        present(alert, animated: true)
    }


    private func goToPanel() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let accessVC = storyboard.instantiateViewController(
            withIdentifier: "LoginAccessViewController"
        ) as! LoginAccessViewController

        accessVC.modalPresentationStyle = .fullScreen
        present(accessVC, animated: true)
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
