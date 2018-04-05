//
//  PayHandler.swift
//  Buyer
//
//  Created by William J. Wolfe on 2/16/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import Foundation
import FirebaseDatabase


protocol PayController: class {
    func buyerPaid()
    func paymentFailed(message: String)
}

class PayHandler {
    private static let _instance = PayHandler();
    
    weak var delegate: PayController?;
    
    static var Instance: PayHandler {
        return _instance;
    }
    
    func startListeningForPayment() {
        DBProvider.Instance.stripeCustomersRef
            .child("\(AuctionHandler.Instance.buyer_id)")
            .child("charges")
            .observe(DataEventType.childChanged) {
                
                (snapshot: DataSnapshot) in
                
                print("observed a stripe customer with buyer_id = \(AuctionHandler.Instance.buyer_id)")
                if let data = snapshot.value as? NSDictionary {
                    
                    
                    if let amount = data["amount"] {
                        if let status = data["status"] {
                            if amount as? Int == Int(AuctionHandler.Instance.min_price) && status as! String == "succeeded" {
                                self.delegate?.buyerPaid()
                            }
                            else {
                                self.delegate?.paymentFailed(message: "Transaction failed, did not succeed")
                                print("Transaction failed, did not succeed)")
                            }
                        } else {
                            self.delegate?.paymentFailed(message: "Transaction failed, missing status")
                            print("Transaction failed, missing status)")
                        }
                    } else {
                        self.delegate?.paymentFailed(message: "Transaction failed, because amount missing")
                        print("Transaction failed, because amount missing)")
                    }
                }
        }
    }
  
}

