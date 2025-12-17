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
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        let identifier = "PointAnnotationView"

        var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView

        if view == nil {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view?.canShowCallout = true
            view?.titleVisibility = .visible
            view?.subtitleVisibility = .visible   // ✅ ESTA LÍNEA ES LA CLAVE
        } else {
            view?.annotation = annotation
        }

        return view
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
                let ratingAvg = data["ratingAvg"] as? Double ?? 0
                let ratingCount = data["ratingCount"] as? Int ?? 0

               


                let annotation = PointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.title = title
                annotation.documentID = docID
                annotation.ownerID = userId
                annotation.subtitle = "\(desc)\n⭐ \(String(format: "%.1f", ratingAvg)) (\(ratingCount))"
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
        let pointId = annotation.documentID

        // cargar comentarios
        loadComments(for: pointId) { comments in
            DispatchQueue.main.async {
                var message = ""
                for c in comments {
                    message += "\(c.userName): \(c.text)\n\n"
                }
                if message.isEmpty { message = "No hay comentarios aún." }

                let alert = UIAlertController(title: annotation.title ?? "Comentarios",
                                              message: message,
                                              preferredStyle: .actionSheet)

                // Agregar/editar comentario (usuario actual)
                alert.addAction(UIAlertAction(title: "Agregar/Editar mi comentario", style: .default, handler: { _ in
                    self.askForComment(existing: comments.first(where: { $0.userId == Auth.auth().currentUser?.uid }), pointId: pointId)
                }))

                // Si mi comentario existe, permitir eliminar
                if let myComment = comments.first(where: { $0.userId == Auth.auth().currentUser?.uid }) {
                    alert.addAction(UIAlertAction(title: "Eliminar mi comentario",
                                                 style: .destructive,
                                                 handler: { _ in

                        let confirm = UIAlertController(
                            title: "Confirmar",
                            message: "¿Seguro que deseas eliminar tu comentario?",
                            preferredStyle: .alert
                        )

                        confirm.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
                        confirm.addAction(UIAlertAction(title: "Eliminar", style: .destructive, handler: { _ in
                            self.deleteMyComment(pointId: pointId) { err in
                                if err == nil {
                                    self.showMessage(message: "Comentario eliminado")
                                }
                            }
                        }))

                        self.present(confirm, animated: true)
                    }))

                }

                alert.addAction(UIAlertAction(title: "Cerrar", style: .cancel))
                alert.addAction(UIAlertAction(title: "Calificar ⭐", style: .default, handler: { _ in
                    self.showRatingSheet(pointId: pointId)
                }))

                self.present(alert, animated: true)
            }
        }
    }

    func askForComment(existing: Comment?, pointId: String) {
        let alert = UIAlertController(title: existing == nil ? "Agregar comentario" : "Editar comentario",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Escribe tu comentario"
            tf.text = existing?.text
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default, handler: { _ in
            let text = alert.textFields?.first?.text ?? ""
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }
            self.addOrUpdateComment(pointId: pointId, text: text) { isUpdate, err in
                if let err = err {
                    print("Error guardando comentario: \(err)")
                    return
                }

                self.showMessage(
                    message: isUpdate ? "Comentario actualizado" : "Comentario agregado"
                )
            }

        }))
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
    
    func fetchCurrentUserFullName(completion: @escaping (String) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion("Usuario")
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                let name = data["name"] as? String ?? ""
                let lastName = data["lastName"] as? String ?? ""
                let fullName = "\(name) \(lastName)".trimmingCharacters(in: .whitespaces)

                completion(fullName.isEmpty ? "Usuario" : fullName)
            } else {
                completion("Usuario")
            }
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

            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 800,
                longitudinalMeters: 800
            )
            self.mapView.setRegion(region, animated: true)

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

              
                let region = MKCoordinateRegion(center: coord, latitudinalMeters: 800, longitudinalMeters: 800)
                self.mapView.setRegion(region, animated: true)

                
                self.resultsTable.isHidden = true
                self.barraBusqueda.resignFirstResponder()

               
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
    // MARK: - Comentarios: CRUD

    // Cargar comentarios (puedes usar snapshot listener para real-time)
    // Uso: loadComments(for: annotation.documentID) { comments in ... }
    func loadComments(for pointId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("points").document(pointId).collection("comments")
          .order(by: "timestamp", descending: false)
          .getDocuments { snapshot, error in
            var comments: [Comment] = []
            if let docs = snapshot?.documents {
                for d in docs {
                    let data = d.data()
                    let comment = Comment(
                        id: d.documentID,
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "Anon",
                        text: data["text"] as? String ?? "",
                        timestamp: data["timestamp"] as? Timestamp
                    )
                    comments.append(comment)
                }
            }
            completion(comments)
        }
    }

    // Añadir o actualizar comentario (document id = currentUser.uid -> garantiza uno por usuario)
    func addOrUpdateComment(pointId: String, text: String, completion: ((Bool, Error?) -> Void)? = nil) {
        guard let user = Auth.auth().currentUser else {
            completion?(false, NSError(domain: "Auth", code: 0))
            return
        }

        let commentRef = db.collection("points")
            .document(pointId)
            .collection("comments")
            .document(user.uid)

        fetchCurrentUserFullName { fullName in

            commentRef.getDocument { snap, _ in
                let isUpdate = snap?.exists == true

                let data: [String: Any] = [
                    "userId": user.uid,
                    "userName": fullName,
                    "text": text,
                    "timestamp": FieldValue.serverTimestamp()
                ]

                commentRef.setData(data) { error in
                    completion?(isUpdate, error)
                }
            }
        }
    }


    // Eliminar comentario del usuario actual
    func deleteMyComment(pointId: String, completion: ((Error?) -> Void)? = nil) {
        guard let user = Auth.auth().currentUser else {
            completion?(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user"]))
            return
        }
        db.collection("points").document(pointId)
          .collection("comments").document(user.uid)
          .delete { err in completion?(err) }
    }
    
    func showRatingSheet(pointId: String) {
        let sheet = UIAlertController(title: "Calificar lugar",
                                      message: "Selecciona una calificación",
                                      preferredStyle: .actionSheet)

        for i in 1...5 {
            sheet.addAction(UIAlertAction(title: "\(i) ⭐", style: .default, handler: { _ in
                self.saveRating(pointId: pointId, stars: i)
            }))
        }

        sheet.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(sheet, animated: true)
    }
    
    func saveRating(pointId: String, stars: Int) {
        guard let user = Auth.auth().currentUser else { return }

        let pointRef = db.collection("points").document(pointId)
        let ratingRef = pointRef.collection("ratings").document(user.uid)

        db.runTransaction({ transaction, errorPointer -> Any? in
            let pointDoc: DocumentSnapshot
            do {
                pointDoc = try transaction.getDocument(pointRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let oldAvg = pointDoc.data()?["ratingAvg"] as? Double ?? 0
            let oldCount = pointDoc.data()?["ratingCount"] as? Int ?? 0

            let ratingDoc = try? transaction.getDocument(ratingRef)

            var newAvg = oldAvg
            var newCount = oldCount

            if let oldStars = ratingDoc?.data()?["stars"] as? Int {
                // 🔁 Usuario ya calificó → reemplaza
                newAvg = ((oldAvg * Double(oldCount)) - Double(oldStars) + Double(stars)) / Double(oldCount)
            } else {
                // ➕ Nueva calificación
                newCount += 1
                newAvg = ((oldAvg * Double(oldCount)) + Double(stars)) / Double(newCount)
            }

            transaction.setData([
                "stars": stars,
                "timestamp": FieldValue.serverTimestamp()
            ], forDocument: ratingRef)

            transaction.updateData([
                "ratingAvg": newAvg,
                "ratingCount": newCount
            ], forDocument: pointRef)

            return nil
        }) { _, error in
            if let error = error {
                print("Error rating: \(error)")
            } else {
                self.showMessage(message: "Calificación realizada")
            }
        }

    }
    func showMessage(title: String = "Éxito", message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
extension LoginAccessViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
        self.resultsTable.isHidden = searchResults.isEmpty
        self.resultsTable.reloadData()
    }
    

}
