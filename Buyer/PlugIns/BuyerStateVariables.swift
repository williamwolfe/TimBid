//
//  BuyerStateVariables.swift
//  Buyer
//
//  Created by William J. Wolfe on 5/14/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import Foundation

class BuyerStateVariables {
    private static let _instance = BuyerStateVariables();
    
    var buyer = "";
    var buyer_id = "";
    
    var seller = "";
    var seller_id = "";
    var temp_seller = "";
    
    
    var request_accepted_id = ""; //this is the requestAccepted id, not the buyer's id
    var auction_key = "";
    
    var item_description = "";
    var min_price = "";
    var min_price_cents = "";
    
    var amount_paid = "";
    var accepted_by = "";
    
    var inAuction = false;
    
    
    static var Instance: BuyerStateVariables {
        return _instance;
    }
    
    func resetVariables () {
        seller = "";
        seller_id = "";
        temp_seller = "";
        auction_key = "";
        request_accepted_id = "";
        auction_key = "";
        amount_paid = "";
        min_price_cents = "";
        min_price = "";
        item_description = "";
        accepted_by = "";
        inAuction = false;
        
    }
}
