//
//  SellerAuctionList.swift
//  Buyer
//
//  Created by William J. Wolfe on 6/4/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit
import CoreData


class SellerAuctionList: UITableViewController {

    var item_description = ""
    var item_price = ""
    var post_date = ""
    var buyer_id = ""
    var purchase_date = ""
    var status = ""
    
    var offerings_list = [NSManagedObject]()
    
    @IBAction func deleteAll(_ sender: Any) {
        confirmDeleteAllSales()
    }
    
    @IBOutlet weak var myTableView: UITableView!
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return offerings_list.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SellerAuctionCell
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 67/255, green: 96/255, blue: 179/255, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        //cell.myImage.image = UIImage(named: "sell.png")
        //cell.myImage.image = UIImage(named: "sell.png")
        
        //item description
        let x = offerings_list[indexPath.row]
        cell.myDescription?.text = x.value(forKey: "item_description") as? String
        
        //item price
        //let a = offerings_list[indexPath.row]
        let aInt = x.value(forKey: "item_price") as! String
        var amount:Int? = Int(aInt)
        amount = amount!/100
        cell.myAmount.text = "$" + String(amount!)
        
        // item post date
        //let d = offerings_list[indexPath.row]
        print("Trying to print the post date: \(x.value(forKey: "post_date")!)")
        //cell.myDate?.text = String(describing: d.value(forKey: "post_date")!)
        let shorter_date  = String(describing: x.value(forKey: "post_date")!).prefix(19)
        cell.myDate?.text = String(shorter_date)
        
        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 95.0;//Choose your custom row height
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        let context = getContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SellerItem")
        
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
            print("error in ViewWillAppear, SellerAuctionList")
        }
    }
    
    @IBAction func backBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    func getContext() -> NSManagedObjectContext  {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        return context
    }
    
    func cleanCoreData() {
        let fetchRequest:NSFetchRequest<SellerItem> = SellerItem.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        
        do {
            print("deleting all contents of SellerItem")
            try getContext().execute(deleteRequest)
        }
        catch {
            print(error.localizedDescription)
        }
        
        offerings_list.removeAll()
        myTableView.reloadData()
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        let item_description = offerings_list[indexPath.row].value(forKey: "item_description") as? String
        let item_price = offerings_list[indexPath.row].value(forKey: "item_price") as? String
        
        let alert = UIAlertController(
            title:      "Action On Row Item",
            message:    "What do you want to do with this item?",
            preferredStyle: .alert);
        
        let accept = UIAlertAction(
            title: "Delete This Item",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                self.deleteRowFromSellerItem(x: item_description!, index: indexPath.row)
        });
        
        let cancel = UIAlertAction(
            title: "Cancel",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                print("canceled the delete operation")
        });
        
        
        let put_up_for_sale = UIAlertAction(
            title: "Auction This Item",
            style: .default,
            handler: { (alertAction: UIAlertAction) in
                self.putItemUpForSale(x: item_description!, y: item_price!, index: indexPath.row)
        });
        
        alert.addAction(accept);
        alert.addAction(put_up_for_sale);
        alert.addAction(cancel);
        present(alert, animated: true, completion: nil);
        
    }
    
    func deleteRowFromSellerItem(x: String, index: Int) {
        print("got into delete row from item, index = \(index)")
        let context = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SellerItem")
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
        print("in putItemUpForSale: auction_in_progress = \(Seller_AuctionHandler.Instance.auction_in_progress)")
        if (Seller_AuctionHandler.Instance.auction_in_progress) {
            alertTheUser(title: "You Are In An Active Auction", message: "Please return to the Seller Home view and cancel the active auction before putting a new item up for sale")
        } else {
            Seller_AuctionHandler.Instance.item_description = x
            Seller_AuctionHandler.Instance.min_price_cents = y
            self.navigationController?.popViewController(animated: true)
            //dismiss(animated: true, completion: nil)
        }
        //dismiss(animated: true, completion: nil)
    }
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }
    
    
    
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
}
