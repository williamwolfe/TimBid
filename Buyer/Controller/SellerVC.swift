//
//  SellerVC.swift
//  Buyer
//
//  Created by William J. Wolfe on 4/21/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class SellerVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, Seller_AuctionController {
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var callAuctionBtn: UIButton!
    @IBOutlet weak var startChat: UIButton!
    
    private var locationManager = CLLocationManager();
    private var userLocation: CLLocationCoordinate2D?;
    private var buyerLocation: CLLocationCoordinate2D?;
    
    private var timer = Timer();
    
    private var canCallAuction = true;
    private var sellerCanceledRequest = false;
    private var canChat = false;
    
    @IBOutlet weak var SellSomething: UILabel!
    @IBOutlet weak var MinPriceLabel: UILabel!
    @IBOutlet weak var DescribeThing: UITextView!
    @IBOutlet weak var MinPriceValue: UITextField!
    
    //private let SELLER_CHAT_SEGUE = "SellerChatSegue"
    //private let TABLE_VIEW_SEGUE = "TableViewSegue";
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //callAuctionBtn.backgroundColor = UIColor.jsq_messageBubbleGreen()
        //callAuctionBtn.backgroundColor = UIColor(red: 80/255, green: 161/255, blue: 101/255, alpha: 1.0)
        callAuctionBtn.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1.0)
        //callAuctionBtn.layer.cornerRadius = callAuctionBtn.frame.height/2
        callAuctionBtn.layer.shadowColor = UIColor.darkGray.cgColor
        callAuctionBtn.layer.shadowRadius = 4
        callAuctionBtn.layer.shadowOpacity = 0.5
        callAuctionBtn.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        startChat.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1.0)
        //startChat.layer.cornerRadius = startChat.frame.height/2
        startChat.layer.shadowColor = UIColor.darkGray.cgColor
        startChat.layer.shadowRadius = 4
        startChat.layer.shadowOpacity = 0.5
        startChat.layer.shadowOffset = CGSize(width: 0, height: 0)
        startChat.isHidden = true;
        
        initializeLocationManager();
        myMap.showsUserLocation = true
        
        Seller_AuctionHandler.Instance.delegate = self;
        Seller_AuctionHandler.Instance.min_price_cents = "";
        
        printSellerVariables()
        self.title = ""
        if (Seller_AuctionHandler.Instance.name != "") {
            self.title = Seller_AuctionHandler.Instance.name
        } else  {
            self.title = "TIMBid Seller"
        }

        
    }
    
    func printSellerVariables() {
        print("SellerVC: buyer = \(Seller_AuctionHandler.Instance.buyer)")
        print("SellerVC: buyer_id = \(Seller_AuctionHandler.Instance.buyer_id)")
        print("SellerVC: seller = \(Seller_AuctionHandler.Instance.seller)")
        print("SellerVC: seller_id = \(Seller_AuctionHandler.Instance.seller_id)")
        print("SellerVC: auction_request_id = \(Seller_AuctionHandler.Instance.auction_request_id)")
        //print("SellerVC: accepted_by = \(Seller_AuctionHandler.Instance.accepted_by)")
        //print("SellerVC: min_price = \(Seller_AuctionHandler.Instance.min_price)")
        print("SellerVC: min_price_cents = \(Seller_AuctionHandler.Instance.min_price_cents)")
        print("SellerVC: item_description = \(Seller_AuctionHandler.Instance.item_description)")
        print("SellerVC: amount_paid = \(Seller_AuctionHandler.Instance.amount_paid)")
        print("SellerVC: auction_in_progress = \(Seller_AuctionHandler.Instance.auction_in_progress)")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Seller_AuctionHandler.Instance.observeMessagesForSeller();
        if(Seller_AuctionHandler.Instance.item_description != "") {
            DescribeThing.text = Seller_AuctionHandler.Instance.item_description
        }
        if(Seller_AuctionHandler.Instance.min_price_cents != "") {
            var amountDollars :Int? = Int(Seller_AuctionHandler.Instance.min_price_cents)
            amountDollars = amountDollars!/100
            MinPriceValue.text = String(describing: amountDollars!)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DBProvider.Instance.dbRef.removeAllObservers()
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
            
            if buyerLocation != nil {
                if !canCallAuction {
                    let buyerAnnotation = MKPointAnnotation();
                    buyerAnnotation.coordinate = buyerLocation!;
                    buyerAnnotation.title = "Buyer Location";
                    myMap.addAnnotation(buyerAnnotation);
                }
            }
            
            let annotation = MKPointAnnotation();
            annotation.coordinate = userLocation!;
            annotation.title = "Seller's Location";
            myMap.addAnnotation(annotation);
            
        }
        
    }
    
    @objc func updateSellersLocation() {
        Seller_AuctionHandler.Instance.updateSellerLocation(lat: userLocation!.latitude, long: userLocation!.longitude);
    }
    
    //This function is called by an "observer" function in Seller_AuctionHandler
    func canCallAuction(delegateCalled: Bool) {
        if delegateCalled { //seller added an auction request
            //Set the UI for Seller:
            callAuctionBtn.setTitle("Cancel Auction", for: UIControlState.normal);
            //callAuctionBtn.backgroundColor = UIColor(red: 80/255, green: 161/255, blue: 101/255, alpha: 1)
            canCallAuction = false;
            DescribeThing.isEditable = false
            MinPriceValue.isEnabled = false;
            if (Seller_AuctionHandler.Instance.amount_paid != "") {
                var amountPaid:Int? = Int(Seller_AuctionHandler.Instance.min_price_cents)
                amountPaid = amountPaid!/100
                SellSomething.text = "\(Seller_AuctionHandler.Instance.buyer) paid $\(amountPaid!)"
            } else {
                if Seller_AuctionHandler.Instance.buyer != "" {
                    SellSomething.text = "Found buyer: \(Seller_AuctionHandler.Instance.buyer)"
                } else {
                    SellSomething.text = "Currently For Sale:"
                }
            }
            //Add sale item to the Core Data entity "Item"
            addRecordToSellerItem()
        } else { //seller canceled the auction
            //Set the UI for Seller:
            //callAuctionBtn.backgroundColor = UIColor(red: 80/255, green: 161/255, blue: 101/255, alpha: 1)
            callAuctionBtn.setTitle("Call Auction", for: UIControlState.normal);
            canCallAuction = true;
            DescribeThing.isEditable = true;
            MinPriceValue.isEnabled = true;
            SellSomething.text = "Describe what you want to sell:"
            canChat = false;
            startChat.isHidden = true;
            Seller_MessagesHandler.Instance.cancelChat();
            buyerLocation = nil;
            Seller_AuctionHandler.Instance.buyer = "";
            Seller_AuctionHandler.Instance.buyer_id = "";
            Seller_AuctionHandler.Instance.amount_paid = "";
            
        }
    }
    
    func buyerAcceptedRequest(requestAccepted: Bool, buyerName: String) {
        
        if !sellerCanceledRequest {
            if requestAccepted {
                alertTheUser(title: "Auction Accepted", message: "\(buyerName) Accepted Your Auction Request")
                canChat = true;
                startChat.isHidden = false;
                SellSomething.text = "Found buyer: \(Seller_AuctionHandler.Instance.buyer)"
                Seller_AuctionHandler.Instance.startListeningForPayment()
            } else { // Buyer canceled the auction
                print("inside SellerVC: buyer canceled the auction")
                Seller_AuctionHandler.Instance.buyer = "";
                Seller_AuctionHandler.Instance.buyer_id = "";
                Seller_AuctionHandler.Instance.amount_paid = ""
                MinPriceLabel.text = "Price:"
                startChat.isHidden = true;
                Seller_AuctionHandler.Instance.cancelAuction();//remove request (auction_request_id) from DB
                timer.invalidate();
                alertTheUser(title: "Auction Canceled", message: "\(buyerName) Canceled Auction Request")
                
                
            }
        }
        sellerCanceledRequest = false;
    }
    
    func buyerPaid() {
        
        Seller_AuctionHandler.Instance.amount_paid = Seller_AuctionHandler.Instance.min_price_cents
        let buyer = Seller_AuctionHandler.Instance.buyer
        var amountPaid:Int? = Int(Seller_AuctionHandler.Instance.min_price_cents)
        amountPaid = amountPaid!/100
        alertTheUser(
            title: "Payment",
            message: "Buyer \(buyer) has paid $\(amountPaid!)")
        SellSomething.text = "\(buyer) paid $\(amountPaid!)"
    }
    
    func updateBuyersLocation(lat: Double, long: Double) {
        buyerLocation = CLLocationCoordinate2D(latitude: lat, longitude: long);
    }
    
    @IBAction func Minus5(_ sender: Any) {
        var price  = Int(MinPriceValue.text!)!;
        price -= 5;
        if(price <= 0) {
            price = 0;
        }
        print("price = \(price)")
        if(MinPriceValue.isEnabled) {
            MinPriceValue.text = String(price);
        }
        
    }
    
    @IBAction func Plus5(_ sender: Any) {
        var price = Int(MinPriceValue.text!)!
        price += 5
        print("price = \(price)")
        if(MinPriceValue.isEnabled) {
            MinPriceValue.text = String(price);
        }
    }
    
    //call auction:
    //The button text is "call auction" and then gets changed to "cancel auction"
    @IBAction func callAuction(_ sender: Any) {
        if userLocation != nil {
            if(callAuctionBtn.currentTitle == "Call Auction") {
                //if the buyer mode is in an auction, don't start a new one
                if (AuctionHandler.Instance.inAuction == true) {
                    print("currently in an auction as a buyer, cancel that auction if you wish to call a new auction")
                    alertTheUser(title: "Already in an auction", message: "Please cancel that auction if you wish to call a new auction")
                    return
                }
                //if canCallAuction { // the user (seller) clicked on "call auction"
                //validate the inputs and that the min_price is a whole number of dollars
                //and then convert to min_price_cents
                var min_price_cents = 0
                min_price_cents = validateInputs()
                if min_price_cents <= 0 {
                    alertTheUser(title: "Price is 0", message: "Please enter a price greater than 0 dollars.")
                    return
                }
                //////////////////////////////////////////////
                Seller_AuctionHandler.Instance.requestAuction(
                    latitude: Double(userLocation!.latitude),
                    longitude: Double(userLocation!.longitude),
                    description: DescribeThing.text!,
                    min_price_cents: min_price_cents,
                    accepted_by: "no_one")
                ////////////////////////////////////////////////
                /*
                Seller_AuctionHandler.Instance.test()
                let data: Dictionary<String, Any> =
                    [Constants.NAME: Seller_AuctionHandler.Instance.seller,
                     Constants.DESCRIPTION: DescribeThing.text!,
                     Constants.MIN_PRICE: min_price_cents,
                     Constants.ACCEPTED_BY: "no one",
                     Constants.BUYER_ID: Seller_AuctionHandler.Instance.buyer_id,
                     Constants.SELLER_ID: Seller_AuctionHandler.Instance.seller_id,
                     Constants.LATITUDE: Double(userLocation!.latitude),
                     Constants.LONGITUDE: Double(userLocation!.longitude)]
                DBProvider.Instance.requestRef.childByAutoId().setValue(data);
                */
                /////////////////////////////////////////////////////
                
                timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(SellerVC.updateSellersLocation), userInfo: nil, repeats: true);
                callAuctionBtn.setTitleColor(.black, for: .normal)
                
            } else { //the user (seller) clicked on "cancel aution"
                Seller_AuctionHandler.Instance.cancelAuction();//remove request (auction_request_id) from DB
                buyerLocation = nil;
                MinPriceLabel.text = "Price ($)"
                timer.invalidate();
                callAuctionBtn.setTitleColor(.white, for: .normal)
                
            }
        } else {
            alertTheUser(title: "Location Problem", message: "The app is unable to determine your location")
        }
    }
    
    private func validateInputs() -> Int {
        if(DescribeThing.text == "") {
            alertTheUser(title: "Describe the item", message: "Please describe the item for sale")
            return 0
        } else if (MinPriceValue.text == "") {
            alertTheUser(title: "Minimum Price", message: "Please enter a minimum price for the item")
        } else  {
            let min_price_dollars = Int(MinPriceValue.text!)
            if min_price_dollars != nil {
                var min_price_cents = 0
                min_price_cents = 100*min_price_dollars!
                return min_price_cents
            } else {
                alertTheUser(title: "Format Eerror",
                             message: "Dollar value must be a whole number, no decimals or cents")
                return 0
            }
        }
        
        return 0
    }
    
/*
    @IBAction func backButton(_ sender: Any) {
        print("got into the backButton action")
        if !canCallAuction {
            Seller_AuctionHandler.Instance.cancelAuction()
            buyerLocation = nil;
            MinPriceLabel.text = "min price:"
            timer.invalidate();
        }
        dismiss(animated: true, completion: nil)
    }
*/
    
    @IBAction func logout(_ sender: Any) {
        if !canCallAuction {
            Seller_AuctionHandler.Instance.cancelAuction();
            Seller_MessagesHandler.Instance.cancelChat();
            timer.invalidate();
        }
        if (AuthProvider.Instance.logOut()) {
            dismiss(animated: true, completion: nil);
        } else {
           alertTheUser(title: "Could Not Logout", message: "We could not logout at the moment, please try again later");
        }
    }
    
    /*
    @IBAction func GoToTableView(_ sender: Any) {
        performSegue(withIdentifier: TABLE_VIEW_SEGUE, sender: nil)
    }*/
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }
    
    func addRecordToSellerItem() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "SellerItem", into: context)
        newItem.setValue(Seller_AuctionHandler.Instance.item_description, forKey: "item_description")
        newItem.setValue(Seller_AuctionHandler.Instance.min_price_cents, forKey: "item_price")
        newItem.setValue(Seller_AuctionHandler.Instance.buyer_id, forKey: "buyer_identifier")
        newItem.setValue(Date(), forKey: "post_date")
        newItem.setValue(Date(), forKey: "purchase_date") //should fix this, the item is not sold yet. date should be nil
        do
        {
            try context.save()
        }
        catch
        {
            print("error trying to save to core data")
        }
    }
    
    func addRecordToBid(buyer_id: String, seller_id: String, description: String, price: String, buyer_name: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "SellerBid", into: context)
        newItem.setValue(buyer_id, forKey: "buyer_id")
        newItem.setValue(seller_id, forKey: "seller_id")
        newItem.setValue(price, forKey: "min_price")
        newItem.setValue(description, forKey: "item_description")
        newItem.setValue(Date(), forKey: "date")
        newItem.setValue(buyer_name, forKey: "buyer_name")
        
        do
        {
            try context.save()
            print("%%%%%%  added a record to Bid")
            let price_dollars = Int(price)!/100
            alertTheUser(title: "A Bid Arrived", message: "A buyer bid $\(price_dollars) on item: \(description), check your Bid List")
        }
        catch
        {
            print("error trying to save to Bid core data")
        }
        //myTableView.reloadData()
    }
    
    
}

