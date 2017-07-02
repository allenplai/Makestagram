//
//  Post.swift
//  Makestagram
//
//  Created by Allen Lai on 6/8/17.
//  Copyright © 2017 Allen Lai. All rights reserved.
//

import Foundation


import UIKit
import FirebaseDatabase.FIRDataSnapshot
import FirebaseStorage

class Post: MGKeyed {
    var key: String?
    let imageURL: String
    let imageHeight: CGFloat
    let creationDate: Date

    // for the Like feature
    var likeCount: Int
    let poster: User
    
    var isLiked = false
    
    init(imageURL: String, imageHeight: CGFloat) {
        self.imageURL = imageURL
        self.imageHeight = imageHeight
        self.creationDate = Date()
        
        self.likeCount = 0
        self.poster = User.current
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let imageURL = dict["image_url"] as? String,
            let imageHeight = dict["image_height"] as? CGFloat,
            let createdAgo = dict["created_at"] as? TimeInterval,
            let likeCount = dict["like_count"] as? Int,
            let userDict = dict["poster"] as? [String : Any],
            let uid = userDict["uid"] as? String,
            let username = userDict["username"] as? String
            else { return nil }
        
        self.key = snapshot.key
        self.imageURL = imageURL
        self.imageHeight = imageHeight
        self.creationDate = Date(timeIntervalSince1970: createdAgo)
        
        self.likeCount = likeCount
        self.poster = User(uid: uid, username: username)
    }

    var dictValue: [String : Any] {
        let createdAgo = creationDate.timeIntervalSince1970
        let userDict = ["uid" : poster.uid,
                        "username" : poster.username]
        
        return ["image_url" : imageURL,
                "image_height" : imageHeight,
                "created_at" : createdAgo,
                "like_count" : likeCount,
                "poster" : userDict]
    }
    
    private static func create(forURLString urlString: String, aspectHeight: CGFloat) {
        let currentUser = User.current
        // 2
        let post = Post(imageURL: urlString, imageHeight: aspectHeight)
        // 3
        let dict = post.dictValue
        // 4
        let postRef = Database.database().reference().child("posts").child(currentUser.uid).childByAutoId()
        //5
        postRef.updateChildValues(dict)
    }
    
//    static func create(for image: UIImage) {
//        let imageRef = Storage.storage().reference().child("test_image.jpg")
//        StorageService.uploadImage(image, at: imageRef) { (downloadURL) in
//            guard let downloadURL = downloadURL else {
//                return
//            }
//            
//            let urlString = downloadURL.absoluteString
//            create(forURLString: urlString, aspectHeight: 320)
//        }
//    }
    
    static func create(for image: UIImage) {
        let imageRef = StorageReference.newPostImageReference()
        StorageService.uploadImage(image, at: imageRef) { (downloadURL) in
            guard let downloadURL = downloadURL else {
                return
            }
            
            let urlString = downloadURL.absoluteString
            let aspectHeight = image.aspectHeight
            create(forURLString: urlString, aspectHeight: aspectHeight)
        }
    }


}




