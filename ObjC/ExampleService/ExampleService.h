//
//  ExampleService.h
//  <>
//
//  Created by Naveen Shan.
//  Copyright © 2015. All rights reserved.
//

#import "BaseService.h"

@interface ExampleService : BaseService

#pragma mark -

+ (instancetype)sharedInstance;

#pragma mark - JSON Examples

- (void)getAllUsersWithCompletionHandler:(void (^)(NSDictionary *details, NSError *error))handler;

- (void)getUserDetailsForUser:(NSString *)userId withCompletionHandler:(void (^)(NSDictionary *details, NSError *error))handler;

- (void)getAllUserSampleWithCompletionHandler:(void (^)(NSDictionary *details, NSError *error))handler;

@end
