//
//  Seller_AuctionHandler.swift
//  Buyer
//
//  Created by William J. Wolfe on 4/21/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol Seller_AuctionController: class {
    func canCallAuction(delegateCalled: Bool);
    func buyerAcceptedRequest(requestAccepted: Bool, buyerName: String);
    func updateBuyersLocation(lat: Double, long: Double);
    func buyerPaid();
    func addRecordToBid(buyer_id: String, seller_id: String, description: String, price: String, buyer_name: String)
    func printSellerVariables();
}


class Seller_AuctionHandler {
    private static let _instance = Seller_AuctionHandler();
    weak var delegate: Seller_AuctionController?;
    var seller = "";
    var seller_id = "";
    var buyer = "";
    var buyer_id = "";
    var auction_request_id = "";
   
    
    var status = ""; // stripe variable: "succeeded" means payment went through
    var min_price_cents = "";
    var amount_paid = "";
    var item_description = "";
    var auction_in_progress :Bool = false;
    var in_negotiations :Bool = false;
    
    var child_added_id = ""
    var previous_child_added_id = ""
    
    var bid_child_added_id = ""
    var previous_bid_child_added_id = ""
    
    static var Instance: Seller_AuctionHandler {
        return _instance;
    }
    
    func observeMessagesForSeller() {
        //Observe: Auction_Request, Child Added (seller has submitted an item for sale)
        DBProvider.Instance.requestRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            print("inside Seller: observe request, childAdded")
            if let data = snapshot.value as? NSDictionary {
                //avoid duplicate observations:
                self.child_added_id = snapshot.key;
                if(self.child_added_id != self.previous_child_added_id) {
                    if let name = data[Constants.NAME] as? String {
                        if let min_price_cents = data[Constants.MIN_PRICE] {
                            if let item_description = data[Constants.DESCRIPTION] {
                                if name == self.seller {
                                    self.auction_request_id = snapshot.key;
                                    self.auction_in_progress = true;
                                    self.min_price_cents = String(describing: min_price_cents)
                                    self.item_description = String(describing: item_description)
                                    self.delegate?.canCallAuction(delegateCalled: true);
                                    self.previous_child_added_id = self.child_added_id
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //Observe: Auction_Request, Child Removed (seller cancels auction)
        DBProvider.Instance.requestRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot) in
            print("inside Seller: observe request, childRemoved")
            if let data = snapshot.value as? NSDictionary {
                print("inside seller_auction_handler, heard a child removed")
                if let name = data[Constants.NAME] as? String {
                    if name == self.seller {
                        //self.auction_request_id = "";
                        self.auction_in_progress = false;
                        self.in_negotiations = false;
                        self.delegate?.canCallAuction(delegateCalled: false);
                        print("Seller_AuctionHandler: after request child removed:")
                        self.delegate?.printSellerVariables()
                    }
                }
            }
            
        }
        
        //Observe: Auction_Accepted, Child Added (buyer accepts auction)
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if let buyer_id = data[Constants.BUYER_ID] {
                        if let this_seller_id = data[Constants.SELLER_ID] {
                            //make sure this "acceptance" is for a auction put up by this seller:
                            if (String(describing: this_seller_id) == self.seller_id ) {
                                if self.buyer == "" {
                                    if self.min_price_cents != "" {
                                        self.buyer = name;
                                        self.buyer_id = buyer_id as! String;
                                        self.delegate?.buyerAcceptedRequest(requestAccepted: true, buyerName: self.buyer);
                                        self.delegate?.printSellerVariables()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
        
        //Observe: Auction_Accepted, Child Removed (buyer cancels auction)
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childRemoved) { (snapshot:DataSnapshot) in
            print("inside Seller: observe requestAccepted, childRemoved")
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.buyer {
                        self.buyer = "";
                        self.buyer_id = "";
                        self.auction_in_progress = false;
                        self.in_negotiations = false;
                        self.delegate?.buyerAcceptedRequest(requestAccepted: false, buyerName: name);
                        print("Seller_AuctionHandler: after request_accepted child removed:")
                        self.delegate?.printSellerVariables()
                    }
                }
            }
            
        }
        //Observe: Request_Accepted, Child Changed
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot) in
            print("inside Seller: observe requestAccepted, childChanged")
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constants.NAME] as? String {
                    if name == self.buyer {
                        if let lat = data[Constants.LATITUDE] as? Double {
                            if let long = data[Constants.LONGITUDE] as? Double {
                                self.delegate?.updateBuyersLocation(lat: lat, long: long);
                            }
                        }
                    }
                }
            }
        }
        
        DBProvider.Instance.bidRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            print("inside Seller: observe bid, childAdded")
            print("**** observed a child added to Bid")
            if let data = snapshot.value as? NSDictionary {
                let key = snapshot.key;
                self.bid_child_added_id = snapshot.key;
                if(self.bid_child_added_id != self.previous_bid_child_added_id){
                    self.child_added_id = snapshot.key;
                    if let buyer_id = data[Constants.BUYER_ID] {
                        if let buyer_name = data[Constants.BUYER_NAME] {
                            if let seller_id = data[Constants.SELLER_ID] as? String {
                                if let description = data[Constants.DESCRIPTION] {
                                    if let min_price = data[Constants.MIN_PRICE] {
                                        if (seller_id == Seller_AuctionHandler.Instance.seller_id) {
                                            print("bid buyer_id = \(buyer_id)")
                                            print("bid seller_id = \(seller_id)")
                                            print("bid description = \(description)")
                                            print("min_price = \(min_price)")
                                            print("buyer_name = \(buyer_name)")
                                            //put this bid in the cored database entity called Bid
                                            self.delegate?.addRecordToBid(
                                                buyer_id: buyer_id as! String,
                                                seller_id: seller_id,
                                                description: description as! String,
                                                price: min_price as! String,
                                                buyer_name: buyer_name as! String)
                                
                                            DBProvider.Instance.bidRef.child(key).removeValue();
                                            self.previous_bid_child_added_id = self.bid_child_added_id
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
    
    // this will be called after the buyer accepts the auction
    func startListeningForPayment() {
        DBProvider.Instance.stripeCustomersRef
            .child("\(self.buyer_id)")
            .child("charges")
            .observe(DataEventType.childChanged) {
                
                (snapshot: DataSnapshot) in
                
                if let data = snapshot.value as? NSDictionary {
                    
                    
                    if let amount = data["amount"] {
                        if let status = data["status"] {
                            if amount as? Int == Int(self.min_price_cents) && status as! String == "succeeded" {
                                self.delegate?.buyerPaid()
                            }
                            else {
                                print("Transaction failed, did not succeed)")
                            }
                        } else {
                            print("Transaction failed, missing status)")
                        }
                    } else {
                        print("Transaction failed, missing amount)")
                    }
                    
                }
        }
    }
    
    //seller submits an item for sale:
    func requestAuction(latitude: Double, longitude: Double, description: String, min_price_cents: Int, accepted_by: String) {
        let data: Dictionary<String, Any> =
            [Constants.NAME: seller,
             Constants.DESCRIPTION: description,
             Constants.MIN_PRICE: min_price_cents,
             Constants.ACCEPTED_BY: accepted_by,
             Constants.BUYER_ID: buyer_id,
             Constants.SELLER_ID: seller_id,
             Constants.LATITUDE: latitude,
             Constants.LONGITUDE: longitude];
        DBProvider.Instance.requestRef.childByAutoId().setValue(data);
    } // request auction
    
    func cancelAuction() {
        print("got into the seller's cancel auction func")
        print("auction_request_id = \(auction_request_id)")
        if (auction_request_id != "") {
            DBProvider.Instance.requestRef.child(auction_request_id).removeValue();
        }
        
        print("got past the remove request using auction_request_id")
        item_description = ""
        amount_paid = ""
        buyer_id = ""
        buyer = "";
        auction_request_id = "";
        status = ""; // stripe variable: "succeeded" means payment went through
        min_price_cents = "";
    }
    
    func updateSellerLocation(lat: Double, long: Double) {
        DBProvider.Instance.requestRef.child(auction_request_id).updateChildValues([Constants.LATITUDE: lat, Constants.LONGITUDE: long]);
    }
    func test() {
        print("I am a test function in seller_auctionHandler")
    }
    
    
}// end -- Seller_AuctionHandler
