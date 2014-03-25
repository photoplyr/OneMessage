//
//  UserProxy.h
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserProxy : NSObject

@property (nonatomic, copy) NSString * email;
@property (nonatomic, copy) NSString * password;
@property (nonatomic, copy) NSString * pin;
@property (nonatomic, copy) NSString * sessionKey;
@property (nonatomic, copy) NSString * userName;
@property (nonatomic, copy) NSString * companyLogo;

+ (UserProxy *) instance;

@end
