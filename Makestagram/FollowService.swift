//
//  FollowService.swift
//  Makestagram
//
//  Created by Allen Lai on 6/9/17.
//  Copyright © 2017 Allen Lai. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct FollowService {
    
//    private static func followUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
//        let currentUID = User.current.uid
//        let followData = ["followers/\(user.uid)/\(currentUID)" : true,
//                          "following/\(currentUID)/\(user.uid)" : true]
//        
//        let ref = DatabaseReference.toLocation(.root)
//        ref.updateChildValues(followData) { (error, _) in
//            if let error = error {
//                assertionFailure(error.localizedDescription)
//                success(false)
//            }
//            
//            // 1    -- get all their posts and add them from your timeline
//            UserService.posts(for: user) { (posts) in
//                // 2    -- Next we get all of the post keys for that user's posts. This will allow us to write each post to our own timeline
//                let postKeys = posts.flatMap { $0.key }
//                
//                // 3  -- We build a multiple location update using a dictionary that adds each of the followee's post to our timeline.
//                var followData = [String : Any]()
//                let timelinePostDict = ["poster_uid" : user.uid]
//                postKeys.forEach { followData["timeline/\(currentUID)/\($0)"] = timelinePostDict }
//                
//                // 4    -- We write the dictionary to our database
//                ref.updateChildValues(followData, withCompletionBlock: { (error, ref) in
//                    if let error = error {
//                        assertionFailure(error.localizedDescription)
//                    }
//                    
//                    // 5
//                    success(error == nil)
//                })
//            }
//        }
//    }
    // add the follow count feature
    private static func followUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let followData = ["followers/\(user.uid)/\(currentUID)" : true,
                          "following/\(currentUID)/\(user.uid)" : true]
        
        let ref = Database.database().reference()
        ref.updateChildValues(followData) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                success(false)
            }
            // We created a dispatch group to manage the completion of asynchronous requests.
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            let followingCountRef = Database.database().reference().child("users").child(currentUID).child("following_count")
            followingCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount + 1
                
                return TransactionResult.success(withValue: mutableData)
            })
            
            // save thing for current user's follower_count.
            dispatchGroup.enter()
            let followerCountRef = Database.database().reference().child("users").child(user.uid).child("follower_count")
            followerCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount + 1
                
                return TransactionResult.success(withValue: mutableData)
            })
            
            // for timeline
            dispatchGroup.enter()
            
            // 1    -- get all their posts and add them from your timeline
            UserService.posts(for: user) { (posts) in
                let postKeys = posts.flatMap { $0.key }
                
                var followData = [String : Any]()
                let timelinePostDict = ["poster_uid" : user.uid]
                postKeys.forEach { followData["timeline/\(currentUID)/\($0)"] = timelinePostDict }
                
                ref.updateChildValues(followData, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                    }
                    
                    dispatchGroup.leave()
                })
            }
            
            // 7
            dispatchGroup.notify(queue: .main) {
                success(true)
            }
        }
    }
    
    
    private static func unfollowUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        // Use NSNull() object instead of nil because updateChildValues expects type [Hashable : Any]
        // http://stackoverflow.com/questions/38462074/using-updatechildvalues-to-delete-from-firebase
        let followData = ["followers/\(user.uid)/\(currentUID)" : NSNull(),
                          "following/\(currentUID)/\(user.uid)" : NSNull()]
        
        let ref = Database.database().reference()
        ref.updateChildValues(followData) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return success(false)
            }
            
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            let followingCountRef = Database.database().reference().child("users").child(currentUID).child("following_count")
            followingCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount - 1
                
                return TransactionResult.success(withValue: mutableData)
            })
            
            dispatchGroup.enter()
            let followerCountRef = Database.database().reference().child("users").child(user.uid).child("follower_count")
            followerCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount - 1
                
                return TransactionResult.success(withValue: mutableData)
            })
            
            dispatchGroup.enter()
            UserService.posts(for: user, completion: { (posts) in
                var unfollowData = [String : Any]()
                let postsKeys = posts.flatMap { $0.key }
                postsKeys.forEach {
                    // Use NSNull() object instead of nil because updateChildValues expects type [Hashable : Any]
                    unfollowData["timeline/\(currentUID)/\($0)"] = NSNull()
                }
                
                ref.updateChildValues(unfollowData, withCompletionBlock: { (error, ref) in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                    }
                    
                    dispatchGroup.leave()
                })
            })
            
            dispatchGroup.notify(queue: .main) {
                success(true)
            }
        }
    }
//    private static func unfollowUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
//        let currentUID = User.current.uid
//        // Use NSNull() object instead of nil because updateChildValues expects type [Hashable : Any]
//        // http://stackoverflow.com/questions/38462074/using-updatechildvalues-to-delete-from-firebase
//        let followData = ["followers/\(user.uid)/\(currentUID)" : NSNull(),
//                          "following/\(currentUID)/\(user.uid)" : NSNull()]
//        
////        let ref = Database.database().reference()
//        let ref = DatabaseReference.toLocation(.root)
//        ref.updateChildValues(followData) { (error, ref) in
//            if let error = error {
//                assertionFailure(error.localizedDescription)
//                return success(false)
//            }
//            
//            // delete all the posts from users timeline
//            UserService.posts(for: user, completion: { (posts) in
//                var unfollowData = [String : Any]()
//                let postsKeys = posts.flatMap { $0.key }
//                postsKeys.forEach {
//                    // Use NSNull() object instead of nil because updateChildValues expects type [Hashable : Any]
//                    unfollowData["timeline/\(currentUID)/\($0)"] = NSNull()
//                }
//                
//                ref.updateChildValues(unfollowData, withCompletionBlock: { (error, ref) in
//                    if let error = error {
//                        assertionFailure(error.localizedDescription)
//                    }
//                    
//                    success(error == nil)
//                })
//            })
//        }
//    }
    
    

    static func setIsFollowing(_ isFollowing: Bool, fromCurrentUserTo followee: User, success: @escaping (Bool) -> Void) {
        if isFollowing {
            followUser(followee, forCurrentUserWithSuccess: success)
        } else {
            unfollowUser(followee, forCurrentUserWithSuccess: success)
        }
    }
    
    // checks if the user is followed by current user.
    static func isUserFollowed(_ user: User, byCurrentUserWithCompletion completion: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let ref = Database.database().reference().child("followers").child(currentUID)
        
        ref.queryEqual(toValue: nil, childKey: currentUID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? [String : Bool] {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
}
