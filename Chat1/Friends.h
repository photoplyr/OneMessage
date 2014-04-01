//
//  Friends.h
//  OneMessage
//
//  Created by Troy Simon on 4/1/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Friends : NSManagedObject

@property (nonatomic, retain) NSNumber * approved;
@property (nonatomic, retain) NSNumber * badge;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * publickey;
@property (nonatomic, retain) NSData * symkey;
@property (nonatomic, retain) NSString * token;

@end
