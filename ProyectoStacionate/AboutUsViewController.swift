import UIKit

class AboutUsViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var purposeTextView: UITextView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadContent()
    }

    private func setupUI() {
        titleLabel.text = "About Us"
        titleLabel.font = .boldSystemFont(ofSize: 22)

        appNameLabel.text = "Stacionate"
        appNameLabel.font = .boldSystemFont(ofSize: 18)

        configureTextView(descriptionTextView)
        configureTextView(purposeTextView)

        backButton.layer.cornerRadius = 8
    }

    private func configureTextView(_ textView: UITextView) {
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textAlignment = .justified
        textView.font = .systemFont(ofSize: 15)
    }

    private func loadContent() {
        descriptionTextView.text =
        """
        Stacionate is a mobile application designed to help drivers find available parking spaces quickly and easily. The platform allows users to share real-time parking information, creating a collaborative and reliable community.
        """

        purposeTextView.text =
        """
        The main purpose of Stacionate is to reduce the time and frustration drivers experience when searching for parking. By encouraging users to provide feedback and updates, the app improves urban mobility and benefits the entire community.
        """

        versionLabel.text = "Version 1.0.0"
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
        // o navigationController?.popViewController(animated: true)
    }
}
