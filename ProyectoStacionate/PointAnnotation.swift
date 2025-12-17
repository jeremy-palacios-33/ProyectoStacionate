
import MapKit
import Foundation
import FirebaseFirestore

struct Comment {
    var id: String
    var userId: String
    var userName: String
    var text: String
    var timestamp: Timestamp?
}

class PointAnnotation: MKPointAnnotation {
    var documentID: String = ""
    var ownerID: String = ""
    var comments: [Comment] = []
}
