import UIKit
import MapKit
import CoreLocation
class LoginAccessViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var centerButtom: UIButton!
    let locationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Acceso"
        locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()

            mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
    }
    
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }

    @IBAction func centerMapButtonTapped(_ sender: UIButton) {
        mapView.setUserTrackingMode(.follow, animated: true)
    }
    
    @IBAction func tiltMapButtonTapped(_ sender: UIButton) {
        let camera = MKMapCamera(
                lookingAtCenter: mapView.centerCoordinate, // mira al centro actual
                fromDistance: 500,   // altura sobre el terreno (ajusta a tu gusto)
                pitch: 60,           // inclinación en grados (0 = plano)
                heading: 0           // dirección que mira la cámara
            )
            mapView.setCamera(camera, animated: true)
    }
    
}
