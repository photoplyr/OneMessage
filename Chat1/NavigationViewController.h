//
//  NavigationViewController.h
//  OneChat
//
//  Created by Troy Simon on 3/18/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface NavigationViewController : UINavigationController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end
