//
//  Panorama+Firebase.swift
//  DronePan-Swift
//
//  Created by Shubh on 03/08/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import Foundation
import FirebaseDatabase
import UIKit

extension UIViewController
{
    
    // ADD PANORAMA IN FIREBASE SERVER
    func addPanoramaToCloudStoraga(panorama:[PanoramaModel]) -> Void {
    for panorama in panorama
    {
                let panoRef = ref.child("users").child("\(userID!)").child("panoramas").childByAutoId()
                panoRef.child(SerializationKeys.airCraftHeading).setValue(panorama.airCraftHeading)
                panoRef.child(SerializationKeys.airCraftAltitude).setValue(panorama.airCraftAltitude)
                panoRef.child(SerializationKeys.columns).setValue(panorama.columns)
                panoRef.child(SerializationKeys.airCraftLatitude).setValue(panorama.airCraftLatitude)
                panoRef.child(SerializationKeys.airCraftLongitude).setValue(panorama.airCraftLongitude)
                panoRef.child(SerializationKeys.rows).setValue(panorama.rows)
                panoRef.child(SerializationKeys.skyRow).setValue(panorama.skyRow)
                panoRef.child(SerializationKeys.yawType).setValue(panorama.yawType)
                panoRef.child(SerializationKeys.timeStamp).setValue(panorama.timeStamp)
            }

    }

    //FETCH ALL PANORAMA FROM FIREBASE SERVER
    func fetchAllWaypointsFromCloundStorage(completion:@escaping (([PanoramaModel])->Void)){
        
        let panopointRef = ref.child("users").child("\(userID!)").child("panoramas")
        panopointRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            
            var panoramas : [PanoramaModel] = []
            
            if let snapDic = snapshot.value as? NSDictionary
            {
                for child in snapDic
                {
                    
                   if let childDic = child.value as? Dictionary<String, AnyObject>
                   {
                    var newDict:Dictionary<String, AnyObject> = childDic
                    newDict["childId"] = child.key as AnyObject
                    let panorama = PanoramaModel.init(newDict)
                    panoramas.append(panorama)
                    
                    }
                }
            }
            completion(panoramas)
            
        })
        
    }

    func deletePanormaFromCloud(panorama:PanoramaModel) -> Void {
        
        if let id = panorama.id as? String
        {
        let panopointRef = ref.child("users").child("\(userID!)").child("panoramas").child(id)
        panopointRef.removeValue()
        }
    }
}
