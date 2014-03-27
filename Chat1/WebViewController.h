//
//  WebViewController.h
//  OneLogin
//
//  Created by Troy Simon on 2/3/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProxy.h"
#import "PersistentDataProxy.h"
#import "WebServiceDelegate.h"

static NSString *const kKeychainPasscode = @"oneLogin";
static NSString *const kKeychainServiceName = @"oneMessager";


@interface WebViewController : UIViewController <WebServiceDelegate>

@property(weak,nonatomic) IBOutlet UIWebView *web;
@property(weak,nonatomic) IBOutlet UILabel *peasewait;
@end
