import UIKit
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

class LoginAccessViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate , UIGestureRecognizerDelegate{
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var centerButtom: UIButton!
    let locationManager = CLLocationManager()
    let db = Firestore.firestore()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
       
        locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()

            mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        mapView.delegate = self
        longPress.delegate = self
        listenPoints()
    }
    
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }

    @IBAction func centerMapButtonTapped(_ sender: UIButton) {
        mapView.setUserTrackingMode(.follow, animated: true)
    }
    
    @IBAction func tiltMapButtonTapped(_ sender: UIButton) {
        let camera = MKMapCamera(
                lookingAtCenter: mapView.centerCoordinate,
                fromDistance: 500,
                pitch: 60,
                heading: 0
            )
            mapView.setCamera(camera, animated: true)
    }
    
    func listenPoints() {
        db.collection("points").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening points: \(error)")
                return
            }

            guard let docs = snapshot?.documents else { return }

            let anns = self.mapView.annotations.filter { !($0 is MKUserLocation) }
            self.mapView.removeAnnotations(anns)

            for doc in docs {
                let data = doc.data()
                let lat = data["lat"] as? Double ?? 0
                let lon = data["lon"] as? Double ?? 0
                let title = data["title"] as? String ?? "Sin título"
                let desc = data["description"] as? String ?? ""
                let userId = data["userId"] as? String ?? ""
                let docID = doc.documentID

                let annotation = PointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.title = title
                annotation.subtitle = desc
                annotation.documentID = docID
                annotation.ownerID = userId

                self.mapView.addAnnotation(annotation)
            }
        }
    }



    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .began { return }

            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)

            
            let alert = UIAlertController(title: "Nuevo punto", message: nil, preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Título" }
            alert.addTextField { $0.placeholder = "Descripción" }

            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
            alert.addAction(UIAlertAction(title: "Guardar", style: .default, handler: { _ in
                
                let title = alert.textFields?[0].text ?? "Sin título"
                let desc = alert.textFields?[1].text ?? ""

                self.db.collection("points").addDocument(data: [
                    "title": title,
                    "description": desc,
                    "lat": coord.latitude,
                    "lon": coord.longitude,
                    "timestamp": FieldValue.serverTimestamp(),
                    "userId": Auth.auth().currentUser?.uid ?? "unknown",
                ])
            }))
            present(alert, animated: true)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)

        guard let annotation = view.annotation as? PointAnnotation else { return }

        let currentUserId = Auth.auth().currentUser?.uid ?? ""

        let alert = UIAlertController(title: annotation.title ?? "",
                                      message: annotation.subtitle ?? "",
                                      preferredStyle: .actionSheet)

        if annotation.ownerID == currentUserId {
            alert.addAction(UIAlertAction(title: "Eliminar punto", style: .destructive, handler: { _ in
                self.deletePoint(documentID: annotation.documentID)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cerrar", style: .cancel))

        present(alert, animated: true)
    }

    
    
    func deletePoint(documentID: String) {
        db.collection("points").document(documentID).delete { error in
            if let error = error {
                print("Error deleting point: \(error)")
                return
            }
            print("Punto eliminado")
        }
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
