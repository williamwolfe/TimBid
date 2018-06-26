//
//  PayVC.swift
//  Buyer
//
//  Created by William J. Wolfe on 1/1/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit
import Stripe
import FirebaseDatabase
import FirebaseAuth

class PayVC: UIViewController, STPPaymentCardTextFieldDelegate, PayController  {
    
    var paymentCardTextField: STPPaymentCardTextField! = nil
    var submitButton: UIButton! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if(AuctionHandler.Instance.amount_paid != "") {
            var amountPaid:Int? = Int(AuctionHandler.Instance.min_price)
            amountPaid = amountPaid!/100
            payment.text = "Paid $\(amountPaid!) Thank You!"
            payment2.text = "Show this to the Seller to confirm the payment."
        } else {
            if  AuctionHandler.Instance.min_price != "" {
                payment.text = "Pay: $\(Int(AuctionHandler.Instance.min_price)!/100)"
                payment2.text = ""
            } else {
                payment.text = "Sorry, no amount to pay, try again"
            }
            
        }
        
        PayHandler.Instance.delegate = self;
       
        paymentCardTextField = STPPaymentCardTextField(frame: CGRect(x: 15, y: 100, width: view.frame.width - 30, height: 44))
        paymentCardTextField.delegate = self
        view.addSubview(paymentCardTextField)
        
        submitButton = UIButton(type: .system)
        submitButton.frame = CGRect(x: 15, y: 150, width: 100, height: 44)
        submitButton.isEnabled = false
        submitButton.setTitle("Submit", for: [])
        submitButton.addTarget(self, action: #selector(self.submitCard(_:)), for: .touchUpInside)
        view.addSubview(submitButton)
        
    }
    
    func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
        submitButton.isEnabled = textField.isValid
    }
   
    @IBAction func submitCard(_ sender: Any) {
        // If you have your own form for getting credit card information, you can construct
        // your own STPCardParams from number, month, year, and CVV.
        let cardParams = paymentCardTextField.cardParams
        
        STPAPIClient.shared().createToken(withCard: cardParams) { token, error in
            
            guard let stripeToken = token else {
                NSLog("Error creating token: %@", error!.localizedDescription);
                return
            }
            
            // TODO: send the token to your server so it can create a charge
            
            let user_id = Auth.auth().currentUser!.uid
            //let user_id = DBProvider.Instance.dbRef.child("buyers").child(user!.uid)
           
            //Using the stripeToken.tokenId to write a "source" (card) to Firebase
           //   '/stripe_customers/{userId}/sources/{pushId}/token'
            DBProvider.Instance.dbRef.child("stripe_customers")
                .child(user_id)
                .child("sources")
                .childByAutoId()
                .child("token").setValue(stripeToken.tokenId)
            
        
            //Using the amount to charge the card:
            //   '/stripe_customers/{userId}/charges/{id}'
            
            
            DBProvider.Instance.dbRef.child("stripe_customers")
                .child(user_id)
                .child("charges")
                .childByAutoId()
                .child("amount").setValue(self.getAmount())
           
            
        }
    }
    
    func getAmount() -> Int {
        if let amount = Int(AuctionHandler.Instance.min_price) {
            return amount
        } else {
            return 0
        }
        
    }
    
    /*
    func getAmount() -> String {
        print("charge amount is: \(AuctionHandler.Instance.min_price)")
        return AuctionHandler.Instance.min_price
    }*/
    
    func buyerPaid() {
        AuctionHandler.Instance.amount_paid = AuctionHandler.Instance.min_price
        
        let buyer = AuctionHandler.Instance.buyer
        var amountPaid:Int? = Int(AuctionHandler.Instance.min_price)
        amountPaid = amountPaid!/100
    
        alertTheUser(
            title: "Payment",
            message: "Buyer \(buyer) has paid $\(amountPaid!)")
        submitButton.isEnabled = false
        payment.text = "Paid $\(amountPaid!) - Thank You!"
        payment2.text = "Show this to the Seller to confirm payment."
        //payBttnOutlet.isHidden = true
    }
    
    func paymentFailed(message: String) {
        alertTheUser(title: "Payment Failed", message: message)
    }
    

    @IBOutlet weak var payment: UILabel!
    
    @IBOutlet weak var payment2: UILabel!
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }
    

}
