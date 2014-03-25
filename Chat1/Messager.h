//
//  Messager.h
//  OneChat
//
//  Created by Troy Simon on 3/18/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Messager : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * dirty;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * soid;
@property (nonatomic, retain) NSString * toid;
@property (nonatomic, retain) NSNumber * uploaded;

@end
