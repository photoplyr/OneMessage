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
#import "Me.h"

#import "MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "MMExampleDrawerVisualStateManager.h"

#import "CoreDataAccess.h"

#import "SecKeyWrapper.h"
#import "CryptoCommon.h"

#import "SFHFKeychainUtils.h"

#import <Parse/Parse.h>

#define NEWMESSAGE @"NewMessage"
#define CHANNELREADY @"channelReady"
#define HIDEKEYBOARD @"hidekeyboard"
#define APPNAME @"OneMessage"

#define DATA_FILE @"ol_data.plist"

#define  MAX_ENTRIES_LOADED 100

#define GET_INFO_COMPLETE @"GET_INFO_COMPLETE"
#define API_PROTOCOL @"https://"
#define API_DOMAIN @"app.onelogin.com/mobile/"
#define API_VERSION  @"v1"
#define WEBAGENTIPHONE @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 7_1 like Mac OS X; en-us) AppleWebKit/531.21.20 (KHTML, like Gecko) Mobile/7B298g"
#define WEBAGENTIPAD @"Mozilla/5.0(iPad; U; CPU iPhone OS 7_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B314 Safari/531.21.10"


#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (assign) MMDrawerController * drawerController;
@property (copy) NSString *deviceUuid;
@property BOOL locked;

//@property (copy) NSString *tokensource;
@property (copy) NSString *tokentarget;
@property (copy) NSData *symkey;
//
//@property (copy) NSData *publickeysource;
//@property (copy) NSData *publickeytarget;
//
//@property (copy) NSData *symkeysource;
//@property (copy) NSData *symkeytarget;

-(void) closeDrawer;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

-(NSArray *) getMessages;
-(void) addMessage:(NSString *) message from:(NSString *)siod to:(NSString *)toid forDate:(NSDate *) date;

-(void) addFriend:(NSString *) name withToken:(NSString *) token withSymKey:(NSData *) symkey  withPubKey:(NSData *)pubkey withBadge:(int) badge;
-(NSArray *) getFriends;
-(Friends *) getFriend:(NSString *) friendToken;
-(Me *) getMe;


-(void) unsubscribe:(NSString *) sid;
-(void) subscribe:(NSString *) sid;
@end
