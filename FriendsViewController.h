//
//  FriendsViewController.h
//  OneMessage
//
//  Created by Troy Simon on 3/19/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Friends.h"
#import "FriendTableViewCell.h"

@interface FriendsViewController : UITableViewController

@property (strong, nonatomic) NSArray *friends;

@end
