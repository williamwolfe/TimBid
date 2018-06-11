//
//  AuctionHandler.swift
//  Buyer
//
//  Created by William J. Wolfe on 11/11/17.
//  Copyright © 2017 William J. Wolfe. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol AuctionController: class {
    func checkProximity(lat: Double, long: Double, description: String, min_price: String);
    func sellerCanceledAuction();
    func auctionCanceled();
    func updateSellersLocation(lat: Double, long: Double);
    func enableChat();
    func disableChat();
    func enablePay();
    func disablePay();
    func printBuyerVariables();
}

class AuctionHandler {
    private static let _instance = AuctionHandler();
    weak var delegate: AuctionController?;
    
    var auction_key = "";
    var seller = "";
    var seller_id = "";
    var temp_seller = "";
    var buyer = "";
    var buyer_id = "";
    var name = "";
   
    var min_price = "";
    var min_price_cents = ""
    var amount_paid = "";
    var accepted_by = "";
    var item_description = "";
    
     var request_accepted_id = ""; //this is the requestAccepted id, not the buyer's id
    
    var inAuction = false;
    
    
    var child_added_id = ""
    var previous_child_added_id = ""
    
    var request_accepted_child_added_id = ""
    var request_accepted_previous_child_added_id = ""
    
    static var Instance: AuctionHandler {
        return _instance;
    }
    
    
     func observeMessagesForBuyer() {
        //listen for a new auction request:
        DBProvider.Instance.requestRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            print("inside Buyer: observe request, childAdded")
            self.child_added_id = snapshot.key;
            if(self.child_added_id != self.previous_child_added_id) {
                //First: check to see if Buyer is currently in an auction (the "seller" variable has a value)
                if self.seller == "" {
                    if let data = snapshot.value as? NSDictionary {
                        if let latitude = data[Constants.LATITUDE] as? Double {
                        if let longitude = data[Constants.LONGITUDE] as? Double {
                            if let description = data[Constants.DESCRIPTION] {
                                if let min_price = data[Constants.MIN_PRICE] {
                                    if let name = data[Constants.NAME] {
                                        if let seller_id = data[Constants.SELLER_ID] {
                                            if let accepted_by = data[Constants.ACCEPTED_BY] {
                                                //Second, check to see if the request has not been taken by someone else:
                                                if (String(describing: accepted_by) == "no_one") {
                                                    
                                                    self.item_description = String(describing: description)
                                                    self.min_price = String(describing: min_price)
                                                    self.min_price_cents = String(describing: min_price)
                                                    //self.min_price_cents = 100 * self.min_price
                                                    self.temp_seller = name as! String
                                                    self.auction_key = snapshot.key
                                                    self.seller_id = seller_id as! String
                                                    

                                                    BuyerStateVariables.Instance.seller_id = seller_id as! String
                                                    BuyerStateVariables.Instance.item_description = String(describing: description)
                                                    BuyerStateVariables.Instance.min_price = String(describing: min_price)
                                                    BuyerStateVariables.Instance.min_price_cents = String(describing: min_price)
                                                    BuyerStateVariables.Instance.temp_seller = String(describing: name as! String)
                                                    BuyerStateVariables.Instance.auction_key = snapshot.key
                                                    
                                                    //Third: check that the seller is withing the geographic area:
                                                    self.delegate?.checkProximity(lat: latitude,long: longitude, description: description as! String,
                                                        min_price: String(describing: min_price)
                                                    );
                                                    
                                                    self.previous_child_added_id = self.child_added_id
                                                } else {
                                                    print("ignore this new request, it is already taken by someone else")
                                                }
                                                
                                            }
                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                } else {
                    print("ignore this new request, already have a seller, in an acution")
                }
            }
        }
            
        // Observe: Auction_Request, child removed
        // seller canceled auction:
        DBProvider.Instance.requestRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot) in
                print("inside Buyer: observe request, childRemoved")
                if let data = snapshot.value as? NSDictionary {
                        if let buyer_id = data[Constants.BUYER_ID] as? String {
                            print("got into (buyer) auction_handler, request, child removed (after checking match for buyer_id)")
                            if buyer_id == self.buyer_id {
                                self.delegate?.sellerCanceledAuction();
                                self.delegate?.disableChat();
                                self.delegate?.disablePay();
                            }
                        }
            }
        }
                

        
        
        DBProvider.Instance.requestRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot) in
            print("inside Buyer: observe request, childChanged")
            if let data = snapshot.value as? NSDictionary {
                if let lat = data[Constants.LATITUDE] as? Double {
                    if let long = data[Constants.LONGITUDE] as? Double {
                        self.delegate?.updateSellersLocation(lat: lat, long: long);
                        
                    }
                }
            }
            
        }
        
        //Buyer accepts Auction
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            self.request_accepted_child_added_id = snapshot.key;
            if(self.request_accepted_child_added_id != self.request_accepted_previous_child_added_id) {
                if let data = snapshot.value as? NSDictionary {
                    if let name = data[Constants.NAME] as? String {
                        if (name == self.buyer  && self.seller != "" ){
                            self.request_accepted_id = snapshot.key;
                            self.delegate?.enableChat()
                            self.delegate?.enablePay()
                            PayHandler.Instance.startListeningForPayment()
                            self.delegate?.printBuyerVariables()
                            self.request_accepted_previous_child_added_id = self.request_accepted_child_added_id
                        }
                    }
                }
            }
        }
        
        
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot) in
            print("inside Buyer: observe requestAccepted, childRemoved")
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.buyer {
                        self.delegate?.auctionCanceled();
                        self.delegate?.disableChat()
                        self.delegate?.disablePay()
                        
                        print("Buyer AuctionHandler: after request_accepted child removed")
                        self.delegate?.printBuyerVariables()
                    }
                }
            }
            
        }
        
    }
    /*
    func startListeningForPayment() {
        DBProvider.Instance.stripeCustomersRef
            .child("\(self.buyer_id)")
            .child("charges")
            .observe(DataEventType.childChanged) {
                
                (snapshot: DataSnapshot) in
                
                print("observed a stripe customer with buyer_id = \(self.buyer_id)")
                if let data = snapshot.value as? NSDictionary {
                    
                    print("inside buyer: data amount = \(data["amount"]!)")
                    print("inside buyer: data status = \(data["status"]!)")
                    print("min_price = \(self.min_price)")
                    if (data["amount"] as? Int == Int(self.min_price)
                        &&
                        data["status"] as! String == "succeeded"
                        ) {
                        
                        print("Transaction succeeded")
                    }
                    else {
                        print("Transaction failed") }
                }
        }
    }*/
 
    
    func auctionAccepted(lat: Double, long: Double) {
        
        let data: Dictionary<String, Any> = [
            Constants.NAME: buyer,
            Constants.SELLER: seller,
            Constants.BUYER_ID: buyer_id,
            Constants.SELLER_ID: seller_id,
            Constants.LATITUDE: lat,
            Constants.LONGITUDE: long];
        
       
        
        DBProvider.Instance.requestRef.child("\(auction_key)/accepted_by").observeSingleEvent(of: .value) {
            (snapshot) in
            if (snapshot.value as? String) != nil {
                if (snapshot.value as? String == "no_one") {
                    DBProvider.Instance.requestAcceptedRef.childByAutoId().setValue(data);
                    DBProvider.Instance.requestRef.child(self.auction_key).updateChildValues(["accepted_by": self.buyer])
                    DBProvider.Instance.requestRef.child(self.auction_key).updateChildValues(["buyer_id": self.buyer_id])
                    self.inAuction = true
                } else {
                    //auction is no longer available
                    self.delegate?.auctionCanceled();
                }
            } else {
                print("could not get a value for accepted_by from the request")
            }
        }
    }
    
    func cancelAuctionForBuyer() {
        print("inside cancelAuctionForBuyer: just before remove requestAccepted")
        if (self.request_accepted_id != "") {
            DBProvider.Instance.requestAcceptedRef.child(self.request_accepted_id).removeValue();
        } else {
            print("Auction Handler: request_accetped_id is the empty string")
        }
        
        print("inside cancelAuctionForBuyer: just after remove requestAccepted")
    }
    
    func updateBuyerLocation(lat: Double, long: Double) {
        if (self.request_accepted_id != "") {
            DBProvider.Instance.requestAcceptedRef.child(self.request_accepted_id).updateChildValues([Constants.LATITUDE: lat, Constants.LONGITUDE: long]);
        } else {
            print("Inside updateBuyerLocation: request_accepted_id is empty")
        }
    }
}//Auction Handler


