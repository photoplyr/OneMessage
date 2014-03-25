//
//  PersistentDataProxy.m
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import "PersistentDataProxy.h"
#import "Util.h"
#import "UserProxy.h"
#import "AppDelegate.h"

@implementation PersistentDataProxy

@synthesize localData = _localData;

- (void)saveLocalData
{
    self.localData = [NSMutableDictionary dictionary];
    
    [self.localData setObject:[UserProxy instance].sessionKey forKey:@"sessionKey"];
    [self.localData setObject:[UserProxy instance].pin forKey:@"pin"];
    
    [self.localData writeToFile:[Util filePathForFileName:DATA_FILE] atomically:YES];
}


- (void)loadLocalData
{
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile: [Util filePathForFileName:DATA_FILE]];
    self.localData = [NSMutableDictionary dictionaryWithDictionary:dict];
    
    NSLog(@"localData: %@", self.localData);
    
    if([self.localData objectForKey:@"pin"]) [UserProxy instance].pin = [self.localData objectForKey:@"pin"];
    if([self.localData objectForKey:@"sessionKey"]) [UserProxy instance].sessionKey = [self.localData objectForKey:@"sessionKey"];
    //[RTCUserProxy instance].role = [dict objectForKey:kUserRoleKey];
    //[RTCUserProxy instance].user = [RTCUser createFromDict:[dict objectForKey:kUserDataKey]];
}



static PersistentDataProxy * _instance = nil;

+ (PersistentDataProxy *) instance
{
    if(_instance == nil)
    {
        _instance = [[PersistentDataProxy alloc] init];
    }
    
    return _instance;
}

@end
