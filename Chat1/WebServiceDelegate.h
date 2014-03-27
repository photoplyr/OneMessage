//
//  WebServiceDelegate.h
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WebServiceDelegate <NSObject>

@required
- (void)webServiceDidFinishWithSuccess:(NSString *)data;
- (void)webServiceDidFailWithError:(NSString *)error;

@optional
- (void)webServiceDidFinishWithSuccessAndData:(NSDictionary*)dict;

@end
