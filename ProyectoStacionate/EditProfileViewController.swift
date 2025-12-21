//
//  EditProfileViewController.swift
//  ProyectoStacionate
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class EditProfileViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var userImageView: UIImageView!

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    // MARK: - Variables
    var profileImage: UIImage?
    private let db = Firestore.firestore()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }

    // MARK: - Setup UI
    private func setupUI() {

        // Imagen de perfil
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.clipsToBounds = true

        if let image = profileImage {
            userImageView.image = image
        } else {
            userImageView.image = UIImage(systemName: "person.crop.circle.fill")
            userImageView.tintColor = .systemGray
        }

        // Botones
        [saveButton, cancelButton].forEach {
            $0?.layer.cornerRadius = 10
        }

        // Email SOLO LECTURA (notorio)
        emailTextField.isUserInteractionEnabled = false
        emailTextField.textColor = .secondaryLabel
        emailTextField.backgroundColor = UIColor.systemGray6
        emailTextField.layer.cornerRadius = 8
        emailTextField.layer.borderWidth = 1
        emailTextField.layer.borderColor = UIColor.systemGray4.cgColor

        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Correo electrónico",
            attributes: [.foregroundColor: UIColor.systemGray2]
        )
    }

    // MARK: - Load User Data
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }

        // Email desde Auth
        emailTextField.text = user.email

        // Firestore
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("⚠️ No se pudo cargar el perfil")
                return
            }

            DispatchQueue.main.async {
                let name = data["name"] as? String ?? ""
                let lastName = data["lastName"] as? String ?? ""
                let phone = data["phone"] as? String ?? ""

                // Nombre completo
                let fullName = "\(name) \(lastName)".trimmingCharacters(in: .whitespaces)


                // Text + Placeholder (mejor UX)
                self.nameTextField.text = fullName
                self.nameTextField.placeholder = "Nombre completo"

                self.phoneTextField.text = phone
                self.phoneTextField.placeholder = "Teléfono"

            }
        }
    }

    // MARK: - Actions
    @IBAction func saveTapped(_ sender: UIButton) {
        guard let fullName = nameTextField.text, !fullName.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty else {
            showAlert("Error", "Completa todos los campos")
            return
        }

        // Validar teléfono: solo números y 9 dígitos
        let phoneRegex = "^[0-9]{9}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        if !phoneTest.evaluate(with: phone) {
            showAlert("Error", "Ingresa un número de teléfono válido de 9 dígitos")
            return
        }

        // Validar nombre: solo letras y espacios
        let nameRegex = "^[A-Za-zÁÉÍÓÚáéíóúÑñ ]+$"
        let nameTest = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        if !nameTest.evaluate(with: fullName) {
            showAlert("Error", "El nombre solo puede contener letras y espacios")
            return
        }

        guard let user = Auth.auth().currentUser else { return }

        // Separar el nombre completo en nombre y apellido
        let nameParts = fullName.split(separator: " ")
        let firstName = nameParts.first.map(String.init) ?? ""
        let lastName = nameParts.dropFirst().joined(separator: " ")

        let data: [String: Any] = [
            "name": firstName,
            "lastName": lastName,
            "phone": phone
        ]

        db.collection("users").document(user.uid).updateData(data) { error in
            if let error = error {
                self.showAlert("Error", error.localizedDescription)
            } else {
                self.showAlert("Éxito", "Perfil actualizado correctamente") {
                    self.dismiss(animated: true)
                }
            }
        }
    }



    @IBAction func cancelTapped(_ sender: UIButton) {
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
