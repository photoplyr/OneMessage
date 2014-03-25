//
//  PersistentDataProxy.h
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PersistentDataProxy : NSObject

@property (nonatomic, retain) NSMutableDictionary * localData;

- (void)saveLocalData;
- (void)loadLocalData;

+ (PersistentDataProxy *) instance;

@end
