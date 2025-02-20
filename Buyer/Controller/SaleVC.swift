//
//  SaleVC.swift
//  Buyer
//
//  Created by William J. Wolfe on 3/21/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseStorage
import FirebaseDatabase


class SaleVC: UITableViewController {
    
    var thisSellerID = ""
    var offerings_list = [NSManagedObject]()
    
    @IBOutlet var myTableView: UITableView!
    
    @IBAction func deleteAll(_ sender: Any) {
        confirmDeleteAllSales()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTableView.rowHeight = 95

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //let request = Commit.createFetchRequest()
        //let sort = NSSortDescriptor(key: "date", ascending: false)
        //request.sortDescriptors = [sort]
        
        let context = getContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
        
        let sort = NSSortDescriptor(key: "post_date", ascending: false)
        request.sortDescriptors = [sort]
        
        request.returnsObjectsAsFaults = false
        
        do
        {
            let results = try context.fetch(request)
            if results.count > 0
            {
                offerings_list = results as! [NSManagedObject]
                for result in results as! [NSManagedObject]
                {
                    if let post_date = result.value(forKey: "post_date") as? Date
                    {
                        print("post_date is:")
                        print(post_date)
                    }
                    if let item_description = result.value(forKey: "item_description") as? String
                    {
                        print("item_description is:")
                        print(item_description)
                    }
                }
            } else {
                print("results.count = 0")
            }
        }
        catch
        {
            print("error in Buyer: SaleVC ViewWillAppear, TableVC")
        }
    }
    
    func getContext() -> NSManagedObjectContext  {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        return context
    }
    
    func cleanCoreData() {
        let fetchRequest:NSFetchRequest<Item> = Item.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        
        do {
            print("deleting all contents")
            try getContext().execute(deleteRequest)
        }
        catch {
            print(error.localizedDescription)
        }
        
        offerings_list.removeAll()
        myTableView.reloadData()
    }
    


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return offerings_list.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Sale", for: indexPath) as! Sale
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        //item description
        let x = offerings_list[indexPath.row]
        
        cell.myLabel?.text = x.value(forKey: "item_description") as? String
        
        //item price
        //let a = offerings_list[indexPath.row]
        let aInt = x.value(forKey: "item_price") as! String
        var amount:Int? = Int(aInt)
        amount = amount!/100
        
        let seller_id = x.value(forKey: "seller_identifier")
        
        cell.myAmount.text = "$" + String(amount!)
        
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd,yyyy"
        cell.myDate?.text = dateFormatterPrint.string(from: x.value(forKey: "post_date") as! Date)
        /////////////////////////////////
        
        
        ///////get rating and number of ratings for this seller_id:
        var currentRating = ""
        var nRatings = 1
       
        
        DBProvider.Instance.sellersRef.child(seller_id as! String).child("data").observeSingleEvent(of: .value, with: { (snapshot) in
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
            
            if let profileImageUrl = value?["profileImageUrl"] {
                cell.imageView?.loadImageUsingCacheWithUrlString(profileImageUrl as! String)
                /*
                let storageRef = Storage.storage().reference(forURL: profileImageUrl as! String)
                storageRef.downloadURL(completion: { (url, error) in
                    
                   do {
                        let data = try Data(contentsOf: url!)
                        let image = UIImage(data: data as Data)
                        cell.imageView?.image = image

                    } catch {
                        print(error)
                    }
                })
                */
                
                
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
        
        if (cell.imageView?.image == nil) {
             cell.imageView?.image = UIImage(named: "female_buyer")
        }
       
        cell.imageView?.layer.cornerRadius = (cell.imageView?.image?.size.width)!/2;
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 1.0;
        cell.imageView?.layer.borderColor =  UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        //cell.imageView?.contentMode = .scaleAspectFill
        //cell.imageView?.translatesAutoresizingMaskIntoConstraints = false
        //cell.imageView?.layer.masksToBounds = true
        
        //green_circle_check: bought by buyer: 0
        //red_x: buyer not interested, rejected the auction first time it showed up: 1
        //green_open: buyer accepted the auction, but it was ultimately canceled by buyer or seller: 2
        //blue_pause: in the negotiation phase, pending: 3
        
        ///print("8888 status = \(String(describing: Int(x.value(forKey: "status") as! String) ))")

        if (x.value(forKey: "status") != nil) {
            if let myInt = Int(x.value(forKey: "status") as! String) {
               
                switch myInt {
                case 0:
                    cell.statusImage.image = UIImage(named: "green_circle_check")
                    
                case 1:
                    cell.statusImage.image = UIImage(named: "red_x_transparent")
                    
                case 2:
                    cell.statusImage.image = UIImage(named: "green_open_transparent")
                    
                case 3:
                    cell.statusImage.image = UIImage(named: "blue_pause")
                    
                default:
                    
                    cell.statusImage.image = UIImage(named: "green_open_transparent")
                }
            }  else {
                cell.statusImage.image = UIImage(named: "green_open_transparent")
            }
        } else {
             cell.statusImage.image = UIImage(named: "green_open_transparent")
        }
 
        print("status = \(String(describing: x.value(forKey: "status") ))")
        //cell.statusImage.image = UIImage(named: "green_open_transparent")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        let item_description = offerings_list[indexPath.row].value(forKey: "item_description") as? String
        let item_price = offerings_list[indexPath.row].value(forKey: "item_price") as? String
        let seller_identifier = offerings_list[indexPath.row].value(forKey: "seller_identifier") as? String
        thisSellerID = seller_identifier!
        
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
            title: "Bid On This Item",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                self.submitBid(x: item_description!, y: item_price!, z: seller_identifier!, index: indexPath.row)
        });
        
        let enter_rating = UIAlertAction(
            title: "Rate This Seller",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                self.performSegue(withIdentifier: "RatingSegue", sender: nil)
                
        });
        
        alert.addAction(accept);
        alert.addAction(put_up_for_sale);
        alert.addAction(enter_rating);
        alert.addAction(cancel);
        present(alert, animated: true, completion: nil);
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is RatingVC
        {
            let vc = segue.destination as? RatingVC
            print("got into the prepar for segue")
            vc?.thisSellerID = thisSellerID
        }
    }
 
    func deleteRowFromItem(x: String, index: Int) {
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
        let descriptionPredicate = NSPredicate(format: "%K = %@", "item_description", x)
        fetchRequest.predicate = descriptionPredicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
        }
        catch {
            print("error deleting data")
        }
        
        offerings_list.remove(at: index)
        myTableView.reloadData()
    }
    
    func putItemUpForSale(x: String, y: String, index: Int) {
        print("trying to put item \(x) at index \(index) up for sale")
        AuctionHandler.Instance.item_description = x
        AuctionHandler.Instance.min_price_cents = y
        dismiss(animated: true, completion: nil)
        //to do this, need to set the item_description and min_price in the text fields in SellerVC
    }
    
    func submitBid(x: String, y: String, z: String, index: Int) {

        //set these variables as local variables, to avoid collision with auction handler values
        let bid_item_description = x
        var bid_min_price_cents = y
        let bid_seller_id = z

        //1. Create the alert controller.
        let alert = UIAlertController(title: "Submit Bid", message: "Item: \(bid_item_description), current price = $\(Int(y)!/100)", preferredStyle: .alert)
        
        //2. Add the text field.
        alert.addTextField { (textField) in textField.text = "amount (dollars)" }
        
        alert.addAction(UIAlertAction(title: "Bid on this Item", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("Text field: \(String(describing: textField?.text))")
            if self.isStringAnInt(string: (textField?.text)!) {
                if let dollars = Int((textField?.text)!)  {
                    let number_of_pennies = dollars * 100
                    print("cents = \(number_of_pennies)")
                    //AuctionHandler.Instance.min_price_cents = String(number_of_pennies)
                    bid_min_price_cents = String(number_of_pennies)
                } else {
                    print("could not convert string \((textField?.text)!) to an integer")
                    self.alertTheUser(title: "Problem with input", message: "The dollar amount must be a whole number of dollars, no cents, and not other characters (example: 50)")
                    return
                }
            } else {
                print("text field is not an int")
                self.alertTheUser(title: "Problem with input", message: "The dollar amount must be a whole number of dollars, no cents, and no other characters (example: 50)")
                return
            }
            print("bid item_description = \(bid_item_description)")
            print("bid price in cents  = \(bid_min_price_cents)")
            print("bid buyer_name  = \(AuctionHandler.Instance.buyer)")
            print("bid buyer_id  = \(AuctionHandler.Instance.buyer_id)")
            print("bid seller_id  = \(bid_seller_id)")
            
            let data: Dictionary<String, Any> =
                [
                 Constants.DESCRIPTION: bid_item_description,
                 Constants.MIN_PRICE: bid_min_price_cents,
                 Constants.BUYER_ID: AuctionHandler.Instance.buyer_id,
                 Constants.SELLER_ID: bid_seller_id,
                 Constants.BUYER_NAME: AuctionHandler.Instance.buyer
                 ];
            
            DBProvider.Instance.bidRef.childByAutoId().setValue(data);
        }))
        
        let cancel = UIAlertAction(
            title: "Cancel",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                print("canceled the delete all")
        });
        
        alert.addAction(cancel);
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
        
        
    }
    
    func isStringAnInt(string: String) -> Bool {
        return Int(string) != nil
    }
    
    @IBAction func backBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
    
    func confirmDeleteAllSales() {
        
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
    
    
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }

}
