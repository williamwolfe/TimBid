//
//  SellerAuctionCell.swift
//  Buyer
//
//  Created by William J. Wolfe on 6/4/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit

class SellerAuctionCell: UITableViewCell {

    @IBOutlet weak var myAmount: UILabel!
    @IBOutlet weak var myDescription: UILabel!
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
