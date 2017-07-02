//
//  MGPaginationHelper.swift
//  Makestagram
//
//  Created by Allen Lai on 6/9/17.
//  Copyright © 2017 Allen Lai. All rights reserved.
//

import Foundation
protocol MGKeyed {
    var key: String? { get set }
}

class MGPaginationHelper<T: MGKeyed> {
    enum MGPaginationState {
        case initial        // no data has been loaded yet
        case ready          // ready and waiting for next request to paginate and load the next page
        case loading        // currently paginating and waiting for data from Firebase
        case end            // all data has been paginated
    }

    // MARK: - Properties
    
    let pageSize: UInt
    let serviceMethod: (UInt, String?, @escaping (([T]) -> Void)) -> Void
    var state: MGPaginationState = .initial
    var lastObjectKey: String?
    
    // MARK: - Init
    
    init(pageSize: UInt = 3, serviceMethod: @escaping (UInt, String?, @escaping (([T]) -> Void)) -> Void) {
        self.pageSize = pageSize
        self.serviceMethod = serviceMethod
    }
    
    
    func paginate(completion: @escaping ([T]) -> Void) {
        // We switch on our helper's state to determine the behavior of our helper when paginate(completion:) is called.
        switch state {
        // For our initial state, we make sure that the lastObjectKey is nil use the fallthrough keyword to execute the ready case below.
        case .initial:
            lastObjectKey = nil
            fallthrough
            
        // For our ready state, we make sure to change the state to loading and execute our service method to return the paginated data
        case .ready:
            state = .loading
            serviceMethod(pageSize, lastObjectKey) { [unowned self] (objects: [T]) in
                
                // We use the defer keyword to make sure the following code is executed whenever the closure returns. This is helpful for removing duplicate code
                defer {
                    // if the returned last returned object has a key value, we store that in lastObjectKey to use as a future offset for paginating.
                    if let lastObjectKey = objects.last?.key {
                        self.lastObjectKey = lastObjectKey
                    }
                    
                    // We determine if we've paginated through all content because if the number of objects returned is less than the page size, we know that we're only the last page of objects.
                    self.state = objects.count < Int(self.pageSize) ? .end : .ready
                }
                
                // If lastObjectKey of the helper doesn't exist, we know that it's the first page of data so we return the data as is
                guard let _ = self.lastObjectKey else {
                    return completion(objects)
                }
                
                // 9
                let newObjects = Array(objects.dropFirst())
                completion(newObjects)
            }
            
        // 10
        case .loading, .end:
            return
        }
    }
    
    func reloadData(completion: @escaping ([T]) -> Void) {
        state = .initial
        
        paginate(completion: completion)
    }
    
}


