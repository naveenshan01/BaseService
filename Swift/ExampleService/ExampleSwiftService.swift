//
//  ExampleSwiftService.swift
//  <>
//
//  Created by Naveen Shan.
//  Copyright © 2015. All rights reserved.
//

import Foundation

var serviceInstance: ExampleSwiftService?

 @objc public class ExampleSwiftService: BaseService {
    
    public class func sharedInstance () -> AnyObject {
        if serviceInstance == nil {
            serviceInstance = ExampleSwiftService.init()
            
            // Normal we need to set this once in app on app launch.
            // Or if we required we can append along with url string, No need to set base url.
            ExampleSwiftService.setBaseURL("http://jsonplaceholder.typicode.com")
        }
        return serviceInstance!
    }
    
    // MARK: JSON Service
    public func getAllUsersWithCompletionHandler(handler:((NSArray?, NSError?) -> Void)) {
        let urlString = NSString(format: "%@/users", ExampleSwiftService.baseURL())
        let request = ExampleSwiftService.jsonGetRequestWithURLString(urlString as String)
        
        ExampleSwiftService.sendRequest(request, completionHandler: {response,error in
            handler(response as? NSArray,error);
        })
    }
    
    // MARK: SOAP Service
}
