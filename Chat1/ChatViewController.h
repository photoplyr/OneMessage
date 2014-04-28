//
//  MainViewController.h
//  Chat1
//
//  Created by Troy Simon on 3/17/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//


#import "JSMessagesViewController.h"


@interface ChatViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>


@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSDictionary *avatars;
@property (nonatomic, strong)  UIProgressView *progress;
- (NSString *)decryptMessage:(NSData *)blob;

@end
