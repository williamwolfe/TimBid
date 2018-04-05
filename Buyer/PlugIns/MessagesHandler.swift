//
//  MessagesHandler.swift
//  Buyer
//
//  Created by William J. Wolfe on 12/22/17.
//  Copyright © 2017 William J. Wolfe. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

protocol MessageReceivedDelegate: class {
    func messageReceived(senderID: String, senderName: String, text: String);
    func mediaReceived(senderID: String, senderName: String, url: String);
}

class MessagesHandler {
    private static let _instance = MessagesHandler();
    var messageCount: Int =  0
    
    //These variables are for preventing duplicate messages:
    var message_id = ""
    var previous_message_id = ""
    
    var media_message_id = ""
    var previous_media_message_id = ""
    //
    
    var arrayOfMessageIds:[String] = []
    private init() {}
    
    weak var delegate: MessageReceivedDelegate?;
    
    static var Instance: MessagesHandler {
        return _instance;
    }
    
    func sendMessage(senderID: String, senderName: String, text: String) {
        
        let data: Dictionary<String, Any> = [
            Constants.SENDER_ID: senderID,
            Constants.SENDER_NAME: senderName,
            Constants.RECEIVER_NAME: AuctionHandler.Instance.seller,
            Constants.TEXT: text];
        
        DBProvider.Instance.messagesRef.childByAutoId().setValue(data);
        
        
    }
    
    func sendMediaMessage(senderID: String, senderName: String, url: String) {
        let data: Dictionary<String, Any> = [Constants.SENDER_ID: senderID, Constants.SENDER_NAME: senderName, Constants.URL: url];
        
        DBProvider.Instance.mediaMessagesRef.childByAutoId().setValue(data);
    }
    
    func sendMedia(image: Data?, video: URL?, senderID: String, senderName: String) {
        //putData(_:metadata:completion:)
        //Changed "put" to putData
        if image != nil {
            
            DBProvider.Instance.imageStorageRef.child(senderID + "\(NSUUID().uuidString).jpg").putData(image!, metadata: nil) { (metadata: StorageMetadata?, err: Error?) in
                
                if err != nil {
                    // inform the user that there was a problem uploading his image
                    print("got an err in MessagesHandler/sendMedia, image section")
                } else {
                    self.sendMediaMessage(senderID: senderID, senderName: senderName, url: String(describing: metadata!.downloadURL()!));
                }
            }
            
        } else {
            DBProvider.Instance.videoStorageRef.child(senderID + "\(NSUUID().uuidString)").putFile(from: video!, metadata: nil) { (metadata: StorageMetadata?, err: Error?) in
                
                if err != nil {
                    // inform the user that uploading the video has failed using delegation
                    print("got an err in MessagesHandler/sendMedia, video section")
                } else {
                    self.sendMediaMessage(senderID: senderID, senderName: senderName, url: String(describing: metadata!.downloadURL()!))
                }
                
            }
        }
        
    }
    
    func observeMessages() {
        DBProvider.Instance.messagesRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                self.messageCount += 1
                self.message_id = snapshot.key;
                self.arrayOfMessageIds.append(self.message_id)
                
            if(self.message_id != self.previous_message_id) {
                
                if let senderID = data[Constants.SENDER_ID] as? String {
                    if let senderName = data[Constants.SENDER_NAME] as? String {
                        if let text = data[Constants.TEXT] as? String {
                            if( AuctionHandler.Instance.buyer == senderName
                                ||
                                AuctionHandler.Instance.seller == senderName
                                )
                            {
                                self.delegate?.messageReceived(
                                    senderID:   senderID,
                                    senderName: senderName,
                                    text:       text);
                               self.previous_message_id = self.message_id
                            }
                        }
                    }
                }
                }
            }
            
        }
    }
    
    func observeMediaMessages() {
        DBProvider.Instance.mediaMessagesRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            
            if let data = snapshot.value as? NSDictionary {
                self.media_message_id = snapshot.key
                 if(self.media_message_id != self.previous_media_message_id) {
                    if let id = data[Constants.SENDER_ID] as? String {
                        if let name = data[Constants.SENDER_NAME] as? String {
                            if let fileURL = data[Constants.URL] as? String {
                                self.delegate?.mediaReceived(senderID: id, senderName: name, url: fileURL);
                                self.previous_media_message_id = self.media_message_id
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    func cancelChat() {
        //DBProvider.Instance.requestRef.child(seller_id).removeValue();
        
        for (_, value) in arrayOfMessageIds.enumerated() {
            DBProvider.Instance.messagesRef.child(value).removeValue()
        }
        arrayOfMessageIds = [];
        messageCount = 0;
        
    }
    
    
} // class
