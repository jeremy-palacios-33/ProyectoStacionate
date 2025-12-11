import UIKit
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

class LoginAccessViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate , UIGestureRecognizerDelegate,
    UISearchBarDelegate, UITableViewDelegate,
    UITableViewDataSource{
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var barraBusqueda: UISearchBar!
    @IBOutlet weak var centerButtom: UIButton!
    
    @IBOutlet weak var resultsTable: UITableView!
    
    let completer = MKLocalSearchCompleter()
    var searchResults: [MKLocalSearchCompletion] = []
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
        barraBusqueda.delegate = self
        resultsTable.delegate = self
        resultsTable.dataSource = self
        resultsTable.isHidden = true
        completer.delegate = self
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -12.0464, longitude: -77.0428),
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        )
        listenPoints()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults.removeAll()
            resultsTable.isHidden = true
            resultsTable.reloadData()
            return
        }

        completer.queryFragment = searchText
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let query = searchBar.text, !query.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Error en búsqueda: \(error.localizedDescription)")
                return
            }

            guard let response = response, let item = response.mapItems.first else {
                print("No se encontraron resultados")
                return
            }

            let coordinate = item.placemark.coordinate

            // Centramos el mapa en el resultado
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 800,
                longitudinalMeters: 800
            )
            self.mapView.setRegion(region, animated: true)

            // Agregar un pin temporal opcional
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = item.name ?? "Resultado"
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
                   UITableViewCell(style: .subtitle, reuseIdentifier: "cell")

        let result = searchResults[indexPath.row]
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle

        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let completion = searchResults[indexPath.row]

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            if let item = response?.mapItems.first {
                let coord = item.placemark.coordinate

                // Centrar mapa
                let region = MKCoordinateRegion(center: coord, latitudinalMeters: 800, longitudinalMeters: 800)
                self.mapView.setRegion(region, animated: true)

                // Limpia resultados y oculta tabla
                self.resultsTable.isHidden = true
                self.barraBusqueda.resignFirstResponder()

                // Pin temporal (si quieres)
                let ann = MKPointAnnotation()
                ann.coordinate = coord
                ann.title = item.name
                self.mapView.addAnnotation(ann)
            }
        }
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resultsTable.isHidden = true
        searchResults.removeAll()
        resultsTable.reloadData()
    }


}
extension LoginAccessViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
        self.resultsTable.isHidden = searchResults.isEmpty
        self.resultsTable.reloadData()
    }
}
