//
//  AuthProvider.swift
//  Buyer
//
//  Created by William J. Wolfe on 11/8/17.
//  Copyright © 2017 William J. Wolfe. All rights reserved.
//

import Foundation
import FirebaseAuth
import Firebase
import FBSDKLoginKit

typealias LoginHandler = (_ msg: String?) -> Void;

struct LoginErrorCode {
    static let INVALID_EMAIL = "Invalid Email Address, Please Provide A Real Email Address";
    static let WRONG_PASSWORD = "Wrong Password, Please Enter The Correct Password";
    static let PROBLEM_CONNECTING = "Problem Connecting To Database, Please Try Later";
    static let USER_NOT_FOUND = "User Not Found, Please Register";
    static let EMAIL_ALREADY_IN_USE = "Email Already In Use, Please Use Another Email";
    static let WEAK_PASSWORD = "Password Should Be At Least 6 Characters Long";
}

class AuthProvider {
    private static let _instance = AuthProvider();
    var user_id: String = ""
    static var Instance: AuthProvider {
        return _instance;
    }
    
    func login(withEmail: String, password: String, loginHandler: LoginHandler?) {
        
        
        Auth.auth().signIn(withEmail: withEmail, password: password, completion: { (user, error) in
            
            if error != nil {
                self.handleErrors(err: error! as NSError, loginHandler: loginHandler);
            } else {
                        self.user_id = user!.uid;
                        loginHandler?(nil);
                        let userID = self.userID()
                        AuctionHandler.Instance.buyer_id = userID;
                        Seller_AuctionHandler.Instance.seller_id = userID;
                
                        DBProvider.Instance.sellersRef.child("\(userID)/data/name").observeSingleEvent(of: .value) { (snapshot) in
                                if (snapshot.value as? String) != nil {
                                    AuctionHandler.Instance.name = snapshot.value as! String;
                                    Seller_AuctionHandler.Instance.name = snapshot.value as! String;
                                    
                            } else {
                                    AuctionHandler.Instance.name = "TIMBid Buyer"
                                    Seller_AuctionHandler.Instance.name = "TIMBid Seller"
                            }
                        }
                    }
            
        });
        
    } // login func
    
    func signUp(withEmail: String, password: String, name: String, profileImage: UIImage, loginHandler: LoginHandler?) {
        
        Auth.auth().createUser(withEmail: withEmail, password: password, completion: { (user, error) in
            
            if error != nil {
                self.handleErrors(err: error! as NSError, loginHandler: loginHandler);
            } else {
                
                if user?.uid != nil {
                    self.user_id = user!.uid;
                    AuctionHandler.Instance.buyer_id = self.user_id
                    //user is now authenticated
                    
                    //generate a unique string to name the image:
                    let imageName = NSUUID().uuidString
                    //define a reference on firebase, in the profile_images directory:
                    let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
 
                    if let uploadData = UIImagePNGRepresentation(profileImage) {
                       
                        storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                            if let error = error {
                                print(error)
                                return
                            }
                            //get the image url from firebase storage, and store it in the users data on firebase:
                            if let profileImageUrl = metadata?.downloadURL()?.absoluteString {
                                // store the user to database:
                                DBProvider.Instance.saveUser(withID: user!.uid, email: withEmail, password: password, rating: "4", nRatings: 1, name: name, profileImageUrl: profileImageUrl);
                                //log the user in:
                                self.login(withEmail: withEmail, password: password, loginHandler: loginHandler);
                        
                            }
                        })
                    }
                }
            }
        })
    }
        
    
    func logOut() -> Bool {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut();
                return true;
            } catch {
                return false;
            }
        }
        return true;
    }
    
    func userID() -> String {
        return Auth.auth().currentUser!.uid;
    }
    
    private func handleErrors(err: NSError, loginHandler: LoginHandler?) {
        
        if let errCode = AuthErrorCode(rawValue: err.code) {
            
            
            switch errCode {
                
            //case .errorCodeWrongPassword:
                //loginHandler?(LoginErrorCode.WRONG_PASSWORD);
                //break;
                
            case .wrongPassword:
                loginHandler?(LoginErrorCode.WRONG_PASSWORD);
                break;
                
            case .invalidEmail:
                loginHandler?(LoginErrorCode.INVALID_EMAIL);
                break;
                
            case .userNotFound:
                loginHandler?(LoginErrorCode.USER_NOT_FOUND);
                break;
                
            case .emailAlreadyInUse:
                loginHandler?(LoginErrorCode.EMAIL_ALREADY_IN_USE);
                break;
                
            case .weakPassword:
                loginHandler?(LoginErrorCode.WEAK_PASSWORD);
                break;
                
            default:
                loginHandler?(LoginErrorCode.PROBLEM_CONNECTING);
                break;
                
            }
            
        }
        
    }
    
} // class

