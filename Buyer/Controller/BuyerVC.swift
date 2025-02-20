//
//  BuyerVC.swift
//  Buyer
//
//  Created by William J. Wolfe on 11/8/17.
//  Copyright © 2017 William J. Wolfe. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Firebase
import FirebaseAuth


class BuyerVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, AuctionController {

    @IBOutlet weak var BuyerModeText: UITextView!
    @IBOutlet weak var acceptAuctionBtn: UIButton!
    @IBOutlet weak var chatBttnOutlet: UIButton!
    @IBOutlet weak var payBttnOutlet: UIButton!
    
    @IBOutlet weak var myMap: MKMapView!
    private var locationManager = CLLocationManager();
    private var userLocation: CLLocationCoordinate2D?;
    private var sellerLocation: CLLocationCoordinate2D?;
    private var timer = Timer();
    
    private var acceptedAuction         = false;
    private var buyerCanceledAuction    = false;
    private var canChat                 = false;
    private var canPay                  = false;
    
    private var  buyer_mode_text = "Welcome to the BUYER MODE of the TIMBid  App!  You can bid on items by clicking on the VIEW AUCTIONS button.  You will be notified if the seller accepts your bid.  Then you will see the seller's location on the MAP, a CHAT option will be enabled, a PAY button will facilitate payment, and a CANCEL button will allow you to cancel at any time.  To sell an item, switch to the SELLER MODE by clicking the icon on the bottom tab bar"
    
    private var buyer_mode_in_auction_text = "Auction in Progress: Hit Chat to connect with the Seller, hit View Map to see where the Seller is, and hit Pay to complete the transaction.  Hit CANCEL to cancel this auction."
    
    private var delta = 0.01;
    //Here are some values for how delta will make to km or ft:
    //.0005 --> 0.1 km = 328  ft
    //.0010 --> 0.2 km = 656  ft
    //.0050 --> 1.0 km = 3280 ft
    //.0100 --> 2.0 km
    
    var items: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeLocationManager();
        myMap.showsUserLocation = true
        AuctionHandler.Instance.delegate = self;
        BuyerModeText.text = buyer_mode_text
        
        chatBttnOutlet.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1)
        chatBttnOutlet.layer.shadowColor = UIColor.darkGray.cgColor
        chatBttnOutlet.layer.shadowRadius = 4
        chatBttnOutlet.layer.shadowOpacity = 0.5
        chatBttnOutlet.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        acceptAuctionBtn.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1)
        acceptAuctionBtn.layer.shadowColor = UIColor.darkGray.cgColor
        acceptAuctionBtn.layer.shadowRadius = 4
        acceptAuctionBtn.layer.shadowOpacity = 0.5
        acceptAuctionBtn.layer.shadowOffset = CGSize(width: 0, height: 0)
       
        payBttnOutlet.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1)
        payBttnOutlet.layer.shadowColor = UIColor.darkGray.cgColor
        payBttnOutlet.layer.shadowRadius = 4
        payBttnOutlet.layer.shadowOpacity = 0.5
        payBttnOutlet.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        chatBttnOutlet.isEnabled = false
        chatBttnOutlet.setTitleColor(UIColor.gray, for: .disabled)
        chatBttnOutlet.backgroundColor = UIColor.lightGray
        chatBttnOutlet.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 0.3)
        chatBttnOutlet.isHidden = false;
        
        payBttnOutlet.isEnabled = false
        payBttnOutlet.setTitleColor(UIColor.gray, for: .disabled)
        payBttnOutlet.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 0.3)
        payBttnOutlet.isHidden = false;
        
        printBuyerVariables()
        
    }
    
    func printBuyerVariables() {
        
        print("BuyerVC: buyer = \(AuctionHandler.Instance.buyer)")
        print("BuyerVC: buyer_id = \(AuctionHandler.Instance.buyer_id)")
        print("BuyerVC: seller = \(AuctionHandler.Instance.seller)")
        print("BuyerVC: seller_id = \(AuctionHandler.Instance.seller_id)")
        print("BuyerVC: auction_key = \(AuctionHandler.Instance.auction_key)")
        print("BuyerVC: request_accepted_id = \(AuctionHandler.Instance.request_accepted_id)")
        print("BuyerVC: accepted_by = \(AuctionHandler.Instance.accepted_by)")
        print("BuyerVC: min_price = \(AuctionHandler.Instance.min_price)")
        print("BuyerVC: min_price_cents = \(AuctionHandler.Instance.min_price_cents)")
        print("BuyerVC: item_description = \(AuctionHandler.Instance.item_description)")
        print("BuyerVC: amount_paid = \(AuctionHandler.Instance.amount_paid)")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AuctionHandler.Instance.observeMessagesForBuyer();
        self.title = ""
        if (AuctionHandler.Instance.name != "") {
            self.title = AuctionHandler.Instance.name
        } else  {
            self.title = "TIMBid Buyer"
        }
        
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
            
            if sellerLocation != nil {
                if acceptedAuction {
                    let sellerAnnotation = MKPointAnnotation();
                    sellerAnnotation.coordinate = sellerLocation!;
                    sellerAnnotation.title = "Sellers Location";
                    myMap.addAnnotation(sellerAnnotation);
                }
            }
 
            
            let annotation = MKPointAnnotation();
            annotation.coordinate = userLocation!;
            annotation.title = "Buyer's Location";
            myMap.addAnnotation(annotation);
            
        }
        
    }
 

    @IBAction func logout(_ sender: Any) {
        if acceptedAuction {
            acceptAuctionBtn.isHidden = true;
            AuctionHandler.Instance.cancelAuctionForBuyer();
            MessagesHandler.Instance.cancelChat();
            timer.invalidate();
        }
        if AuthProvider.Instance.logOut() {
            dismiss(animated: true, completion: nil);
        } else {
            // problem with logging out
            alertTheUser(title: "Could Not Logout", message: "We could not logout at the moment, please try again later");
        }
    }
    
    
    func checkProximity(lat: Double, long: Double, description: String, min_price: String) {

    if nearby(lat: lat, long: long) && !acceptedAuction
        {
            addRecordToItem()
            presentAcceptRejectOption(
                    title:          "Auction Request",
                    message:        "Item Up For Sale, Description:\(description), Min Price: $\(Int(min_price)!/100)");
        } else
        {
            rejectAuction()
        }
    }
 
    
    func nearby(lat: Double, long: Double) -> Bool {
        //"delta" is a global variable
        if userLocation != nil {
            return true
            /*
            if  (lat  <= self.userLocation!.latitude + delta)   && (lat  >= self.userLocation!.latitude - delta)
                &&
                (long <= self.userLocation!.longitude + delta)  && (long >= self.userLocation!.longitude - delta)
            {
                return true
            } else
            {
                return false
            }
            */
        } else {
            print("missing location information")
            return false
        }
    }
    
    private func presentAcceptRejectOption(title: String, message: String) {
        
        let alert = UIAlertController(
            title:      title,
            message:    message,
            preferredStyle: .alert);
        
        let accept = UIAlertAction(
            title: "Accept",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                AuctionHandler.Instance.seller = AuctionHandler.Instance.temp_seller
                self.acceptedAuction = true;
                self.acceptAuctionBtn.isHidden = false;
                self.BuyerModeText.text = self.buyer_mode_in_auction_text + " Seller: \(AuctionHandler.Instance.seller).  Item: \(AuctionHandler.Instance.item_description).  Price: $\(Int(AuctionHandler.Instance.min_price)!/100)."
                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(BuyerVC.updateBuyersLocation), userInfo: nil, repeats: true);
                
                AuctionHandler.Instance.auctionAccepted(
                    lat:    Double(self.userLocation!.latitude),
                    long:   Double(self.userLocation!.longitude)); //creates a new Request_Accepted child (autoID)
        });
        
        let reject = UIAlertAction(
            title: "Reject",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                
                self.rejectAuction()
        });
        
        alert.addAction(accept);
        alert.addAction(reject);
        //rootViewController?.present(alert, animated: true, completion: nil)
        present(alert, animated: true, completion: nil)
        
    }
    
    func sellerCanceledAuction() {
        if !buyerCanceledAuction {
            updateStatus(status: "2")
            
            AuctionHandler.Instance.cancelAuctionForBuyer(); //removes requestAccepted (buyer_id) item from DB
            self.acceptedAuction = false;
            self.acceptAuctionBtn.isHidden = true;
           
            if AuctionHandler.Instance.seller != "" {
                alertTheUser( title: "Auction Canceled", message: "\(AuctionHandler.Instance.seller) Has Canceled The Auction");
            }
            BuyerStateVariables.Instance.resetVariables();
            
            AuctionHandler.Instance.seller = "";
            AuctionHandler.Instance.seller_id = "";
            AuctionHandler.Instance.auction_key = "";
            AuctionHandler.Instance.amount_paid = "";
            AuctionHandler.Instance.min_price_cents = "";
            AuctionHandler.Instance.min_price = "";
            AuctionHandler.Instance.item_description = "";
            AuctionHandler.Instance.request_accepted_id = "";
            
        }
        //added this line after lots of testing.
        //the symptom was that the requestAccepted was not being deleted when the seller canceled.
        //this only happened after a couple of cycles of request/accepted/cancels etc:
        buyerCanceledAuction = false
    }
    func getContext() -> NSManagedObjectContext  {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        return context
    }
    
    func auctionCanceled() {
        updateStatus(status: "2")
        rejectAuction()
        buyerCanceledAuction = false;
        timer.invalidate();
    }
    
    func updateStatus(status: String) {
        let context = getContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let item_description = result.value(forKey: "item_description") as? String {
                        if item_description == AuctionHandler.Instance.item_description {
                            if let min_price = result.value(forKey: "item_price") as? String{
                                if min_price == AuctionHandler.Instance.min_price {
                                    if(result.value(forKey: "status") as? String != "0") {
                                        result.setValue(status, forKey: "status")
                                        do { try context.save() } catch {print("9999 error trying to save to core data") }
                                    }
                                }
                            }
                            
                            
                        }
                    }
                }
            }
        } catch { print("error getting Item data in auctionCanceled") }
    }
    
    private func rejectAuction() {
        self.acceptedAuction = false
        self.acceptAuctionBtn.isHidden = true;
        
        AuctionHandler.Instance.amount_paid = ""
        AuctionHandler.Instance.seller = "";
        AuctionHandler.Instance.seller_id = "";
        AuctionHandler.Instance.min_price_cents = "";
        AuctionHandler.Instance.min_price = "";
        AuctionHandler.Instance.item_description = "";
        
        AuctionHandler.Instance.request_accepted_id = "";
        AuctionHandler.Instance.inAuction = false
        
        self.BuyerModeText.text = self.buyer_mode_text
        
        
    }
    
    func updateSellersLocation(lat: Double, long: Double) {
        print("updating seller's location (inside BuyerVC)")
        sellerLocation = CLLocationCoordinate2D(latitude: lat, longitude: long);
    }
    
    @objc func updateBuyersLocation() {
        AuctionHandler.Instance.updateBuyerLocation(lat: userLocation!.latitude, long: userLocation!.longitude);
    }
    
    // the "cancel" button, somehow I named it oddly
    @IBAction func buyItem(_ sender: Any) {
        if acceptedAuction {
            buyerCanceledAuction = true;
            acceptAuctionBtn.isHidden = true;
            AuctionHandler.Instance.cancelAuctionForBuyer(); //remove requestAccepted (buyer_id)
            timer.invalidate();
        }
    }
    
    
    internal func enableChat() {
        chatBttnOutlet.isEnabled = true
        chatBttnOutlet.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1)
        updateStatus(status: "3")
    }
    
    internal func disableChat() {
        chatBttnOutlet.isEnabled = false
        chatBttnOutlet.setTitleColor(UIColor.gray, for: .disabled)
        chatBttnOutlet.backgroundColor = UIColor.lightGray
    }

    
    
    internal func enablePay() {
        payBttnOutlet.isEnabled = true
        payBttnOutlet.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1)
        
    }
    
    internal func disablePay() {
        payBttnOutlet.isEnabled = false
        payBttnOutlet.setTitleColor(UIColor.gray, for: .disabled)
        payBttnOutlet.backgroundColor = UIColor.lightGray
    }
    
    func addRecordToItem() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "Item", into: context)
        newItem.setValue(AuctionHandler.Instance.item_description, forKey: "item_description")
        newItem.setValue(AuctionHandler.Instance.min_price_cents, forKey: "item_price")
        newItem.setValue(AuctionHandler.Instance.seller_id, forKey: "seller_identifier")
        newItem.setValue(Date(), forKey: "post_date")
        newItem.setValue(Date(), forKey: "purchase_date") //should fix this, the item is not sold yet. date should be nil
        newItem.setValue("1", forKey: "status") //"1" means "open for bids"
        do
        {
            try context.save()
        }
        catch
        {
            print("error trying to save to core data")
        }
    }
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }
    

}
