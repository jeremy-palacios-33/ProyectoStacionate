import UIKit
import FirebaseFirestore


class CommentsViewController: UIViewController , UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var pointId: String!
        var pointTitle: String!
        var pointDescription: String!

        var comments: [Comment] = []
        let db = Firestore.firestore()

    
    override func viewDidLoad() {
            super.viewDidLoad()

            titleLabel.text = pointTitle
            descriptionLabel.text = pointDescription

            tableView.delegate = self
            tableView.dataSource = self

            loadComments()
        }
    
    
    func loadComments() {
        db.collection("points")
            .document(pointId)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, _ in

                self.comments = snapshot?.documents.map { d in
                    let data = d.data()
                    return Comment(
                        id: d.documentID,
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "Anon",
                        text: data["text"] as? String ?? "",
                        timestamp: data["timestamp"] as? Timestamp
                    )
                } ?? []

                self.tableView.reloadData()
            }
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")

        let c = comments[indexPath.row]
        cell.textLabel?.text = c.userName
        cell.detailTextLabel?.text = c.text
        cell.detailTextLabel?.numberOfLines = 0

        return cell
    }

    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
