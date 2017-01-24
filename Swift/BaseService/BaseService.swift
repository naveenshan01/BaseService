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
var serviceQueue: OperationQueue?

public class BaseService: NSObject {
    
    public class func requestOperationQueue() -> OperationQueue {
        if serviceQueue == nil {
            serviceQueue = OperationQueue()
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
    
    class func logMessage(message: String) {
        if(kDebugEnabled) {
            NSLog("%@", message)
        }
    }
    
    //MARK: - Host Name From URL
    
    class func hostNameFromURL(urlString: String?) -> String? {
        var hostName: String? = nil
        
        if var url = urlString, urlString != nil && url.characters.count > 0 {
            url = url.replacingOccurrences(of: "https://", with: "")
            url = url.replacingOccurrences(of: "http://", with: "")
            
            let hostParts = url.components(separatedBy: "/")
            hostName = hostParts[0]
        }

        if hostName == nil {
            NSLog("Exception on hostNameFromURL - \(urlString)")
        }
        return hostName
    }
    
    class func domainNameFromURL(urlString: String?) -> String? {
        var domainName: String? = nil
        let hostName = self.hostNameFromURL(urlString: urlString)
        
        if let host = hostName, hostName != nil && host.characters.count > 0 {
            let hostNameParts = host.components(separatedBy: "/")
            let noOfParts = hostNameParts.count
            domainName = hostNameParts[noOfParts-2]
        }
        if domainName == nil {
            NSLog("Exception on domainNameFromURL - \(urlString)")
        }
        return domainName
    }
    
    //MARK: -
    
    class func truncateSoapHeaders(dictionary: Dictionary<String, AnyObject>) -> Dictionary<String, AnyObject> {
        var dictionary = dictionary
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
    
    public class func serializedString(parameters: Dictionary<String, AnyObject>) -> String {
        var queryString: String? = nil
        let keys = parameters.keys
        if keys.count > 0 {
            for key in keys {
                var value: AnyObject? = parameters[key]
                if queryString == nil {
                    queryString = ""
                }
                if let aValue = value as? Dictionary<String, AnyObject> {
                    value = self.serializedString(parameters: aValue) as AnyObject?
                }
                if value != nil {
                    queryString = queryString! + String(format: "<%@>%@</%@>", key, (value as? String)! , key)
                }
            }
        }
        return queryString!
    }
    
    
    //MARK: -
    
    public class func URLWithUTF8EncodedString(urlString: String?) -> URL? {
        guard let stringURL = urlString, urlString != nil && stringURL.characters.count > 0 else {
            return nil
        }
        let urlwithPercentEscapes = stringURL.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)

        var url: URL? = nil
        if urlwithPercentEscapes != nil {
            url = URL(string: urlwithPercentEscapes!)
        }
        return url
    }
    
    public class func requestWithMethod(method: String, urlString: String) -> URLRequest? {
        let url = self.URLWithUTF8EncodedString(urlString: urlString)
        guard let encodedURL = url, url != nil else {
            return nil
        }
        var request = URLRequest(url: encodedURL, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.httpMethod = method
        return request
    }
    
    public class func soapPostRequestWithURLString(urlString: String, soapAction: String?, parameters: AnyObject?) -> URLRequest? {
        let url = self.URLWithUTF8EncodedString(urlString: urlString)
        guard let encodedURL = url, url != nil else {
            return nil
        }
        var request = URLRequest(url: encodedURL, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.httpMethod = "POST"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(self.hostNameFromURL(urlString: urlString), forHTTPHeaderField: "Host")
        request.setValue(self.domainNameFromURL(urlString: urlString), forHTTPHeaderField: "Domain")
        
        if soapAction != nil {
            request.setValue(soapAction, forHTTPHeaderField: "SOAPAction")
        }
        
        if parameters != nil {
            var serializedParameterString: String? = nil
            if let theParameters = parameters as? Dictionary<String, AnyObject> {
                serializedParameterString = self.serializedString(parameters: theParameters)
            }
            else {
                serializedParameterString = parameters as? String
            }
            
            serializedParameterString = self.completePostBody(requestBody: serializedParameterString)
            var strContentLength: String? = String(format: "%lu", (serializedParameterString?.characters.count)!)
            if strContentLength != nil {
                request.setValue(strContentLength, forHTTPHeaderField: "Content-Length")
            }
            strContentLength = nil
            
            var postData = serializedParameterString?.data(using: String.Encoding.utf8)
            serializedParameterString = nil
            
            if postData != nil && (postData?.count)! > 0 {
                request.httpBody = postData
            }
            postData = nil
        }
        
        return request
    }
    
    //MARK: -
    
    public class func jsonGetRequestWithURLString(urlString: String) -> URLRequest? {
        let url = self.URLWithUTF8EncodedString(urlString: urlString)
        guard let encodedURL = url, url != nil else {
            return nil
        }
        var request = URLRequest(url: encodedURL, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logMessage(message: String(format: "Request URL : %@", urlString))
        
        return request
    }
    
    public class func jsonGetRequestWithBaseURL(urlString: String, parameters: AnyObject) -> URLRequest? {
        var components = URLComponents(string: urlString)
        var queryItems: Array<URLQueryItem> = Array()
        let theParameters = parameters as? Dictionary<String, AnyObject>
        for key in (theParameters?.keys)! {
            let value = parameters[key] as? String
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            return nil
        }
        
        var request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        logMessage(message: String(format: "Request URL : %@", urlString))
        
        return request
    }
    
    public class func jsonPostRequestWithURLString(urlString: String, parameters: AnyObject?) -> URLRequest? {
        guard let url = self.URLWithUTF8EncodedString(urlString: urlString) else {
            return nil
        }
        var request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: Double(kRequestTimeout))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if (parameters != nil) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: parameters!, options: JSONSerialization.WritingOptions.prettyPrinted)
                let strContentLength = String(format: "%lu", jsonData.count)
                request.setValue(strContentLength, forHTTPHeaderField: "Content-Length")
                if jsonData.count > 0 {
                    request.httpBody = jsonData
                }
            }
            catch let error as NSError {
                NSLog("Fail to create JSON : %@",error.description);
            }
        }
        
        logMessage(message: String(format: "Request URL : %@", urlString))
        logMessage(message: String(format: "Request Parameters : %@", String(describing: parameters)))
        
        return request;
    }
    
    //MARK: -
    
    public class func sendRequest(request: URLRequest, completionHandler handler:@escaping ((Dictionary<String, AnyObject>?, Error?) -> Void)){
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let dataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if error != nil {
                logMessage(message: String(format: "Response : Error - %@", error?.localizedDescription ?? " "))
                DispatchQueue.main.async {
                    handler(nil, error)
                }
                return
            }
            let httpResponse = response as? HTTPURLResponse
            logMessage(message: String(format: "Response : Error - %@", httpResponse ?? " "))
            if httpResponse?.statusCode == 200 {   // success
                let mimeType = response?.mimeType
                
                if mimeType == "text/xml" ||
                    mimeType == "application/xml" {
                    let parseError: Error? = nil
                    var xmlDictionary: Dictionary<String, AnyObject> = Dictionary()
                    if parseError != nil {
                        logMessage(message: String(format: "Response : Parse Error - %@", parseError?.localizedDescription ?? " "))
                        DispatchQueue.main.async {
                            handler(nil, parseError)
                        }
                        return
                    }
                    xmlDictionary = self.truncateSoapHeaders(dictionary: xmlDictionary)
                    
                    logMessage(message: String(format: "Response : %@ ", String(describing: xmlDictionary)))
                    DispatchQueue.main.async {
                        handler(xmlDictionary, error)
                    }
                    return;
                }
                else if mimeType == "application/json" {
                    do {
                        let jsonDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)

                        logMessage(message: String(format: "Response : %@ ", String(describing: jsonDictionary)))
                        DispatchQueue.main.async {
                            if let jsonResult = jsonDictionary as? Dictionary<String, AnyObject> {
                                handler(jsonResult, error)
                            }
                            else {
                                handler(nil, error)
                            }
                        }
                        return
                    }
                    catch let error as NSError {
                        logMessage(message: String(format: "Response : Parse Error - %@", error.localizedDescription))
                        DispatchQueue.main.async {
                            handler(nil, error)
                        }
                        return
                    }
                }
                else if mimeType == "text/html" {
                    let stringEncoding = String.Encoding.utf8
                    let htmlString = String(data: data!, encoding: stringEncoding)
                    let responseDictionary: Dictionary<String, AnyObject> = ["html":htmlString! as AnyObject]
                    
                    logMessage(message: String(format: "Response : %@", String(describing: responseDictionary)))
                    DispatchQueue.main.async {
                        handler(responseDictionary, error)
                    }
                    return
                }
                else {
                    var userInfo: Dictionary<String, String> = Dictionary()
                    userInfo[NSLocalizedDescriptionKey] = String(format: "UnSupported Mime Type : %@", mimeType ?? "Empty")
                    let mimeTypeError = NSError(domain: "com.nav.ios", code: 502, userInfo: userInfo)
                    
                    logMessage(message: String(format: "Response : Mime Type Error - %@", mimeTypeError))
                    DispatchQueue.main.async {
                        handler(nil, mimeTypeError)
                    }
                    return
                }
            }
            else {
                var userInfo: Dictionary<String, String> = Dictionary()
                userInfo[NSLocalizedDescriptionKey] = HTTPURLResponse.localizedString(forStatusCode: (httpResponse?.statusCode)!)
                let httpError = NSError(domain: "HTTP Error", code: (httpResponse?.statusCode)!, userInfo: userInfo)
                
                logMessage(message: String(format: "Response : HTTP Error - %@", httpError))
                DispatchQueue.main.async {
                    handler(nil, httpError)
                }
                return
            }
        }

        dataTask.resume()
    }
}
