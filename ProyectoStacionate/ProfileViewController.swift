//
//  ProfileViewController.swift
//  ProyectoStacionate
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var registeredLabel: UILabel!

    @IBOutlet weak var backProfileButton: UIButton!
    @IBOutlet weak var updateProfileButton: UIButton!
    @IBOutlet weak var updatePassButton: UIButton!

    // MARK: - Variables
    private let db = Firestore.firestore()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkSession()
        loadUserData()
    }

    // MARK: - Setup UI
    private func setupUI() {
        // Imagen de perfil
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.clipsToBounds = true
        userImageView.image = UIImage(systemName: "person.circle.fill")
        userImageView.tintColor = .systemGray

        // Botones
        [updateProfileButton, updatePassButton].forEach {
            $0?.layer.cornerRadius = 10
        }
    }

    // MARK: - Session
    private func checkSession() {
        guard Auth.auth().currentUser != nil else {
            goToLogin()
            return
        }
    }

    // MARK: - Load User Data
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }

        // Email (Auth)
        emailLabel.text = user.email ?? "-"

        // Firestore data
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("⚠️ No se encontraron datos en Firestore")
                self.userNameLabel.text = "Usuario"
                self.phoneLabel.text = "-"
                self.registeredLabel.text = "-"
                return
            }

            let name = data["name"] as? String ?? "Usuario"
            let phone = data["phone"] as? String ?? "-"
            let createdAt = data["createdAt"] as? Timestamp

            DispatchQueue.main.async {
                self.userNameLabel.text = name
                self.phoneLabel.text = phone

                if let createdAt = createdAt {
                    let date = createdAt.dateValue()
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.locale = Locale(identifier: "es_PE")
                    self.registeredLabel.text = formatter.string(from: date)
                } else {
                    self.registeredLabel.text = "-"
                }
            }
        }
    }

    // MARK: - Navigation
    private func goToLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(
            withIdentifier: "LoginViewController"
        )
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }

    // MARK: - Actions
    @IBAction func backProfileButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func updateProfileButtonTapped(_ sender: UIButton) {
        print("✏️ Editar perfil")
        // Aquí luego puedes abrir EditProfileViewController
    }

    @IBAction func updatePassTapped(_ sender: UIButton) {
        print("🔐 Cambiar contraseña")

        guard let email = Auth.auth().currentUser?.email else { return }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("❌ Error:", error.localizedDescription)
            } else {
                print("✅ Correo de recuperación enviado")
            }
        }
    }
}
