//
//  UserProxy.m
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import "UserProxy.h"

@implementation UserProxy

@synthesize email = _email;
@synthesize password = _password;
@synthesize pin = _pin;
@synthesize sessionKey = _sessionKey;
@synthesize userName = _userName;
@synthesize companyLogo = _companyLogo;


static UserProxy * _instance = nil;

+ (UserProxy *) instance
{
    if(_instance == nil)
    {
        _instance = [[UserProxy alloc] init];
    }
    
    return _instance;
}

- (id)init
{
    self = [super init];
    
    self.email = @"";
    self.pin = @"";
    self.password = @"";
    self.sessionKey = @"";
    self.userName = @"";
    self.companyLogo = @"";
    
    return self;
}

@end
