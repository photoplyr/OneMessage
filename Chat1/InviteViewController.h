//
//  InviteViewController.h
//  OneMessage
//
//  Created by Troy Simon on 3/28/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Friends.h"

@interface InviteViewController : UIViewController

@property (nonatomic,weak) IBOutlet UILabel *name;
@property (nonatomic) Friends *friend;
@end
