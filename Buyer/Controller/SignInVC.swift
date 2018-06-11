//
//  SignInVC.swift
//  Buyer
//
//  Created by William J. Wolfe on 11/8/17.
//  Copyright © 2017 William J. Wolfe. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth

class SignInVC: UIViewController, FBSDKLoginButtonDelegate {

    private let BUYER_SEGUE = "BuyerVC";
    private let BUYER_SELLER_SEGUE = "BuyerSellerSegue";
    private let TabBarSegue = "TabBarSegue";
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
        
        let loginButton = FBSDKLoginButton()
        view.addSubview(loginButton)
        loginButton.frame = CGRect(x: 54, y: 400, width: view.frame.width - 108, height: 36)
        
        loginButton.delegate = self
        loginButton.readPermissions = ["email", "public_profile"]
/*
        let customFBLoginButton = UIButton(type: .system)
        customFBLoginButton.backgroundColor = .blue
        customFBLoginButton.frame = CGRect(x: 16, y: 466, width: view.frame.width - 32, height: 50)
        customFBLoginButton.setTitle("Custom FB Login", for: .normal)
        customFBLoginButton.setTitleColor(.white, for: .normal)
        customFBLoginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        view.addSubview(customFBLoginButton)
        customFBLoginButton.addTarget(self, action: #selector(handleCustomFBLogin), for: .touchUpInside)
 */
    }
    
    @objc func handleCustomFBLogin() {
        print("clicked on the custom fb button")
        FBSDKLoginManager().logIn(withReadPermissions: ["email", "public_profile"], from: self)
            {  (result, err) in
                if (err != nil) {
                    print("Custom FB login failed", err ?? "")
                    return
                }
               self.showEmailAddress()
            }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of FB")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if (error != nil) {
            print(error)
            return
        }
        print("successfully logged in with FB")
        showEmailAddress()
    }
    
    //This is for the FB login:
    func showEmailAddress () {
        
        //if FB login do this:
         let accessToken = FBSDKAccessToken.current()
         guard let accessTokenString = accessToken?.tokenString else { return }
         let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
         
         Auth.auth().signIn(with: credentials, completion: { (user, error) in
            if (error != nil ){
                print("something went wrong with our FB user", error ?? "")
                return
            }
            print("successfully logged in with our user", user ?? "")
            print("user email = \(user?.email! ?? "")")
            AuctionHandler.Instance.buyer = (user?.email)!
            Seller_AuctionHandler.Instance.seller = (user?.email)!
            AuctionHandler.Instance.buyer_id = (user?.uid)!
            Seller_AuctionHandler.Instance.seller_id = (user?.uid)!
            DBProvider.Instance.saveUser(withID: user!.uid, email: (user?.email)!, password: "", rating: "4", nRatings: 1, name: (user?.displayName)!, profileImageUrl: "" );
            self.performSegue(withIdentifier: self.TabBarSegue, sender: nil);
            })
         
        //
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start {
            (connection, result, err) in
            if (err != nil) {
                print("failed to start graph request")
                return
            }
            print("hello",result ?? "")
            //self.performSegue(withIdentifier: self.TabBarSegue, sender: nil);
        }
        print("got here 123")
       
    }
    
    @IBAction func logIn(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            
            AuthProvider.Instance.login(withEmail: emailTextField.text!, password: passwordTextField.text!, loginHandler: { (message) in
                        if message != nil {
                            self.alertTheUser(title: "Problem With Authentication", message: message!);
                        } else {
                            AuctionHandler.Instance.buyer = self.emailTextField.text!;
                            Seller_AuctionHandler.Instance.seller = self.emailTextField.text!;
                            BuyerStateVariables.Instance.buyer = self.emailTextField.text!;
                            self.emailTextField.text = "";
                            self.passwordTextField.text = "";
                            self.performSegue(withIdentifier: self.TabBarSegue, sender: nil);
                        }
                                            
            });
            
        } else {
            alertTheUser(title: "Email And Password Are Required",
                         message: "Please enter email and password in the text fields");
        }
 
    }
    
    @IBAction func signUp(_ sender: Any) {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            /*
            AuthProvider.Instance.signUp(withEmail: emailTextField.text!, password: passwordTextField.text!, name: "hello",  loginHandler: { (message) in
                
                    if message != nil {
                        self.alertTheUser(title: "Problem With Creating A New User", message: message!);
                    } else {
                        AuctionHandler.Instance.buyer = self.emailTextField.text!;
                        Seller_AuctionHandler.Instance.seller = self.emailTextField.text!;
                        self.emailTextField.text = "";
                        self.passwordTextField.text = "";
                        self.performSegue(withIdentifier: self.TabBarSegue, sender: nil);
                    }
                
            });
            */
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
