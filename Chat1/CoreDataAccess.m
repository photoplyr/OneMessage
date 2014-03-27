//
//  CoreDataAccess.m
//  OneMessage
//
//  Created by Troy Simon on 3/27/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import "CoreDataAccess.h"
#import "AppDelegate.h"

@implementation CoreDataAccess

static BOOL useinside = NO;
static id _sharedObject = nil;

+(id) alloc {
    if (!useinside) {
        @throw [NSException exceptionWithName:@"Singleton Vialotaion" reason:@"You are violating the singleton class usage. Please call +sharedInstance method" userInfo:nil];
    }
    else {
        return [super alloc];
    }
}

+(id)sharedInstance
{
    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        useinside = YES;
        _sharedObject = [[CoreDataAccess alloc] init];
        useinside = NO;
    });
    // returns the same object each time
    return _sharedObject;
}


@end