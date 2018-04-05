//
//  SignInVC.swift
//  Buyer
//
//  Created by William J. Wolfe on 11/8/17.
//  Copyright © 2017 William J. Wolfe. All rights reserved.
//

import UIKit

class SignInVC: UIViewController {

    private let BUYER_SEGUE = "BuyerVC";
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var logIn: UIButton!
    
    @IBOutlet weak var signUp: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logIn.backgroundColor = UIColor.cyan
        logIn.layer.cornerRadius = logIn.frame.height/2
        logIn.layer.shadowColor = UIColor.darkGray.cgColor
        logIn.layer.shadowRadius = 4
        logIn.layer.shadowOpacity = 0.5
        logIn.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        signUp.backgroundColor = UIColor.cyan
        signUp.layer.cornerRadius = logIn.frame.height/2
        signUp.layer.shadowColor = UIColor.darkGray.cgColor
        signUp.layer.shadowRadius = 4
        signUp.layer.shadowOpacity = 0.5
        signUp.layer.shadowOffset = CGSize(width: 0, height: 0)

        // Do any additional setup after loading the view.
    }
    
    @IBAction func logIn(_ sender: Any) {
        //performSegue(withIdentifier: BUYER_SEGUE, sender: nil)
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            
            AuthProvider.Instance.login(withEmail: emailTextField.text!,
                                        password: passwordTextField.text!,
                                        loginHandler: { (message) in
                                            
                                            if message != nil {
                                                self.alertTheUser(title: "Problem With Authentication",
                                                                  message: message!);
                                            } else {
                                                AuctionHandler.Instance.buyer = self.emailTextField.text!;
                                                
                                                self.emailTextField.text = "";
                                                self.passwordTextField.text = "";
                                                
                                                self.performSegue(withIdentifier: self.BUYER_SEGUE, sender: nil);
                                            }
                                            
            });
            
        } else {
            alertTheUser(title: "Email And Password Are Required",
                         message: "Please enter email and password in the text fields");
        }
 
    }
    
    @IBAction func signUp(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            
            AuthProvider.Instance.signUp(withEmail: emailTextField.text!,
                                         password: passwordTextField.text!,
                                         loginHandler: { (message) in
                
                if message != nil {
                    self.alertTheUser(title: "Problem With Creating A New User", message: message!);
                } else {
                    AuctionHandler.Instance.buyer = self.emailTextField.text!;
                    
                    self.emailTextField.text = "";
                    self.passwordTextField.text = "";
                    
                    self.performSegue(withIdentifier: self.BUYER_SEGUE, sender: nil)
                }
                
            });
            
        } else {
            alertTheUser(title: "Email And Password Are Required",
                         message: "Please enter email and password in the text fields");
        }
    }
    
    
    private func alertTheUser(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }

}
