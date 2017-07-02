//
//  PostHeaderCell.swift
//  Makestagram
//
//  Created by Allen Lai on 6/9/17.
//  Copyright © 2017 Allen Lai. All rights reserved.
//

import UIKit

class PostHeaderCell: UITableViewCell {

    
    static let height: CGFloat = 54

    
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func optionsButtonTapped(_ sender: Any) {
    }

}
