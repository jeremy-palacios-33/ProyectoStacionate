import UIKit

class AboutUsViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var appNameDescriptionLabel: UILabel!

    @IBOutlet weak var appPurposeLabel: UILabel!
    @IBOutlet weak var appPurposeDescriptionLabel: UILabel!

    @IBOutlet weak var appDevelopedLabel: UILabel!
    @IBOutlet weak var appDevelopedOneLabel: UILabel!
    @IBOutlet weak var appDevelopedTwoLabel: UILabel!
    @IBOutlet weak var appDevelopedThreeLabel: UILabel!

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        loadContent()
    }

    // MARK: - UI Configuration

    private func configureUI() {

        view.backgroundColor = .systemBackground

        appNameLabel.font = .boldSystemFont(ofSize: 18)
        appPurposeLabel.font = .boldSystemFont(ofSize: 18)
        appDevelopedLabel.font = .boldSystemFont(ofSize: 18)

        appNameDescriptionLabel.numberOfLines = 0
        appPurposeDescriptionLabel.numberOfLines = 0

        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true

        backButton.layer.cornerRadius = 10
    }

    // MARK: - Load Content

    private func loadContent() {

        if let image = UIImage(named: "stacionate_logo") {
            imageView.image = image
        } else {
            print("❌ Imagen stacionate_logo no encontrada en Assets")
        }

        appNameLabel.text = "📌 ¿Qué es Stacionate?"
        appNameDescriptionLabel.text =
        "Stacionate conecta a conductores con espacios disponibles para estacionar, permitiendo que los usuarios compartan información útil y actualizada para facilitar una experiencia de estacionamiento más rápida, eficiente y colaborativa."

        appPurposeLabel.text = "🎯 Finalidad de la Aplicación"
        appPurposeDescriptionLabel.text =
        "La finalidad de Stacionate es reducir el tiempo y la frustración que enfrentan los conductores al buscar estacionamiento, fomentando una comunidad donde los usuarios colaboran activamente compartiendo información confiable para beneficio de todos."

        appDevelopedLabel.text = "👨‍💻 Desarrollado por"
        appDevelopedOneLabel.text = "• Jeremy Palacios"
        appDevelopedTwoLabel.text = "• Marchelo Cortabrazos"
        appDevelopedThreeLabel.text = "• Jhenny Rumay"

        versionLabel.text = "🛠️ Versión 1.0.0"
    }

    // MARK: - Actions

    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }


}
