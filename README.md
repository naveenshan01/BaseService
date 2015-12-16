# BaseService
An easy to integrate base class for network api call in iOS using NSURLSession and Block based a architecture.

It supports both JSON and SOAP API's

To Integrate,
- Create a Subclass of BaseService.
- Add all api call's like the example did in ExampleService class.
- Call API in Block based method.

```
    [[ExampleService sharedInstance] getAllUserSampleWithCompletionHandler:^(NSDictionary *details, NSError *error) {
        
    }];
    
    // In BaseService subclass : ExampleService
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
```

With Parameters
```
    [[ExampleService sharedInstance] getUserDetailsForUser:nil withCompletionHandler:^(NSDictionary *details, NSError *error)     {
        
    }];
    
    // In BaseService subclass : ExampleService
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
```

For SOAP API
```

// In BaseService subclass : ExampleService
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
```
