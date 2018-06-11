//
//  LoginController+handlers.swift
//  Buyer
//
//  Created by William J. Wolfe on 6/5/18.
//  Copyright © 2018 William J. Wolfe. All rights reserved.
//

import UIKit

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleRegister() {
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            
            
            
            AuthProvider.Instance.signUp(withEmail: emailTextField.text!, password: passwordTextField.text!, name: nameTextField.text!, profileImage: self.profileImageView.image!, loginHandler: { (message) in
                
                if message != nil {
                    self.alertTheUser(title: "Problem With Creating A New User", message: message!);
                } else {
                    AuctionHandler.Instance.buyer = self.emailTextField.text!;
                    AuctionHandler.Instance.name = self.nameTextField.text!;
                    Seller_AuctionHandler.Instance.seller = self.emailTextField.text!;
                    Seller_AuctionHandler.Instance.name = self.nameTextField.text!;
                    self.emailTextField.text = "";
                    self.passwordTextField.text = "";
                    self.nameTextField.text = "";
                    self.performSegue(withIdentifier: self.TabBarSegue2, sender: nil);
                }
                
            });
            
        } else {
            alertTheUser(title: "Email And Password Are Required",
                         message: "Please enter email and password in the text fields");
        }
        
        /*
         guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
         print("Form is not valid")
         return
         }
         
         Auth.auth().createUser(withEmail: email, password: password, completion: { (user: User?, error) in
         
         if let error = error {
         print(error)
         return
         }
         
         guard let uid = user?.uid else {
         return
         }
         
         //successfully authenticated user
         let ref = Database.database().reference()
         let usersReference = ref.child("users").child(uid)
         let values = ["name": name, "email": email]
         usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
         
         if let err = err {
         print(err)
         return
         }
         
         self.dismiss(animated: true, completion: nil)
         })
         
         })
         */
    }
    
    @objc func handleSelectProfileImageView() {
       let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
        
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImageFromPicker: UIImage?
        if let editedImage = info["UIImagePickerControllerEditedImage"] {
            selectedImageFromPicker = editedImage as? UIImage
        } else {
            if let originalImage = info["UIImagePickerControllerOriginalImage"] {
                selectedImageFromPicker = originalImage as? UIImage
            }
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
       
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true,completion: nil)
    }
}
