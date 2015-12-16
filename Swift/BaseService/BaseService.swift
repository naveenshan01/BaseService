//
//  BaseService.swift
//  <>
//
//  Created by Naveen Shan.
//  Copyright © 2015. All rights reserved.
//

import Foundation

var kDebugEnabled = true
var kRequestTimeout = 30
var baseURLString: String?
var serviceQueue: NSOperationQueue?

public class BaseService: NSObject {
    
    public class func requestOperationQueue() -> NSOperationQueue {
        if serviceQueue == nil {
            serviceQueue = NSOperationQueue.init()
        }
        return serviceQueue!
    }
    
    //MARK: -
    // TODO : Do logic for network check if pre network check required.
    public func networkAvailable() -> Bool {
        return true
    }
    
    //MARK: -
    
    public class func baseURL() -> String {
        return baseURLString!
    }
    
    public class func setBaseURL(baseURL: String) {
        baseURLString = baseURL
    }
    
    public class func enableDebug(enable: Bool) {
        kDebugEnabled = enable
    }
    
    public class func setRequestTimeout(seconds: Int) {
        kRequestTimeout = seconds
    }
    
    class func logMessage(message: NSString) {
        if(kDebugEnabled) {
            NSLog("%@", message)
        }
    }
    
    //MARK: - Host Name From URL
    
    class func hostNameFromURL(urlString: String?) -> String? {
        var hostName: String?   =   nil
        
        if urlString != nil && urlString!.characters.count > 0 {
            //Check whether URL contains http:// or https://
            if urlString?.rangeOfString("https://") != nil   {
                var hostString = urlString?.stringByReplacingOccurrencesOfString("https://", withString: "")
                var hostParts = hostString?.componentsSeparatedByString("/")
                hostName    = hostParts?[0]
                hostParts = nil
                hostString = nil
            }
            else if urlString?.rangeOfString("http://") != nil   {
                var hostString = urlString?.stringByReplacingOccurrencesOfString("http://", withString: "")
                var hostParts = hostString?.componentsSeparatedByString("/")
                hostName    =   hostParts?[0]
                hostParts = nil
                hostString = nil
            }
            else    {
                var hostParts = urlString?.componentsSeparatedByString("/")
                hostName    =   hostParts?[0]
                hostParts = nil
            }
        }
        
        if hostName == nil {
            NSLog("Exception on hostNameFromURL - \(urlString)")
        }
        return hostName!
    }
    
    class func domainNameFromURL(urlString: String?) -> String? {
        var domainName: String? =   nil
        let hostName = self.hostNameFromURL(urlString)
        
        if hostName != nil && hostName!.characters.count > 0 {
            var hostNameParts = hostName?.componentsSeparatedByString("/")
            let noOfParts = hostNameParts?.count
            domainName = hostNameParts?[noOfParts!-2]
            hostNameParts = nil
        }
        if domainName == nil {
            NSLog("Exception on domainNameFromURL - \(urlString)")
        }
        return domainName!
    }
    
    //MARK: - MimeType
    
    class func parseMimeType(inout mimeType: NSString?, inout andResponseEncoding stringEncoding: NSStringEncoding, fromContentType contentType: String?) {
        if contentType == nil {
            return
        }
        
        let charsetScanner = NSScanner.init(string: contentType!)
        
        if !charsetScanner.scanUpToString(";", intoString: &mimeType) || charsetScanner.scanLocation == contentType?.characters.count {
            mimeType = NSString.init(string: (contentType?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))!)
            return
        }
        mimeType = mimeType?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let charsetSeparator = "charset="
        var IANAEncoding: NSString? = nil
        
        if charsetScanner.scanUpToString(charsetSeparator, intoString: nil) && charsetScanner.scanLocation < contentType?.characters.count {
            charsetScanner.scanLocation = charsetScanner.scanLocation + charsetSeparator.characters.count
            charsetScanner.scanUpToString(";", intoString: &IANAEncoding)
        }
        if (IANAEncoding != nil) {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(IANAEncoding)
            if (cfEncoding != kCFStringEncodingInvalidId) {
                stringEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            }
        }
    }
    
    public class func parseStringEncodingFromResponseHeader(response: NSURLResponse) -> NSStringEncoding {
        let httpResponse = response as? NSHTTPURLResponse
        //to handle response text encoding
        var charset: NSStringEncoding = 0
        var mimeType: NSString? = nil
        let contentType = httpResponse?.allHeaderFields["Content-Type"] as? String
        self.parseMimeType(&mimeType, andResponseEncoding: &charset, fromContentType: contentType)
        if charset != 0 {
            return charset
        }   else {
            //by default we use - NSASCIIStringEncoding
            return NSASCIIStringEncoding
        }
    }
    
    class func parseMimeTypeFromResponseHeader(response: NSURLResponse) -> NSString {
        let httpResponse = response as? NSHTTPURLResponse
        //to Handle response text encoding
        var charset: NSStringEncoding = 0
        var mimeType: NSString? = nil
        let contentType = httpResponse?.allHeaderFields["Content-Type"] as? String
        self.parseMimeType(&mimeType, andResponseEncoding: &charset, fromContentType: contentType)
        return mimeType!
    }
    
    //MARK: -
    
    class func truncateSoapHeaders(var dictionary: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
        if dictionary["soap:Envelope"] != nil {
            dictionary = (dictionary["soap:Envelope"] as? Dictionary<String, AnyObject>)!
        }
        if dictionary["soap:Body"] != nil {
            dictionary = (dictionary["soap:Body"] as? Dictionary<String, AnyObject>)!
        }
        return dictionary
    }
    
    //MARK: -
    
    public class func completePostBody(requestBody: String?) -> String {
        var completePostBody: String? = nil
        if requestBody != nil {
            //appending POST body with Request Body
            completePostBody = String(format: "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
                "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
                "<soap:Body>\n" +
                "%@\n" +
                "</soap:Body>\n" +
                "</soap:Envelope>\n", requestBody!)
        }
        else    {
            //empty POST body
            completePostBody  =   String(format:"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
                "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n" +
                "<soap:Body>\n" +
                "</soap:Body>\n" +
                "</soap:Envelope>\n")
        }
        return completePostBody!
    }
    
    public class func serializedStringForParameters(parameters: Dictionary<String, AnyObject>) -> String {
        var queryString: String? = nil
        let keys = parameters.keys
        if keys.count > 0 {
            for key in keys {
                var value: AnyObject? = parameters[key]
                if queryString == nil {
                    queryString = ""
                }
                if let aValue = value as? Dictionary<String, AnyObject> {
                    value = self.serializedStringForParameters(aValue)
                }
                if value != nil {
                    queryString = queryString! + String(format: "<%@>%@</%@>", key, (value as? String)! , key)
                }
            }
        }
        return queryString!
    }
    
    
    //MARK: -
    
    public class func URLWithUTF8EncodedString(urlString: String?) -> NSURL {
        var encodedUrlString: String? = nil
        if urlString != nil && urlString?.characters.count > 0 {
            encodedUrlString = urlString?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        }
        var url: NSURL? = nil
        if encodedUrlString != nil {
            url = NSURL(string: encodedUrlString!)
        }
        return url!
    }
    
    public class func requestWithMethod(method: String, urlString: String) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: self.URLWithUTF8EncodedString(urlString), cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.HTTPMethod = method
        return request
    }
    
    public class func soapPostRequestWithURLString(urlString: String, soapAction: String?, parameters: AnyObject?) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: self.URLWithUTF8EncodedString(urlString), cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.HTTPMethod = "POST"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(self.hostNameFromURL(urlString), forHTTPHeaderField: "Host")
        request.setValue(self.domainNameFromURL(urlString), forHTTPHeaderField: "Domain")
        
        if soapAction != nil {
            request.setValue(soapAction, forHTTPHeaderField: "SOAPAction")
        }
        
        if parameters != nil {
            var serializedParameterString: String? = nil
            if let theParameters = parameters as? Dictionary<String, AnyObject> {
                serializedParameterString = self.serializedStringForParameters(theParameters)
            }
            else {
                serializedParameterString = parameters as? String
            }
            
            serializedParameterString = self.completePostBody(serializedParameterString)
            var strContentLength: String? = String(format: "%lu", (serializedParameterString?.characters.count)!)
            if strContentLength != nil {
                request.setValue(strContentLength, forHTTPHeaderField: "Content-Length")
            }
            strContentLength = nil
            
            var postData = serializedParameterString?.dataUsingEncoding(NSUTF8StringEncoding)
            serializedParameterString = nil
            
            if postData != nil && postData?.length > 0 {
                request.HTTPBody = postData
            }
            postData = nil
        }
        
        return request
    }
    
    //MARK: -
    
    public class func jsonGetRequestWithURLString(urlString: String) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: self.URLWithUTF8EncodedString(urlString), cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.HTTPMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logMessage(NSString(format: "Request URL : %@", urlString))
        
        return request
    }
    
    public class func jsonGetRequestWithBaseURL(urlString: String, parameters: AnyObject) -> NSMutableURLRequest {
        let components = NSURLComponents(string: urlString)
        var queryItems: Array<NSURLQueryItem> = Array()
        let theParameters = parameters as? Dictionary<String, AnyObject>
        for key in (theParameters?.keys)! {
            let value = parameters[key] as? String
            queryItems.append(NSURLQueryItem(name: key, value: value))
        }
        components?.queryItems = queryItems
        let url = components?.URL
        let request = NSMutableURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.HTTPMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logMessage(NSString(format: "Request URL : %@", urlString))
        
        return request
    }
    
    public class func jsonPostRequestWithURLString(urlString: String, parameters: AnyObject?) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: self.URLWithUTF8EncodedString(urlString), cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if (parameters != nil) {
            do {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(parameters!, options: NSJSONWritingOptions.PrettyPrinted)
                var strContentLength: String? = String(format: "%lu", jsonData.length)
                if strContentLength != nil {
                    request.setValue(strContentLength, forHTTPHeaderField: "Content-Length")
                }
                strContentLength = nil
                if jsonData.length > 0 {
                    request.HTTPBody = jsonData
                }
            }
            catch let error as NSError {
                NSLog("Fail to create JSON : %@",error.description);
            }
        }
        
        logMessage(NSString(format: "Request URL : %@", urlString))
        logMessage(NSString(format: "Request Parameters : %@", String(parameters)))
        
        return request;
    }
    
    //MARK: -
    
    public class func sendRequest(request: NSURLRequest, completionHandler handler:((AnyObject?, NSError?) -> Void)){
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession.init(configuration: configuration)
        
        let dataTask = session.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if error != nil {
                logMessage(NSString(format: "Response : Error - %@", error!))
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(nil, error)
                })
                return
            }
            let httpResponse = response as? NSHTTPURLResponse
            logMessage(NSString(format: "Response : Error - %@", httpResponse!))
            if httpResponse?.statusCode == 200 {   // success
                let mimeType = response?.MIMEType
                
                if mimeType == "text/xml" || mimeType == "application/xml" {
                    let parseError: NSError? = nil
                    var xmlDictionary: Dictionary<String, AnyObject> = Dictionary()
                    if parseError != nil {
                        logMessage(NSString(format: "Response : Parse Error - %@", parseError!))
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            handler(nil, parseError)
                        })
                        return
                    }
                    xmlDictionary = self.truncateSoapHeaders(xmlDictionary)
                    
                    logMessage(NSString(format: "Response : %@ ", String(xmlDictionary)))
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handler(xmlDictionary, error)
                    })
                    return;
                }
                else if mimeType == "application/json" {
                    do {
                        let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)

                        logMessage(NSString(format: "Response : %@ ", String(jsonDictionary)))
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            handler(jsonDictionary, error)
                        })
                        return
                    }
                    catch let error as NSError {
                        logMessage(NSString(format: "Response : Parse Error - %@", error))
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            handler(nil, error)
                        })
                        return
                    }
                }
                else if mimeType == "text/html" {
                    let stringEncoding = self.parseStringEncodingFromResponseHeader(response!)
                    let htmlString = String(data: data!, encoding: stringEncoding)
                    let responseDictionary: Dictionary<String, String> = ["html":htmlString!]
                    
                    logMessage(NSString(format: "Response : %@", String(responseDictionary)))
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handler(responseDictionary,error)
                    })
                    return
                }
                else {
                    var userInfo: Dictionary<String, String> = Dictionary()
                    userInfo[NSLocalizedDescriptionKey] = String(format: "UnSupported Mime Type : %@", mimeType!)
                    let mimeTypeError = NSError(domain: "com.nav.ios", code: 502, userInfo: userInfo)
                    
                    logMessage(NSString(format: "Response : Mime Type Error - %@", mimeTypeError))
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handler(nil,mimeTypeError)
                    })
                    return
                }
            }
            else {
                var userInfo: Dictionary<String, String> = Dictionary()
                userInfo[NSLocalizedDescriptionKey] = NSHTTPURLResponse.localizedStringForStatusCode((httpResponse?.statusCode)!)
                let httpError = NSError(domain: "HTTP Error", code: (httpResponse?.statusCode)!, userInfo: userInfo)
                
                logMessage(NSString(format: "Response : HTTP Error - %@", httpError))
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler(nil,httpError)
                })
                return
            }
        }
        
//        requestOperationQueue().addOperationWithBlock { () -> Void in
            dataTask.resume()
//        }
    }
}
