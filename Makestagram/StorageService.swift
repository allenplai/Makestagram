//
//  StorageService.swift
//  Makestagram
//
//  Created by Allen Lai on 6/8/17.
//  Copyright © 2017 Allen Lai. All rights reserved.
//

import UIKit
import FirebaseStorage


struct StorageService {
    
    static func uploadImage(_ image: UIImage, at reference: StorageReference, completion: @escaping (URL?) -> Void) {
        
        // Change the UIImage to Data
        guard let imageData = UIImageJPEGRepresentation(image, 0.1) else {
            return completion(nil)
        }
        
        
        reference.putData(imageData, metadata: nil, completion: { (metadata, error) in
            //
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
            
            
            completion(metadata?.downloadURL())
        })
    }

}


