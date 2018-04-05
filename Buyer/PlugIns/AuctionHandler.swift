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
}

class AuctionHandler {
    private static let _instance = AuctionHandler();
    
    weak var delegate: AuctionController?;
    
    var seller = "";
    var seller_id = "";
    var temp_seller = "";
    var buyer = "";
    var buyer_id = "";
    var request_accepted_id = ""; //this is the requestAccepted id, not the buyer's id
    var auction_key = "";
    var min_price = "";
    var min_price_cents = ""
    var amount_paid = "";
    var accepted_by = "";
    var item_description = "";
    
    
    var child_added_id = ""
    var previous_child_added_id = ""
    
    static var Instance: AuctionHandler {
        return _instance;
    }
    
    
     func observeMessagesForBuyer() {
        //listen for a new auction request:
        DBProvider.Instance.requestRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            print("seller = \(self.seller)")
            self.child_added_id = snapshot.key;
            if(self.child_added_id != self.previous_child_added_id) {
            if self.seller == "" {
                if let data = snapshot.value as? NSDictionary {
                    if let latitude = data[Constants.LATITUDE] as? Double {
                        if let longitude = data[Constants.LONGITUDE] as? Double {
                            if let description = data[Constants.DESCRIPTION] {
                                if let min_price = data[Constants.MIN_PRICE] {
                                    if let name = data[Constants.NAME] {
                                        if let seller_id = data[Constants.SELLER_ID] {
                                            if let accepted_by = data[Constants.ACCEPTED_BY] {
                                        
                                                if (String(describing: accepted_by) == "no_one") {
                                                    self.item_description = String(describing: description)
                                                    self.min_price = String(describing: min_price)
                                                    self.min_price_cents = String(describing: min_price)
                                                    //self.min_price_cents = 100 * self.min_price
                                                    self.temp_seller = name as! String
                                                    self.auction_key = snapshot.key
                                                    self.seller_id = seller_id as! String
    
                                                    self.delegate?.checkProximity(
                                                        lat: latitude,
                                                        long: longitude,
                                                        description: description as! String,
                                                        min_price: String(describing: min_price)
                                                    );
                                                    print("inside observe request child added, after checkProximity")
                                                    self.previous_child_added_id = self.child_added_id
                                                }
                                                
                                            }
                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                }
            }
            
        }
            
        // Observe: Auction_Request, child removed
        // seller canceled auction:
        DBProvider.Instance.requestRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot) in
                if let data = snapshot.value as? NSDictionary {
                        if let buyer_id = data[Constants.BUYER_ID] as? String {
                            if buyer_id == self.buyer_id {
                                self.delegate?.sellerCanceledAuction();
                                self.delegate?.disableChat();
                                self.delegate?.disablePay();
                            }
                        }
            }
        }
                

        
        
        DBProvider.Instance.requestRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot) in
            print("inside Buyer: observe auction_request, child changed")
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
            print("inside Buyer: observe auction_accepted, child added")
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if (name == self.buyer  && self.seller != "" ){
                        self.request_accepted_id = snapshot.key;
                        print("buyer's request accepted id = \(self.request_accepted_id)")
                        print("user_id (buyer) = \(AuthProvider.Instance.user_id)")
                        self.delegate?.enableChat()
                        self.delegate?.enablePay()
                        PayHandler.Instance.startListeningForPayment()
                    }
                }
            }
            
        }
        
        //Buyer canceled Auction
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                print("inside Buyer: observe auction_accepted, child removed")
                if let name = data[Constants.NAME] as? String {
                    if name == self.buyer {
                        self.delegate?.auctionCanceled();
                        self.delegate?.disableChat()
                        self.delegate?.disablePay()
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
        DBProvider.Instance.requestAcceptedRef.child(self.request_accepted_id).removeValue();
        //DBProvider.Instance.requestRef.child(self.auction_key).updateChildValues(["accepted_by": "no_one"])
        //DBProvider.Instance.requestRef.child(self.auction_key).updateChildValues(["buyer_id": ""])
    }
    
    func updateBuyerLocation(lat: Double, long: Double) {
        DBProvider.Instance.requestAcceptedRef.child(self.request_accepted_id).updateChildValues([Constants.LATITUDE: lat, Constants.LONGITUDE: long]);
    }


}//Auction Handler
