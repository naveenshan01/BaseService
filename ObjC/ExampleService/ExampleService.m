//
//  ExampleService.m
//  <>
//
//  Created by Naveen Shan.
//  Copyright © 2015. All rights reserved.
//

#import "ExampleService.h"

@implementation ExampleService

#pragma mark -

+ (instancetype)sharedInstance {
    static ExampleService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        
        // Normal we need to set this once in app on app launch.
        // Or if we required we can append along with url string, No need to set base url.
        [[self class] setBaseURL:@"http://jsonplaceholder.typicode.com"];
    });
    return instance;
}

#pragma mark - JSON Examples

- (void)getAllUsersWithCompletionHandler:(void (^)(NSDictionary *details, NSError *error))handler {
    NSString *urlSring = [NSString stringWithFormat:@"%@/users",[[self class] baseURL]];
    NSURLRequest *request = [[self class] jsonGetRequestWithURLString:urlSring];
    [[self class] sendSessionRequest:request completionHandler:^(NSDictionary *response, NSError *responseError) {
        if(responseError) {
            handler(nil,responseError);
        } else {
            handler(response,nil);
        }
    }];
}

// Moke api wouldn't work.
- (void)getUserDetailsForUser:(NSString *)userId withCompletionHandler:(void (^)(NSDictionary *details, NSError *error))handler {
    NSString *urlSring = [NSString stringWithFormat:@"%@/users",[[self class] baseURL]];
    NSDictionary *requestParameters = @{@"UserId":userId};
    NSURLRequest *request = [[self class] jsonPostRequestWithURLString:urlSring parameters:requestParameters];
    [[self class] sendSessionRequest:request completionHandler:^(NSDictionary *response, NSError *responseError) {
        if(responseError) {
            handler(nil,responseError);
        } else {
            handler(response,nil);
        }
    }];
}

#pragma mark - SOAP Examples

// Moke api wouldn't work.
- (void)getAllUserSampleWithCompletionHandler:(void (^)(NSDictionary *details, NSError *error))handler {
    NSString *urlSring = @"https://webservice.exacttarget.com/Service.asmx";
    NSURLRequest *request = [[self class] soapPostRequestWithURLString:urlSring soapAction:@"http://exacttarget.com/wsdl/partnerAPI" parameters:nil];
    [[self class] sendSessionRequest:request completionHandler:^(NSDictionary *response, NSError *responseError) {
        if(responseError) {
            handler(nil,responseError);
        } else {
            handler(response,nil);
        }
    }];
}

@end
