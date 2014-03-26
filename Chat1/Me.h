//
//  Me.h
//  OneMessage
//
//  Created by Troy Simon on 3/26/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Me : NSManagedObject

@property (nonatomic, retain) NSNumber * badge;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * publickey;
@property (nonatomic, retain) NSData * symkey;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * lastchattoken;

@end
