//
//  ProfileHeaderView.swift
//  Makestagram
//
//  Created by Allen Lai on 7/1/17.
//  Copyright © 2017 Allen Lai. All rights reserved.
//

import UIKit

protocol ProfileHeaderViewDelegate: class {
    func didTapSettingsButton(_ button: UIButton, on headerView: ProfileHeaderView)
}

class ProfileHeaderView: UICollectionReusableView {
    
    weak var delegate: ProfileHeaderViewDelegate?

    // MARK: - Subviews
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var followerCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        settingsButton.layer.cornerRadius = 6
        settingsButton.layer.borderColor = UIColor.lightGray.cgColor
        settingsButton.layer.borderWidth = 1
        
    }

    // MARK: - IBAction

    @IBAction func settingsButtonTapped(_ sender: Any) {
        delegate?.didTapSettingsButton(sender as! UIButton, on: self)

    }
    
    
    
}
