//
//  UITableView+Utility.swift
//  Makestagram
//
//  Created by Allen Lai on 6/9/17.
//  Copyright © 2017 Allen Lai. All rights reserved.
//

import UIKit

// We create an extension on our protocol CellIdentifiable. In our extension, we can define default values for our protocol properties and functions.
extension CellIdentifiable where Self: UITableViewCell {
    static var cellIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: CellIdentifiable {

}


protocol CellIdentifiable {
    static var cellIdentifier: String { get }
}

extension UITableView {
    
    func dequeueReusableCell<T: UITableViewCell>() -> T where T: CellIdentifiable {
        guard let cell = dequeueReusableCell(withIdentifier: T.cellIdentifier) as? T else {
            fatalError("Error dequeuing cell for identifier \(T.cellIdentifier)")
        }
        return cell
    }
    
}
