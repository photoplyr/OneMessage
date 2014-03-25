//
//  AppDelegate.h
//  Chat1
//
//  Created by Troy Simon on 3/17/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Messager.h"
#import "Friends.h"

#import "MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "MMExampleDrawerVisualStateManager.h"

#import "SecKeyWrapper.h"
#import "CryptoCommon.h"

#import "SFHFKeychainUtils.h"

#import <Parse/Parse.h>

#define NEWMESSAGE @"NewMessage"
#define CHANNELREADY @"channelReady"
#define HIDEKEYBOARD @"hidekeyboard"
#define APPNAME @"OneMessage"

#define DATA_FILE @"ol_data.plist"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (assign) MMDrawerController * drawerController;
@property (copy) NSString *deviceUuid;
@property BOOL locked;
@property (copy) NSString *tokensource;
@property (copy) NSString *tokentarget;

@property (copy) NSData *publickey;
@property (copy) NSData *targetkey;
@property (copy) NSData *symkey;

-(void) closeDrawer;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

-(NSArray *) getMessages;
-(void) addMessage:(NSString *) message from:(NSString *)siod to:(NSString *)toid forDate:(NSDate *) date;
-(void) addFriend:(NSString *) name withToken:(NSString *) token withKey:(NSData *) key withBadge:(int) badge;
-(NSArray *) getFriends;
@end
