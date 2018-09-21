//
//  SellerMapVC
//  Buyer
//
//  Created by William J. Wolfe on 4/28/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase


class SellerMapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var myMap: MKMapView!
    
    private var locationManager = CLLocationManager();
    private var userLocation: CLLocationCoordinate2D?;
    private var buyerLocation: CLLocationCoordinate2D?;
    
    
    //Putting this in for now:
    private var acceptedAuction = true;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myMap.delegate = self
        myMap.showsScale = true
        myMap.showsPointsOfInterest = true
        myMap.showsUserLocation = true
        
        initializeLocationManager()
        // Suggested by Jared on video:
        //if CLLocationManager.locationServicesEnabled() {}
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeMessagesForMyMap()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //DBProvider.Instance.dbRef.removeAllObservers()
    }
    
    
    private func initializeLocationManager() {
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestWhenInUseAuthorization();
        locationManager.startUpdatingLocation();
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // if we have the coordinates from the manager
        if let location = locationManager.location?.coordinate {
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            
            let region = MKCoordinateRegion(
                center: userLocation!,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005));
            
            myMap.setRegion(region, animated: true);
            
            myMap.removeAnnotations(myMap.annotations);
            /*
            if sellerLocation != nil {
                if acceptedAuction {
                    let sellerAnnotation = MKPointAnnotation();
                    sellerAnnotation.coordinate = sellerLocation!;
                    sellerAnnotation.title = "Seller Location";
                    myMap.addAnnotation(sellerAnnotation);
                }
            }
            */
            //For Seller mode, use:
            print("Inside Seller Map View: buyerLocation = \(String(describing: buyerLocation))")
             if buyerLocation != nil {
                if acceptedAuction {
                    let buyerAnnotation = MKPointAnnotation();
                    buyerAnnotation.coordinate = buyerLocation!;
                    buyerAnnotation.title = "Buyer Location";
                    myMap.addAnnotation(buyerAnnotation);
                }
             }
            
            
            let annotation = MKPointAnnotation();
            annotation.coordinate = userLocation!;
            //annotation.title = "Buyer Location";
            //For Seller mode, use:
            annotation.title = "Seller Location";
            myMap.addAnnotation(annotation);
            
        }
        
    }
    
    /*
    func updateSellersLocation(lat: Double, long: Double) {
        sellerLocation = CLLocationCoordinate2D(latitude: lat, longitude: long);
    }*/
    
    //For Seller mode, use:
    func updateBuyersLocation(lat: Double, long: Double) {
        print("inside Seller's MapView: updateBuyersLocation")
        print("buyer lat = \(lat)")
        print("buyer long = \(long)")
        buyerLocation = CLLocationCoordinate2D(latitude: lat, longitude: long);
    }
    
    
    func observeMessagesForMyMap() {
        
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let lat = data[Constants.LATITUDE] as? Double {
                    if let long = data[Constants.LONGITUDE] as? Double {
                        print("inside Seller's MapView:request ref child changed")
                        print("observing the request accepted ref child changed:")
                        print("buyer's lat = \(lat)")
                        print("buyer's long = \(long)")
                        //self.updateSellersLocation(lat: lat, long: long);
                        //For Seller mode, use:
                        self.updateBuyersLocation(lat: lat, long: long);
                        
                    }
                }
            }
        }
    }
    
}
