//
//  PanoramaModel.swift
//  DronePan-Swift
//
//  Created by Shubh on 03/08/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

struct SerializationKeys {
    static let airCraftHeading = "airCraftHeading"
    static let airCraftAltitude = "airCraftAltitude"
    static let columns   = "columns"
    static let airCraftLatitude = "airCraftLatitude"
    static let airCraftLongitude  = "airCraftLongitude"
    static let rows = "rows"
    static let skyRow   = "skyRow"
    static let yawType   = "yawType"
    static let timeStamp = "timeStamp"
}

//for panorama to cloud
var ref = Database.database().reference()
var userID = Auth.auth().currentUser?.uid


class PanoramaModel: NSObject {

    var airCraftHeading:Double
    var airCraftAltitude:Double
    var columns:Int
    var airCraftLatitude:Double
    var airCraftLongitude:Double
    var rows:Int
    var skyRow:Int
    var yawType:String
    var timeStamp:Double
    var id:AnyObject? //cantain value if init from firebase
    
    
    init(_ dictionary : Dictionary<String,AnyObject>) {
        self.airCraftHeading = dictionary["airCraftHeading"] as? Double ?? 0.0
        self.airCraftAltitude = dictionary["airCraftAltitude"] as? Double ?? 0.0
        self.columns = dictionary["columns"] as? Int ?? 0
        self.airCraftLatitude = dictionary["airCraftLatitude"] as? Double ?? 0.0
        self.airCraftLongitude = dictionary["airCraftLongitude"] as? Double ?? 0.0
        self.rows = dictionary["rows"] as? Int ?? 0
        self.skyRow = dictionary["skyRow"] as? Int ?? 0
        self.yawType = dictionary["yawType"] as? String ?? ""
        self.timeStamp = dictionary["timeStamp"] as? Double ?? 0
        self.id = dictionary["childId"] //for delete pano from db
    }
    // MARK: NSCoding
    
    public func dictionaryRepresentation() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        dictionary[SerializationKeys.airCraftHeading] = airCraftHeading
        dictionary[SerializationKeys.airCraftAltitude] = airCraftAltitude
        dictionary[SerializationKeys.columns] = columns
        dictionary[SerializationKeys.airCraftLatitude] = airCraftLatitude
        dictionary[SerializationKeys.airCraftLongitude] = airCraftLongitude
        dictionary[SerializationKeys.rows] = rows
        dictionary[SerializationKeys.skyRow] = skyRow
        dictionary[SerializationKeys.yawType] = yawType
        dictionary[SerializationKeys.timeStamp] = timeStamp
        
        return dictionary
    }

    
}
