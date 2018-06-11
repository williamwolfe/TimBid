//
//  SellerRatingBuyerVC.swift
//  Buyer
//
//  Created by William J. Wolfe on 6/9/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit

class SellerRatingBuyerVC: UIViewController {
    
    public var thisBuyerID = ""
    public var currentRating = ""
    public var nRatings = 1
    public var thisRatingValue = ""
    public var thisBuyerName = ""
    public var thisBuyerEmail = ""
    
    @IBOutlet weak var thisRating: UILabel!
    
    @IBOutlet weak var thisBuyerNameLabel: UILabel!
    
    @IBOutlet weak var currentRatinglabel: UILabel!
    
    @IBOutlet weak var nRatingsLabel: UILabel!
    
    @IBOutlet weak var thisBuyerEmailLabel: UILabel!
    
    @IBOutlet weak var thisBuyerIDLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Rate This Buyer"
        print("thisBuyerID = \(thisBuyerID)")
        thisBuyerIDLabel.text = thisBuyerID
        thisRating.text = "3"
        
        if (thisBuyerID != "") {
            DBProvider.Instance.buyersRef.child(thisBuyerID).child("data").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                if(value?["rating"] != nil) {
                    self.currentRating = value?["rating"] as? String ?? ""
                } else {
                    self.currentRating = "3"
                }
                
                self.currentRatinglabel.text = self.currentRating
                
                if (value?["nRatings"] != nil) {
                    self.nRatings = value?["nRatings"] as! Int
                } else {
                    self.nRatings = 1
                }
                
                self.nRatingsLabel.text = String(self.nRatings)
                
                if(value?["name"] != nil) {
                    self.thisBuyerName = (value?["name"] as? String)!
                } else {
                    self.thisBuyerName = "name"
                }
                
                self.thisBuyerNameLabel.text = self.thisBuyerName
                
                if(value?["email"] != nil) {
                    self.thisBuyerEmail = (value?["email"] as? String)!
                } else {
                    self.thisBuyerEmail = "email"
                }
                
                self.thisBuyerEmailLabel.text = self.thisBuyerEmail
                
            }) { (error) in print(error.localizedDescription) }
            
        } else {
            alertTheUser(title: "Missing Buyer ID", message: "Missing the Buyer's ID, so can't do the rating")
        }
        
        
    }
    
    func validateInput(x: String) -> Bool {
        if let intValue = Int(x) {
            if (intValue >= 1 && intValue <= 5) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    @IBAction func minusOne() {
        var inputValue  = Int(thisRating.text!)!;
        inputValue -= 1;
        if(inputValue <= 1) {
            inputValue = 1;
        }
        thisRating.text = String(inputValue);
    }
    
    @IBAction func plusOne() {
        var inputValue  = Int(thisRating.text!)!;
        inputValue += 1;
        if(inputValue >= 5) {
            inputValue = 5
        }
        thisRating.text = String(inputValue);
    }
    
    @IBAction func submitRating() {
        
        let inputValue = thisRating.text // Force unwrapping because we know it exists.
        
        if (self.validateInput(x: (inputValue)!) && thisBuyerID != "") {
            let newRating = Int((inputValue)!)
            let updateRating = (Double(nRatings) * Double(currentRating)! + Double(newRating!) )/(Double(nRatings) + 1)
            let updateNRatings = nRatings + 1
            
            DBProvider.Instance.buyersRef.child(thisBuyerID).child("data").updateChildValues(["rating": String(updateRating)])
            DBProvider.Instance.buyersRef.child(thisBuyerID).child("data").updateChildValues(["nRatings": updateNRatings])
        } else {
            self.alertTheUser(title: "Ratings Input Error", message: "Rating must be 1, 2, 3, 4, or 5")
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }


}
