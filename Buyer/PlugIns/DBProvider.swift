//
//  DBProvider.swift
//  Buyer
//
//  Created by William J. Wolfe on 11/10/17.
//  Copyright © 2017 William J. Wolfe. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class DBProvider {
    private static let _instance = DBProvider();
    
    static var Instance: DBProvider {
        return _instance;
    }
    
    var dbRef: DatabaseReference {
        return Database.database().reference();
    }
    
    var buyersRef: DatabaseReference {
        return dbRef.child(Constants.BUYERS);
    }
    
    var sellersRef: DatabaseReference {
        return dbRef.child(Constants.SELLERS);
    }
    
    var requestRef: DatabaseReference {
        return dbRef.child(Constants.AUCTION_REQUEST);
    }
    
    var bidRef: DatabaseReference {
        return dbRef.child(Constants.BID);
    }
    
    var requestAcceptedRef: DatabaseReference {
        return dbRef.child(Constants.AUCTION_ACCEPTED);
    }
    
    //From Chat:
    var messagesRef: DatabaseReference {
        return dbRef.child(Constants.MESSAGES);
    }
    
    var mediaMessagesRef: DatabaseReference {
        return dbRef.child(Constants.MEDIA_MESSAGES);
    }
    
    //got this url from Firebase console, Storage:
    var storageRef: StorageReference {
        return Storage.storage().reference(forURL: "gs://timbid-e79d6.appspot.com");
    }
    
    var imageStorageRef: StorageReference {
        return storageRef.child(Constants.IMAGE_STORAGE);
    }
    
    var videoStorageRef: StorageReference {
        return storageRef.child(Constants.VIDEO_STORAGE);
    }
    
    // end From Chat
    
    var stripeCustomersRef: DatabaseReference {
        return dbRef.child(Constants.STRIPE_CUSTOMERS);
    }
    
    
    func saveUser(withID: String, email: String, password: String, rating: String, nRatings: Int) {
        let data: Dictionary<String, Any> =
            [Constants.EMAIL: email,
             Constants.PASSWORD: password,
             Constants.isSeller: false,
             Constants.RATING: rating,
             Constants.N_RATINGS: 1];
         buyersRef.child(withID).child(Constants.DATA).setValue(data);
        sellersRef.child(withID).child(Constants.DATA).setValue(data);
    }
    
} // class
