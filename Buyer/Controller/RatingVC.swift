//
//  RatingVC.swift
//  Buyer
//
//  Created by William J. Wolfe on 6/7/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit

class RatingVC: UIViewController {
    
    public var thisSellerID = ""
    public var currentRating = ""
    public var nRatings = 1
    public var thisRatingValue = ""
    public var thisSellerName = ""
    public var thisSellerEmail = ""
    
    
    @IBOutlet weak var thisRating: UILabel!
    
    @IBOutlet weak var thisSellerNameLabel: UILabel!
   
    @IBOutlet weak var currentRatinglabel: UILabel!
    
    @IBOutlet weak var nRatingsLabel: UILabel!
    
    @IBOutlet weak var thisSellerEmailLabel: UILabel!
    
    @IBOutlet weak var thisSellerIDLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Rate This Seller"
        print("thisSellerID = \(thisSellerID)")
        thisSellerIDLabel.text = thisSellerID
        thisRating.text = "3"
        
        if (thisSellerID != "") {
            DBProvider.Instance.sellersRef.child(thisSellerID).child("data").observeSingleEvent(of: .value, with: { (snapshot) in
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
                    self.thisSellerName = (value?["name"] as? String)!
                } else {
                    self.thisSellerName = "name"
                }
            
                self.thisSellerNameLabel.text = self.thisSellerName
            
                if(value?["email"] != nil) {
                    self.thisSellerEmail = (value?["email"] as? String)!
                } else {
                    self.thisSellerEmail = "email"
                }
            
                self.thisSellerEmailLabel.text = self.thisSellerEmail
            
            }) { (error) in print(error.localizedDescription) }
        
            } else {
                alertTheUser(title: "Missing Seller ID", message: "Missing the Seller's ID, so can't do the rating")
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
        
        if (self.validateInput(x: (inputValue)!) && thisSellerID != "") {
            let newRating = Int((inputValue)!)
            let updateRating = (Double(nRatings) * Double(currentRating)! + Double(newRating!) )/(Double(nRatings) + 1)
            let updateNRatings = nRatings + 1
            
            DBProvider.Instance.sellersRef.child(thisSellerID).child("data").updateChildValues(["rating": String(updateRating)])
            DBProvider.Instance.sellersRef.child(thisSellerID).child("data").updateChildValues(["nRatings": updateNRatings])
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
