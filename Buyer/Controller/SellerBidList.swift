//
//  SellerBidList.swift
//  Seller
//
//  Created by William J. Wolfe on 3/23/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit
import CoreData
import FirebaseDatabase

class SellerBidList: UITableViewController {
    var thisBuyerID = ""
    
    var bid_list = [NSManagedObject]()
    
    @IBOutlet var myTableView: UITableView!
    
    @IBAction func deleteAll(_ sender: Any) {
        confirmDeleteAllBids()
        
    }
    
    //confirmDeleteAllBids()
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let context = getContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SellerBid")
        let sort = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sort]
        request.returnsObjectsAsFaults = false
        
        do
        {
            let results = try context.fetch(request)
            print("results count = \(results.count)")
            if results.count > 0
            {
                bid_list = results as! [NSManagedObject]
                print("bid list count =\(bid_list.count)")
                for result in results as! [NSManagedObject]
                {
                    if let bid_buyer_id = result.value(forKey: "buyer_id") as? String
                    {
                        print("bid buyer_id:")
                        print(bid_buyer_id)
                    }
                    if let bid_item_description = result.value(forKey: "item_description") as? String
                    {
                        print("bid item_description is:")
                        print(bid_item_description)
                    }
                    
                    if let bid_buyer_name = result.value(forKey: "buyer_name") as? String
                    {
                        print("bid buyer_name is:")
                        print(bid_buyer_name)
                    }
                }
            } else {
                print("results.count = 0")
            }
        }
        catch
        {
            print("error in SaleBidList ViewWillAppear, TableVC")
        }
        myTableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DBProvider.Instance.dbRef.removeAllObservers()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return bid_list.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bid_cell", for: indexPath) as! SellerBidCell
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        //cell.bidImage.image = UIImage(named: "sell.png")
        
        let x = bid_list[indexPath.row]
        
        //item description
        cell.itemDescription?.text = x.value(forKey: "item_description") as? String
        
        let price = x.value(forKey: "min_price") as? String
        let price_cents = Int(price!)!/100
        let buyer_name = x.value(forKey: "buyer_name") as? String
        //cell.amount?.text = "$" + String(price_cents) + " " + buyer_name!
        cell.amount?.text = "$" + String(price_cents)
        
        let buyer_id = x.value(forKey: "buyer_id")
        // item post date
        let shorter_date  = String(describing: x.value(forKey: "date")!).prefix(19)
        cell.date?.text = String(shorter_date)
        
        ///////get rating and number of ratings for this buyer_id:
        var currentRating = ""
        var nRatings = 1
        DBProvider.Instance.buyersRef.child(buyer_id as! String).child("data").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if(value?["rating"] != nil) {
                currentRating = value?["rating"] as? String ?? ""
            } else {
                currentRating = "4"
            }
            
            if (value?["nRatings"]) != nil {
                nRatings = value?["nRatings"] as! Int
            } else {
                nRatings = 1
            }
            
            let star_array: [UIButton] = [cell.star1, cell.star2, cell.star3, cell.star4, cell.star5]
            
            var i = 0;
            while i < 5 {
                print("i = \(i)")
                star_array[i].setImage(#imageLiteral(resourceName: "star_clear_20x20"), for: .normal)
                i = i + 1
            }
            
            if let currentRatingFloat = Float(currentRating) {
                let currentRatingTwoDecimals = (currentRatingFloat * 100).rounded() / 100
                cell.Rating?.text = String(currentRatingTwoDecimals) + " (" + String(nRatings) + ")"
                let currentRatingRounded = currentRatingFloat.rounded()
                let currentRatingInt = Int(currentRatingRounded)
                let n_stars = currentRatingInt
                i = 0;
                while i < n_stars {
                    print("i = \(i)")
                    star_array[i].setImage(#imageLiteral(resourceName: "star_dark_20x20"), for: .normal)
                    i = i + 1
                }
            } else {
                print("could not convert current rating to a float")
            }
            
        }) { (error) in print(error.localizedDescription) }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        let item_description = bid_list[indexPath.row].value(forKey: "item_description") as? String
        let item_price = bid_list[indexPath.row].value(forKey: "min_price") as? String
        let buyer_id = bid_list[indexPath.row].value(forKey: "buyer_id") as? String
        print("buyer id = \(String(describing: buyer_id))")
        thisBuyerID = buyer_id!
        
        
        
        let alert = UIAlertController(
            title:      "Action On Row Item",
            message:    "What do you want to do with this item?",
            preferredStyle: .alert);
        
        let accept = UIAlertAction(
            title: "Delete This Item",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                self.deleteRowFromItem(x: item_description!, index: indexPath.row)
        });
        
        let cancel = UIAlertAction(
            title: "Cancel",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                print("canceled the delete operation")
        });
        
        
        let put_up_for_sale = UIAlertAction(
            title: "Accept the Bid Price",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                self.putItemUpForSale(x: item_description!, y: item_price!, index: indexPath.row)
        });
        
        let enter_rating = UIAlertAction(
            title: "Rate This Buyer",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                self.performSegue(withIdentifier: "SellerRatingBuyerSegue", sender: nil)
                //self.rateThisBuyer(thisBuyerID: buyer_id!)
        });
        
        alert.addAction(accept);
        alert.addAction(put_up_for_sale);
        alert.addAction(enter_rating);
        alert.addAction(cancel);
        present(alert, animated: true, completion: nil);
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is SellerRatingBuyerVC
        {
            let vc = segue.destination as? SellerRatingBuyerVC
            vc?.thisBuyerID = thisBuyerID
        }
    }
    
    func rateThisBuyer(thisBuyerID: String) {
        var currentRating = ""
        var nRatings = 1
        
        print("inside the rateThisSeller function, thisBuyerID = \(thisBuyerID)")
        //use thisSellerID to get the current average rating and number of ratings.
        //then pop up a request for the new rating: 1 - 5
        //then compute the new average rating
        //then update the seller record in Firebase
        
        DBProvider.Instance.buyersRef.child(thisBuyerID).child("data").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if(value?["rating"] != nil) {
                currentRating = value?["rating"] as? String ?? ""
            } else {
                currentRating = "4"
            }
            
            if (value?["nRatings"]) != nil {
                nRatings = value?["nRatings"] as! Int
            } else {
                nRatings = 1
            }
            
        }) { (error) in print(error.localizedDescription) }
        
        //Now need a pop up to get the new rating.
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Submit Rating", message: "Please enter a rating (1-5) for this Buyer", preferredStyle: .alert)
        //2. Add the text field.
        alert.addTextField { (textField) in textField.text = "rating (1-5)" }
        alert.addAction(UIAlertAction(title: "Enter Rating", style: .default, handler: {
            [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            //let newRating = Int((textField?.text)!)
            if (self.validateInput(x: (textField?.text)!)) {
                let newRating = Int((textField?.text)!)
                let updateRating = (Double(nRatings) * Double(currentRating)! + Double(newRating!) )/(Double(nRatings) + 1)
                let updateNRatings = nRatings + 1
                
                DBProvider.Instance.buyersRef.child(thisBuyerID).child("data").updateChildValues(["rating": String(updateRating)])
                DBProvider.Instance.buyersRef.child(thisBuyerID).child("data").updateChildValues(["nRatings": updateNRatings])
                
            } else {
                print("input value could not be validated as between 1 and 5")
                self.alertTheUser(title: "Ratings Input Error", message: "Rating must be an integer from 1 to 5")
            }
        }))
        
        let cancel = UIAlertAction(
            title: "Cancel",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                print("canceled the rating entry")
        });
        
        alert.addAction(cancel);
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
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
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func getContext() -> NSManagedObjectContext  {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        return context
    }
    
    func cleanCoreData() {
        
        print("got into confirm delete all -- should be deleting all bids")
        let fetchRequest:NSFetchRequest<SellerBid> = SellerBid.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        
        do {
            
            try getContext().execute(deleteRequest)
        }
        catch {
            print(error.localizedDescription)
        }
        bid_list.removeAll()
        myTableView.reloadData()
        
    }
    
    func confirmDeleteAllBids() {
        
        let alert = UIAlertController(
            title:      "Delete All Items",
            message:    "Are you sure you want to delete all items in this list?",
            preferredStyle: .alert);
        
        let accept = UIAlertAction(
            title: "Yes, delete all items in this list",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                self.cleanCoreData()
                
        });
        
        let cancel = UIAlertAction(
            title: "Cancel",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                print("canceled the delete all")
        });
        
        alert.addAction(accept);
        alert.addAction(cancel);
        present(alert, animated: true, completion: nil);
    }
    
    func deleteRowFromItem(x: String, index: Int) {
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SellerBid")
        let descriptionPredicate = NSPredicate(format: "%K = %@", "item_description", x)
        fetchRequest.predicate = descriptionPredicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
        }
        catch {
            print("error deleting data")
        }
        
        bid_list.remove(at: index)
        myTableView.reloadData()
    }
    
    func putItemUpForSale(x: String, y: String, index: Int) {
        print("in putItemUpForSale: auction_in_progress = \(Seller_AuctionHandler.Instance.auction_in_progress)")
        if (Seller_AuctionHandler.Instance.auction_in_progress) {
            alertTheUser(title: "You Are In An Active Auction", message: "Please return to the Seller Home view and cancel the active auction before accepting this bid")
        } else {
            Seller_AuctionHandler.Instance.item_description = x
            Seller_AuctionHandler.Instance.min_price_cents = y
            self.navigationController?.popToRootViewController(animated: true)
            //dismiss(animated: true, completion: nil)
        }
        //dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }
    
}
