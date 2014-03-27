//
//  WebService.h
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebServiceDelegate.h"
#import "Command.h"
#import "AppDelegate.h"

@interface WebService : Command <NSURLConnectionDelegate, NSXMLParserDelegate>

@property (nonatomic, retain) id<WebServiceDelegate> delegate;
@property (nonatomic, retain) NSURLConnection * connection;
@property (nonatomic, retain) NSMutableData * responseData;
@property (nonatomic, retain) NSMutableDictionary * params;
@property (nonatomic, copy) NSString * data;
@property (nonatomic, copy) NSString * url;
@property (nonatomic, readwrite) int statusCode;
@property (nonatomic, readwrite) int minRequiredStatusCode;
@property (nonatomic, readwrite) BOOL requiresSessionToken;

- (id)initWithParams:(NSDictionary*)params;
- (NSString *)action;
- (NSString *)completeNotification;
- (NSString *)buildHTTPBody;
- (NSString *)HTTPMethod;
- (NSString*)buildUrl;
- (void)parseData;
- (void)parseError;
- (void)dispatchComplete;

@end
