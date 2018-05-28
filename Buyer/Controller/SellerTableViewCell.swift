//
//  TableVCTableViewCell.swift
//  Seller
//
//  Created by William J. Wolfe on 3/13/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit

class SellerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myAmount: UILabel!
    @IBOutlet weak var myDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    
}
