//
//  BaseService.m
//  <>
//
//  Created by Naveen Shan.
//  Copyright © 2015. All rights reserved.
//

#import "BaseService.h"

static BOOL kDebugEnabled = YES;
static int kRequestTimeout = 30;
static NSString *baseURLString = nil;
static NSOperationQueue *serviceQueue = nil;

@implementation BaseService

+ (NSOperationQueue *)requestOperationQueue {
    if (!serviceQueue) {
        serviceQueue = [[self alloc] init];
    }
    return serviceQueue;
}

#pragma mark -

// TODO : Do logic for network check if pre network check required.
- (BOOL)networkAvailable {
    return YES;
}

#pragma mark - Setup

+ (NSString *)baseURL {
    return baseURLString;
}

+ (void)setBaseURL:(NSString *)baseURL {
    baseURLString = baseURL;
}

+ (void)enableDebug:(BOOL)enable {
    kDebugEnabled = enable;
}

+ (void)setRequestTimeout:(int)seconds {
    kRequestTimeout = seconds;
}

+ (void)logMessage:(NSString *)message {
    if (kDebugEnabled) {
        RequestLog(@"%@",message);
    }
}

#pragma mark - Host Name From Request URL

+ (NSString *)hostNameFromURL:(NSString *)urlString    {
    NSString *hostName = nil;
    @try {
        if (urlString != nil && [urlString length] > 0) {
            //Check whether URL contains http:// or https://
            if ([urlString rangeOfString:@"https://"].location != NSNotFound)   {
                NSString *hostString =   [urlString stringByReplacingOccurrencesOfString:@"https://" withString:@""];
                NSArray *hostParts = [hostString componentsSeparatedByString:@"/"];
                
                hostName = [hostParts objectAtIndex:0];
                hostParts = nil;
            } else if ([urlString rangeOfString:@"http://"].location != NSNotFound)   {
                NSString *hostString = [urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
                NSArray *hostParts = [hostString componentsSeparatedByString:@"/"];
                
                hostName = [hostParts objectAtIndex:0];
                hostParts = nil;
                hostString = nil;
            } else {
                NSArray *hostParts = [urlString componentsSeparatedByString:@"/"];
                
                hostName = [hostParts objectAtIndex:0];
                hostParts = nil;
            }
        }
    }
    @catch (NSException *exception) {
        hostName =   nil;
        RequestLog(@"Exception on hostNameFromURL - %@ : %@",urlString,[exception description]);
    }
    @finally {
        return hostName;
    }
    return hostName;
}

+ (NSString *)domainNameFromURL:(NSString *)urlString  {
    NSString *domainName =   nil;
    @try {
        NSString *hostName = [[self class] hostNameFromURL:urlString];
        if (hostName != nil && [hostName length] > 0)   {
            NSArray *hostNameParts  =   [hostName componentsSeparatedByString:@"."];
            NSUInteger noOfParts   =   [hostNameParts count];
            
            domainName  =   [hostNameParts objectAtIndex:noOfParts-2];
            hostNameParts = nil;
        }
    }
    @catch (NSException *exception) {
        domainName =   nil;
        RequestLog(@"Exception on domainNameFromURL - %@ : %@",urlString,[exception description]);
    }
    @finally {
        return domainName;
    }
    return domainName;
}

#pragma mark - MimeType From Response Header

+ (void)parseMimeType:(NSString **)mimeType andResponseEncoding:(NSStringEncoding *)stringEncoding fromContentType:(NSString *)contentType  {
	if (!contentType) {
		return;
	}
	NSScanner *charsetScanner = [NSScanner scannerWithString: contentType];
	if (![charsetScanner scanUpToString:@";" intoString:mimeType] || [charsetScanner scanLocation] == [contentType length]) {
		*mimeType = [contentType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        charsetScanner = nil;
		return;
	}
	*mimeType = [*mimeType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *charsetSeparator = @"charset=";
	NSString *IANAEncoding = nil;
    
	if ([charsetScanner scanUpToString: charsetSeparator intoString: NULL] && [charsetScanner scanLocation] < [contentType length]) {
		[charsetScanner setScanLocation: [charsetScanner scanLocation] + [charsetSeparator length]];
		[charsetScanner scanUpToString: @";" intoString: &IANAEncoding];
	}
	if (IANAEncoding) {
		CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANAEncoding);
		if (cfEncoding != kCFStringEncodingInvalidId) {
			*stringEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
		}
	}
    charsetScanner = nil;
}

+ (NSStringEncoding)parseStringEncodingFromResponseHeader:(NSURLResponse *)response  {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	//to Handle response text encoding
	NSStringEncoding charset = 0;
	NSString *mimeType = nil;
	[[self class] parseMimeType:&mimeType andResponseEncoding:&charset fromContentType:[[httpResponse allHeaderFields] valueForKey:@"Content-Type"]];
	if (charset != 0) {
		return charset;
	} else {
        //by default we use - NSASCIIStringEncoding
		return NSASCIIStringEncoding;
	}
}

+ (NSString *)parseMimeTypeFromResponseHeader:(NSURLResponse *)response  {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	//to Handle response text encoding
	NSStringEncoding charset = 0;
	NSString *mimeType = nil;
	[[self class] parseMimeType:&mimeType andResponseEncoding:&charset fromContentType:[[httpResponse allHeaderFields] valueForKey:@"Content-Type"]];
	return mimeType;
}

#pragma mark - Request Helpers

+ (NSDictionary *)truncateSoapHeaders:(NSDictionary *)dictionary    {
    if ([dictionary objectForKey:@"soap:Envelope"]) {
        dictionary = [dictionary objectForKey:@"soap:Envelope"];
        if ([dictionary objectForKey:@"soap:Body"]) {
            dictionary = [dictionary objectForKey:@"soap:Body"];
        }
    }
    return dictionary;
}

#pragma mark -

+ (NSString *)completePostBody:(NSString *)requestBody   {
    NSString *completePostBody = nil;
    if (requestBody != nil) {
        //appending POST body with Request Body
        completePostBody  =   [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                               "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                               "<soap:Body>\n"
                               "%@\n"
                               "</soap:Body>\n"
                               "</soap:Envelope>\n",requestBody];
    }
    else    {
        //empty POST body
        completePostBody  =   [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                               "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
                               "<soap:Body>\n"
                               "</soap:Body>\n"
                               "</soap:Envelope>\n"];
    }
    return completePostBody;
}

+ (NSString *)serializedStringForParameters:(NSDictionary *)parameters  {
    NSMutableString *queryString = nil;
    NSArray *keys = [parameters allKeys];
    
    if ([keys count] > 0) {
        for (id key in keys) {
            id value = [parameters objectForKey:key];
            if (!queryString) {
                queryString = [[NSMutableString alloc] init];
            }
            if ([value isKindOfClass:[NSDictionary class]]) {
                value = [[self class] serializedStringForParameters:value];
            }
            if (key && value) {
                [queryString appendFormat:@"<%@>%@</%@>", key, value , key];
            }
        }
    }
    
    return queryString;
}

#pragma mark -

+ (NSURL *)URLWithUTF8EncodedString:(NSString *)urlString {
    NSString *encodedUrlString = nil;
    if (urlString != nil && [NSNull null] != (NSNull *)urlString && [urlString length] > 0) {
        encodedUrlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    NSURL *url = nil;
    if (encodedUrlString) {
        url = [NSURL URLWithString:encodedUrlString];
    }
    return url;
}

+ (NSMutableURLRequest *)requestWithMethod:(NSString *)method urlString:(NSString *)urlString   {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[self class] URLWithUTF8EncodedString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kRequestTimeout];
    [request setHTTPMethod:method];
    
	return request;
}

#pragma mark - SOAP Request Methods

+ (NSMutableURLRequest *)soapPostRequestWithURLString:(NSString *)urlString soapAction:(NSString *)soapAction parameters:(id)parameters {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[self class] URLWithUTF8EncodedString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kRequestTimeout];
    
    [request setHTTPMethod:@"POST"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[[self class] hostNameFromURL:urlString] forHTTPHeaderField:@"Host"];
    [request setValue:[[self class] domainNameFromURL:urlString] forHTTPHeaderField:@"Domain"];
    
    if (soapAction) {
        [request setValue:soapAction forHTTPHeaderField:@"SOAPAction"];
    }
    
    if (parameters) {
        NSString *serializedParameterString = nil;
        if ([parameters isKindOfClass:[NSDictionary class]]) {
            serializedParameterString = [[self class] serializedStringForParameters:parameters];
        } else {
            serializedParameterString = parameters;
        }
        
        serializedParameterString = [[self class] completePostBody:serializedParameterString];
        
        NSString *strContentLength = [NSString stringWithFormat:@"%lu",(unsigned long)[serializedParameterString length]];
        if (strContentLength) {
            [request setValue:strContentLength forHTTPHeaderField:@"Content-Length"];
        }
        strContentLength = nil;
        
        NSMutableData *postData = (NSMutableData *)[serializedParameterString dataUsingEncoding:NSUTF8StringEncoding];
        serializedParameterString = nil;
        
        if (postData != nil && [postData length] > 0)   {
            [request setHTTPBody:postData];
        }
        postData = nil;
    }
    
    return request;
}

#pragma mark - JSON Request Methods

+ (NSMutableURLRequest *)jsonGetRequestWithURLString:(NSString *)urlString {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[self class] URLWithUTF8EncodedString:urlString]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:kRequestTimeout];
    
    [request setHTTPMethod:@"GET"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [self logMessage:[NSString stringWithFormat:@"Request URL : %@",urlString]];
    
    return request;
}

+ (NSMutableURLRequest *)jsonGetRequestWithBaseURL:(NSString *)urlString parameters:(id)parameters {
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in parameters) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:parameters[key]]];
    }
    components.queryItems = queryItems;
    
    NSURL *url = components.URL;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:kRequestTimeout];
    
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [self logMessage:[NSString stringWithFormat:@"Request URL : %@",urlString]];
    
    return request;
}

+ (NSMutableURLRequest *)jsonPostRequestWithURLString:(NSString *)urlString parameters:(id)parameters {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[self class] URLWithUTF8EncodedString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kRequestTimeout];
    
    [request setHTTPMethod:@"POST"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if (parameters) {
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            RequestLog(@"Fail to create JSON : %@",[error description]);
        }

        NSString *strContentLength = [NSString stringWithFormat:@"%lu",(unsigned long)[jsonData length]];
        if (strContentLength) {
            [request setValue:strContentLength forHTTPHeaderField:@"Content-Length"];
        }
        strContentLength = nil;
        
        if (jsonData != nil && [jsonData length] > 0)   {
            [request setHTTPBody:jsonData];
        }
        jsonData = nil;
    }
    
    [self logMessage:[NSString stringWithFormat:@"Request URL : %@",urlString]];
    [self logMessage:[NSString stringWithFormat:@"Request Parameters : %@",parameters]];
    
    return request;
}

#pragma mark - Request Handler

+ (void)sendRequest:(NSURLRequest *)request
  completionHandler:(void (^)(NSDictionary*, NSError*))handler {
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setName:@"HTTPRequest queue"];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)   {
                               
                               if (error) {
                                   [self logMessage:[NSString stringWithFormat:@"Response : Error - %@",error]];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       handler(nil,error);
                                   });
                                   return;
                               }
                               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                               [self logMessage:[NSString stringWithFormat:@"Http Response : %@",httpResponse]];
                               if ([httpResponse statusCode] == 200) { // Sccuess
                                   NSString *mimeType = [response MIMEType];
                                   
                                   if ([mimeType isEqualToString:@"text/xml"] ||
                                       [mimeType isEqualToString:@"application/xml"]) {
                                       NSError *parseError = nil;
                                       NSDictionary *xmlDictionary = [NSDictionary dictionary];
                                       if (parseError) {
                                           [self logMessage:[NSString stringWithFormat:@"Response : Parse Error - %@",parseError]];
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               handler(nil,parseError);
                                           });
                                           return;
                                       }
                                       xmlDictionary = [[self class] truncateSoapHeaders:xmlDictionary];
                                       
                                       [self logMessage:[NSString stringWithFormat:@"Response : %@ ",xmlDictionary]];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           handler(xmlDictionary,error);
                                       });
                                       return;
                                       
                                   } else if ([mimeType isEqualToString:@"application/json"]) {
                                       NSError *parseError = nil;
                                       NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
                                       if (parseError) {
                                           [self logMessage:[NSString stringWithFormat:@"Response : Parse Error - %@",parseError]];
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               handler(nil,parseError);
                                           });
                                           return;
                                       }
                                       
                                       [self logMessage:[NSString stringWithFormat:@"Response : %@ ",jsonDictionary]];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           handler(jsonDictionary,error);
                                       });
                                       return;
                                       
                                   } else if ([mimeType isEqualToString:@"text/html"]) {
                                       NSStringEncoding stringEncoding = [[self class] parseStringEncodingFromResponseHeader:response];
                                       NSString *htmlString = [[NSString alloc] initWithData:data encoding:stringEncoding];
                                       
                                       NSDictionary *responseDictionary = [NSDictionary dictionaryWithObjectsAndKeys:htmlString,@"html", nil];
                                       
                                       [self logMessage:[NSString stringWithFormat:@"Response : %@ ",responseDictionary]];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           handler(responseDictionary,error);
                                       });
                                       return;
                                   }
                                   else {
                                       NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                                       [userInfo setValue:[NSString stringWithFormat:@"UnSupported Mime Type : %@",mimeType] forKey:NSLocalizedDescriptionKey];
                                       NSError *mimeTypeError = [NSError errorWithDomain:@"com.response.app" code:502 userInfo:userInfo];

                                       [self logMessage:[NSString stringWithFormat:@"Response : Mime Type Error - %@",mimeTypeError]];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           handler(nil,mimeTypeError);
                                       });
                                       return;
                                   }
                               }
                               else {
                                   NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                                   [userInfo setValue:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]] forKey:NSLocalizedDescriptionKey];
                                   NSError *httpError = [NSError errorWithDomain:@"HTTP Error" code:[httpResponse statusCode] userInfo:userInfo];
                                   
                                   [self logMessage:[NSString stringWithFormat:@"Response : HTTP Error - %@",httpError]];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       handler(nil,httpError);
                                   });
                                   return;
                               }
                           }];
}

+ (void)sendSessionRequest:(NSURLRequest *)request
         completionHandler:(void (^)(NSDictionary*, NSError*))handler {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self logMessage:[NSString stringWithFormat:@"Response : Error - %@",error]];
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil,error);
            });
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        [self logMessage:[NSString stringWithFormat:@"Http Response : %@",httpResponse]];
        if ([httpResponse statusCode] == 200) { // Sccuess
            NSString *mimeType = [response MIMEType];
            if ([mimeType isEqualToString:@"text/xml"] ||
                [mimeType isEqualToString:@"application/xml"]) {
                NSError *parseError = nil;
                NSDictionary *xmlDictionary = [NSDictionary dictionary];
                if (parseError) {
                    [self logMessage:[NSString stringWithFormat:@"Response : Parse Error - %@",parseError]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(nil,parseError);
                    });
                    return;
                }
                xmlDictionary = [[self class] truncateSoapHeaders:xmlDictionary];
                
                [self logMessage:[NSString stringWithFormat:@"Response : %@ ",xmlDictionary]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(xmlDictionary,error);
                });
                return;
                
            } else if ([mimeType isEqualToString:@"application/json"]) {
                NSError *parseError = nil;
                NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseError];
                if (parseError) {
                    [self logMessage:[NSString stringWithFormat:@"Response : Parse Error - %@",parseError]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(nil,parseError);
                    });
                    return;
                }
                
                [self logMessage:[NSString stringWithFormat:@"Response : %@",jsonDictionary]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(jsonDictionary,error);
                });
                return;
                
            }
            else if ([mimeType isEqualToString:@"text/html"]) {
                NSStringEncoding stringEncoding = [[self class] parseStringEncodingFromResponseHeader:response];
                NSString *htmlString = [[NSString alloc] initWithData:data encoding:stringEncoding];
                
                NSDictionary *responseDictionary = [NSDictionary dictionaryWithObjectsAndKeys:htmlString,@"html", nil];
                
                [self logMessage:[NSString stringWithFormat:@"Response : %@",responseDictionary]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(responseDictionary,error);
                });
                return;
            }
            else {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                [userInfo setValue:[NSString stringWithFormat:@"UnSupported Mime Type : %@",mimeType] forKey:NSLocalizedDescriptionKey];
                NSError *mimeTypeError = [NSError errorWithDomain:@"com.nav.ios" code:402 userInfo:userInfo];
                
                [self logMessage:[NSString stringWithFormat:@"Response : Mime Type Error - %@",mimeTypeError]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(nil,mimeTypeError);
                });
                return;
            }
        }
        else {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]] forKey:NSLocalizedDescriptionKey];
            NSError *httpError = [NSError errorWithDomain:@"HTTP Error" code:[httpResponse statusCode] userInfo:userInfo];
            
            [self logMessage:[NSString stringWithFormat:@"Response : HTTP Error - %@",httpError]];
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil,httpError);
            });
            return;
        }
        
    }];
    
    [dataTask resume];
}

@end
