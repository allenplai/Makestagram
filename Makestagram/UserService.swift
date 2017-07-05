//
//  UserService.swift
//  Makestagram
//
//  Created by Allen Lai on 6/8/17.
//  Copyright © 2017 Allen Lai. All rights reserved.
//

import Foundation

import FirebaseAuth.FIRUser
import FirebaseDatabase

struct UserService {
    
    static func create(_ firUser: FIRUser, username: String, completion: @escaping (User?) -> Void) {
        
        let userAttrs: [String : Any] = ["username": username,
                                         "follower_count": 0,
                                         "following_count" : 0,
                                         "post_count" : 0]
        
//        let ref = Database.database().reference().child("users").child(firUser.uid)
        let ref = DatabaseReference.toLocation(.users).child(firUser.uid)
        ref.setValue(userAttrs) { (error, ref) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
            
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                let user = User(snapshot: snapshot)
                completion(user)
            })
        }
    }

    
    static func posts(for user: User, completion: @escaping ([Post]) -> Void) {
//        let ref = Database.database().reference().child("posts").child(user.uid)
        
        let ref = DatabaseReference.toLocation(.posts(uid: user.uid))
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion([])
            }
            
            let dispatchGroup = DispatchGroup()
            
            let posts: [Post] =
                snapshot
                    .reversed()
                    .flatMap {
                        guard let post = Post(snapshot: $0)
                            else { return nil }
                        
                        dispatchGroup.enter()
                        
                        LikeService.isPostLiked(post) { (isLiked) in
                            post.isLiked = isLiked
                            
                            dispatchGroup.leave()
                        }
                        
                        return post
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(posts)
            })
        })
    }
    
    static func show(forUID uid: String, completion: @escaping (User?) -> Void) {
//        let ref = Database.database().reference().child("users").child(uid)
        let ref = DatabaseReference.toLocation(.showUser(uid: uid))
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let user = User(snapshot: snapshot) else {
                return completion(nil)
            }
            completion(user)
        })
    }
    static func usersExcludingCurrentUser(completion: @escaping ([User]) -> Void) {
        let currentUser = User.current
//        let ref = Database.database().reference().child("users")
        let ref = DatabaseReference.toLocation(.users)

        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            
            let users =  snapshot.flatMap(User.init).filter { $0.uid != currentUser.uid }
            
            // Create a new DispatchGroup so that we can be notified when all asynchronous tasks are finished executing. We'll use the notify(queue:) method on DispatchGroup as a completion handler for when all follow data has been read.
            let dispatchGroup = DispatchGroup()
            users.forEach { (user) in
                dispatchGroup.enter()
                
                // 5
                FollowService.isUserFollowed(user) { (isFollowed) in
                    user.isFollowed = isFollowed
                    dispatchGroup.leave()
                }
            }
            
            // 6
            dispatchGroup.notify(queue: .main, execute: {
                completion(users)
            })
        })
    }
    // get all the followers
    static func followers(for user: User, completion: @escaping ([String]) -> Void) {
        let followersRef = Database.database().reference().child("followers").child(user.uid)
        
        followersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let followersDict = snapshot.value as? [String : Bool] else {
                return completion([])
            }
            
            let followersKeys = Array(followersDict.keys)
            completion(followersKeys)
        })
    }
    
    static func timeline(pageSize: UInt, lastPostKey: String? = nil, completion: @escaping ([Post]) -> Void) {
        let currentUser = User.current

        let ref = DatabaseReference.toLocation(.timeline(uid: currentUser.uid))
        var query = ref.queryOrderedByKey().queryLimited(toLast: pageSize)
        if let lastPostKey = lastPostKey {
            query = query.queryEnding(atValue: lastPostKey)
        }
        
        query.observeSingleEvent(of: .value, with: { (snapshot) in
        
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            
            let dispatchGroup = DispatchGroup()
            
            var posts = [Post]()
            
            for postSnap in snapshot {
                guard let postDict = postSnap.value as? [String : Any],
                    let posterUID = postDict["poster_uid"] as? String
                    else { continue }
                
                dispatchGroup.enter()
                
                PostService.show(forKey: postSnap.key, posterUID: posterUID) { (post) in
                    if let post = post {
                        posts.append(post)
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main, execute: {
                completion(posts.reversed())
            })
        })
    }
    // retrieve data to provide content for a given user's profile
    static func observeProfile(for user: User, completion: @escaping (DatabaseReference, User?, [Post]) -> Void) -> DatabaseHandle {
        let userRef = Database.database().reference().child("users").child(user.uid)
        
        return userRef.observe(.value, with: { snapshot in
            guard let user = User(snapshot: snapshot) else {
                return completion(userRef, nil, [])
            }
            
            posts(for: user, completion: { posts in
                // return completion block with DatabaseReference, user, and posts
                completion(userRef, user, posts)
            })
        })
    }
    
    
    //  retrieve a list of users that the current user is following
    static func following(for user: User = User.current, completion: @escaping ([User]) -> Void) {
        let followingRef = Database.database().reference().child("following").child(user.uid)
        followingRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let followingDict = snapshot.value as? [String : Bool] else {
                return completion([])
            }
            
            var following = [User]()
            let dispatchGroup = DispatchGroup()
            
            for uid in followingDict.keys {
                dispatchGroup.enter()
                
                 show (forUID: uid) { user in
                    if let user = user {
                        following.append(user)
                    }
                    dispatchGroup.leave()
                }
            }
            
            // 4
            dispatchGroup.notify(queue: .main) {
                completion(following)
            }
        })
    }
    static func observeChats(for user: User = User.current, withCompletion completion: @escaping (DatabaseReference, [Chat]) -> Void) -> DatabaseHandle {
        let ref = Database.database().reference().child("chats").child(user.uid)
        
        return ref.observe(.value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion(ref, [])
            }
            
            let chats = snapshot.flatMap(Chat.init)
            completion(ref, chats)
        })
    }
    
    
    
}

