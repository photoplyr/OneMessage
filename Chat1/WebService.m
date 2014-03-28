//
//  WebService.m
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import "WebService.h"
#import "NSDictionary+UrlEncoding.h"
#import "UserProxy.h"


@implementation WebService
{
    AppDelegate *appdelegate;
    NSNumber *filesize;
}

@synthesize delegate = _delegate;
@synthesize url = _url;
@synthesize responseData = _responseData;
@synthesize connection = _connection;
@synthesize statusCode = _statusCode;
@synthesize params = _params;
@synthesize requiresSessionToken = _requiresSessionToken;
@synthesize data = _data;
@synthesize minRequiredStatusCode = _minRequiredStatusCode;

- (id)initWithParams:(NSMutableDictionary*)params
{
    self = [super init];
    
    if(!params) params = [NSMutableDictionary dictionary];
    self.params = params;
    self.minRequiredStatusCode = 300;
    
    self.requiresSessionToken = YES;
    
    appdelegate = [[UIApplication sharedApplication] delegate];

    return self;
}

- (NSString *)completeNotification
{
    return nil;
}

- (NSString *)action
{
    return nil;
}

- (NSString *)HTTPMethod
{
    return @"GET";
}

- (NSString *)buildHTTPBody
{
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString* version = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    [self.params setObject:version forKey:@"version"];
    
    //Test code
    [self.params setObject:[UserProxy instance].sessionKey forKey:@"session_token"];

    return [self.params urlEncodedString];
}

#pragma mark - Command

- (NSString*)buildUrl
{
    NSLog(@"%@%@%@/%@", API_PROTOCOL, API_DOMAIN, API_VERSION, [self action]);
    return [NSString stringWithFormat:@"%@%@%@/%@", API_PROTOCOL, API_DOMAIN, API_VERSION, [self action]];
}

- (void)execute
{
    self.responseData = [NSMutableData data];
    
    self.url = [self buildUrl];
    NSString * httpBody = [self buildHTTPBody];
    
    if([[self HTTPMethod] isEqualToString:@"GET"])
    {
        self.url = [self.url stringByAppendingFormat:@"?%@", httpBody];
    }
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [request setValue: WEBAGENTIPAD forHTTPHeaderField: @"User-Agent"]; // Or any other User-Agent value.
    else
      [request setValue: WEBAGENTIPHONE forHTTPHeaderField: @"User-Agent"]; // Or any other User-Agent value.
    
    
    if([[self HTTPMethod] isEqualToString:@"POST"])
    {
        [request setHTTPBody:[httpBody dataUsingEncoding:NSASCIIStringEncoding]];
    }
    
	[request setHTTPMethod:[self HTTPMethod]];
    [request setHTTPShouldHandleCookies:NO];
    
    NSLog(@"WebService.execute: %@",[[request URL] absoluteString]);
    
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    [self.connection start];
}


#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	// this is to ignore certificates problem
	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.responseData setLength:0];
	self.statusCode = [(NSHTTPURLResponse *)response statusCode];
    NSLog(@"self.statusCode: %ld", self.statusCode);
    
    filesize = [NSNumber numberWithLongLong:[response expectedContentLength]];
    NSLog(@"content-length: %@ bytes", filesize);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.responseData appendData:data];
    
    NSNumber *resourceLength = [NSNumber numberWithUnsignedInteger:[self.responseData length]];
    NSLog(@"resourceData length: %d", [resourceLength intValue]);
    NSLog(@"filesize: %f", [filesize doubleValue]);
    NSLog(@"float filesize: %f", [filesize floatValue]);
    //progressView.progress = [resourceLength floatValue] / [self.filesize floatValue];
    NSLog(@"progress: %f", [resourceLength floatValue] / [filesize floatValue]);

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *data = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    self.data = data;
    
    NSLog(@"connectionDidFinishLoading :: responseData: %@", data);
    
    if(self.statusCode < 300)
    {
        [self parseData];
    }
    else
    {
        [self parseError];
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"connection.didFailWithError: %@", error);
    
    if(self.delegate)
    {
        [self.delegate webServiceDidFailWithError:@"error"];
    }
}


- (void)parseData
{
    NSLog(@"parseData");
}

- (void)parseError
{
    if(self.delegate)
    {
        [self.delegate webServiceDidFailWithError:self.data];
    }
}

- (void)dispatchComplete
{
    NSLog(@"dispatchComplete: %@", self.delegate);
    if(self.delegate)
    {
        [self.delegate webServiceDidFinishWithSuccess:self.data];
    }
    
    if([self completeNotification])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:[self completeNotification] object:self];
    }
}

#pragma mark - memory

- (void)dealloc
{
    self.delegate = nil;
    self.connection = nil;
    self.url = nil;
    self.responseData = nil;
    
}

@end
