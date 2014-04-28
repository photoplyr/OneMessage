//
//  PhotoViewController.h
//  OneMessage
//
//  Created by Troy Simon on 4/25/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoViewController : UIViewController
@property (nonatomic,strong) NSData *imageData;

@property (nonatomic,weak) IBOutlet UIImageView *image;
@end
