//
//  CoreDataHelper.swift
//  EchoEquity
//
//  Created by CANO03 on 15/11/16.
//  Copyright © 2016 Canopus. All rights reserved.
//

import UIKit
import CoreData

class DataBaseHelper: NSObject
{
    
    var singUpDictionary : [String : String] = [:]
    
    
    static let sharedInstance : DataBaseHelper =
        {
            let instance = DataBaseHelper()
            return instance
    }()
    
    
    
    lazy var applicationDocumentsDirectory: URL =
        {
            let urls = FileManager.default.urls(for: .documentDirectory,in:.userDomainMask)
            
            return urls[urls.count-1]
    }()
    
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = Bundle.main.url(forResource: "LocalDataBase", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let url = self.applicationDocumentsDirectory.appendingPathComponent("DronePan-Swift" + ".sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application’s saved data."
        
        do {
            try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return managedObjectContext
        
    }()
    
    
    // MARK: - Core Data Saving support
    func saveContext ()->Bool
    {
        var isSaved : Bool? = false
        
        if (managedObjectContext?.hasChanges)!
        {
            do {
                try  managedObjectContext?.save()
                
                isSaved = true
            } catch
            {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                
                isSaved = false
                
            }
        }
        
        return isSaved!
    }
    
    
    
    //--------------------------------------------------------------------------//
    //MARK: - Core Data Insert Update Delete methods
    //--------------------------------------------------------------------------//
    func allRecordsSortByAttribute(inTable : String,whereKey : String,contains : Any)-> Array<NSManagedObject>?
    {
        var arrayObject : Array<NSManagedObject>?
        
        let entityDesc = NSEntityDescription.entity(forEntityName: inTable, in: managedObjectContext!)
        
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
        
        request.entity = entityDesc
        
        let predicateKey = NSPredicate(format: "self.%@ = %@", whereKey ,contains as! CVarArg)
        
        request.resultType = .managedObjectResultType
        
        request.predicate = predicateKey
        
        request.sortDescriptors = nil
        
        
        do {
            
            let allObject  = try self.managedObjectContext?.fetch(request)
            
            arrayObject = allObject as? Array<NSManagedObject>
        }
        catch
        {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return arrayObject
    }
    
    
    func allRecordsSortByAttribute(inTable : String,wherePredicate : NSPredicate)->Array<NSManagedObject>
    {
        var arrayObject : Array<NSManagedObject>?
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: inTable)
        
        request.resultType = .managedObjectResultType
        
        request.predicate = wherePredicate
        
        do {
            let allObject  = try self.managedObjectContext?.fetch(request)
            arrayObject = allObject as? Array<NSManagedObject>
        }
        catch
        {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return arrayObject!
        
    }
    
    
    func allRecordsSortByAttribute(inTable : String)-> Array<NSManagedObject>
    {
        var arrayObject : Array<NSManagedObject>?
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: inTable)
        
        request.resultType = .managedObjectResultType
        
        do {
            
            let allObject  = try self.managedObjectContext?.fetch(request)
            arrayObject = allObject as? Array<NSManagedObject>
        }
        catch
        {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return arrayObject!
    }
    
    
    func insertRecordInTable(tableName : String,attributes : [String : Any])->NSManagedObject
    {
        
        let entityDescription  = NSEntityDescription.insertNewObject(forEntityName:tableName, into: self.managedObjectContext!)
        
        for key in entityDescription.entity.attributesByName.keys
        {
            let value = attributes[key]
            entityDescription.setValue(value  , forKey: key)
        }
        
        print(entityDescription.objectID)
        
        if self.saveContext()
        {
            return entityDescription
        }
        else
        {
            return entityDescription
        }
        
    }
    
    func insertUpdateRecordInTable(tableName : String,attribute : [String : Any],withExistKey : String , containsUniqueId : Any)->NSManagedObject
    {
        let object_ = (allRecordsSortByAttribute(inTable: tableName, whereKey: withExistKey, contains: containsUniqueId)?.first)
        
        if (object_ != nil)
        {
            return updateRecordInTableWith(attribute: attribute , object: object_!)
        }
        else
        {
            return insertRecordInTable(tableName: tableName, attributes: attribute )
        }
    }
    
    private func updateRecordInTableWith(attribute : [String : Any],object : NSManagedObject)->NSManagedObject
    {
        
        for key in object.entity.attributesByName.keys
        {
            let value = attribute[key]
            object.setValue(value  , forKey: key)
//            object.setValue(attribute[key], forKey: key)
        }
        
        print(object.objectID)
        
        if self.saveContext()
        {
            return object
        }
        else
        {
            return object
        }
        
    }
    
    
    
    //MARK: - delete record
    
    private func deleteRecord(record : NSManagedObject)->Bool
    {
        self.managedObjectContext?.performAndWait({
            self.managedObjectContext?.delete(record)
        })
        
        return self.saveContext()
    }
    
    func deleteRecord(inTable : String)->Bool
    {
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: inTable)
        
        
        do {
        
            let arrayObject  = try self.managedObjectContext?.fetch(request)
            
            let object = arrayObject as? Array<NSManagedObject>
            
            if (object != nil)
            {
                return self.deleteRecord(record: (object?.first)!)
            }
            else
            {
            }
            
        }
        catch
        {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            
        }
        
        return false
    }
    
    func deleteAllTableRecord(inTable : String)->Bool
    {
        return self.flush(table: inTable)
        
    }
    func deleteAllTableRecordInTable(tableName : String,whereKey : String ,contains : Any)
    {
        
    }
    
    func deleteRecordInTable(inTable : String,wherePredicate : NSPredicate)->Bool
    {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: inTable)
        
        request.predicate = wherePredicate
        
        do {
            let arrayObject  = try self.managedObjectContext?.fetch(request)
            
            let object = arrayObject as? Array<NSManagedObject>
            
            if (object != nil)
            {
                return self.deleteRecord(record: (object?.first)!)
            }
            else
            {
                return false
            }
            
        }
        catch
        {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            
//            return false
        }
        
        
    }
    
    private func flush(table : String)->Bool
    {
        
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: table)
        
        do {
            let allObjects  = try self.managedObjectContext?.fetch(request)
            
            let allManagedObject = allObjects as? Array<NSManagedObject>
            
            self.managedObjectContext?.performAndWait({
                
                for record in allManagedObject!
                {
                    self.managedObjectContext?.delete(record)
                }
            })
            
            return self.saveContext()
        }
        catch
        {
            return false
        }
        
     
    }
    
    
    
}


extension Dictionary {
    func nullKeyRemoval() -> Dictionary {
        var dict = self
        
        let keysToRemove = dict.keys.filter { dict[$0] is NSNull }
        for key in keysToRemove {
            dict.removeValue(forKey: key)
        }
        
        return dict
    }
}






