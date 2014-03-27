//
//  UserInfoParser.h
//  OneLogin
//
//  Created by Jacob Bullock on 5/7/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import "XMLParser.h"

@interface UserInfoParser : XMLParser

@property (nonatomic, retain) NSMutableDictionary * userData;

@end
