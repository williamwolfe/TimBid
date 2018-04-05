//
//  Sale.swift
//  Buyer
//
//  Created by William J. Wolfe on 3/21/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit

class Sale: UITableViewCell {

    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var myAmount: UILabel!
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myDate: UILabel!
    
    @IBOutlet weak var star1: UIButton!
    @IBOutlet weak var star2: UIButton!
    @IBOutlet weak var star3: UIButton!
    @IBOutlet weak var star4: UIButton!
    @IBOutlet weak var star5: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
