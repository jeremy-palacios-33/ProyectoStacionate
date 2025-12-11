import UIKit

class VerifyCodeViewController: UIViewController {

    @IBOutlet weak var txtCode: UITextField!
    var phoneNumber: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Verifica tu número"
    }

    @IBAction func verifyPressed(_ sender: Any) {
        let codeEntered = txtCode.text ?? ""
        let savedCode = UserDefaults.standard.string(forKey: "fakeVerificationCode") ?? ""

        if codeEntered == savedCode {

            let alert = UIAlertController(
                            title: "Éxito",
                            message: "Número \(phoneNumber ?? "") verificado correctamente.",
                            preferredStyle: .alert
                        )
            alert.addAction(UIAlertAction(title: "Continuar", style: .default) { _ in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let accessVC = storyboard.instantiateViewController(withIdentifier: "LoginAccessVC") as? LoginAccessViewController {
                    accessVC.modalPresentationStyle = .fullScreen  // importante
                    self.present(accessVC, animated: true)
                }
            })

                        present(alert, animated: true)

        } else {
            let alert = UIAlertController(
                title: "Código incorrecto",
                message: "Intenta nuevamente.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
