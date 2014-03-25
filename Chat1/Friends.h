//
//  Friends.h
//  OneMessage
//
//  Created by Troy Simon on 3/21/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Friends : NSManagedObject

@property (nonatomic, retain) NSNumber * badge;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSData * key;

@end
