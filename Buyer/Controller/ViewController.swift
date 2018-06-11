//
//  ViewController.swift
//  Buyer
//
//  Created by William J. Wolfe on 6/1/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    private let TabBarSegue2 = "TabBarSegue2";
    
    @IBAction func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
        //self.performSegue(withIdentifier: self.TabBarSegue2, sender: nil);
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        */
        
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }
    }
    
    @IBAction func goToTimBidApp () {
        self.performSegue(withIdentifier: self.TabBarSegue2, sender: nil);
    }
    
}
