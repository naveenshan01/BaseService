//
//  BaseService.h
//  <>
//
//  Created by Naveen Shan.
//  Copyright © 2015. All rights reserved.
//

//#define RequestLog(s, ...)
#define RequestLog(s, ...) NSLog(@"HTTPRequest : %@", [NSString stringWithFormat: s, ##__VA_ARGS__])

#import <Foundation/Foundation.h>

@interface BaseService : NSObject

+ (NSOperationQueue *)requestOperationQueue;

#pragma mark -

- (BOOL)networkAvailable;

#pragma mark -

+ (NSString *)baseURL;
+ (void)setBaseURL:(NSString *)baseURL;

+ (void)enableDebug:(BOOL)enable;
+ (void)setRequestTimeout:(int)seconds;

#pragma mark -

+ (NSStringEncoding)parseStringEncodingFromResponseHeader:(NSURLResponse *)response;

#pragma mark -

+ (NSString *)completePostBody:(NSString *)requestBody;
+ (NSString *)serializedStringForParameters:(NSDictionary *)parameters;

+ (NSURL *)URLWithUTF8EncodedString:(NSString *)urlString;

#pragma mark -

+ (NSMutableURLRequest *)requestWithMethod:(NSString *)method urlString:(NSString *)urlString;
+ (NSMutableURLRequest *)soapPostRequestWithURLString:(NSString *)urlString soapAction:(NSString *)soapAction parameters:(id)parameters;

+ (NSMutableURLRequest *)jsonGetRequestWithURLString:(NSString *)urlString;
+ (NSMutableURLRequest *)jsonGetRequestWithBaseURL:(NSString *)urlString parameters:(id)parameters;
+ (NSMutableURLRequest *)jsonPostRequestWithURLString:(NSString *)urlString parameters:(id)parameters;

#pragma mark -

+ (void)sendRequest:(NSURLRequest *)request
  completionHandler:(void (^)(NSDictionary*, NSError*))handler;

+ (void)sendSessionRequest:(NSURLRequest *)request
         completionHandler:(void (^)(NSDictionary*, NSError*))handler;

@end
