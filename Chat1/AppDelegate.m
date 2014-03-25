//
//  AppDelegate.m
//  Chat1
//
//  Created by Troy Simon on 3/17/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import "AppDelegate.h"

#import "NavigationViewController.h"
#import "TWMessageBarManager.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"7d2nKN8Cqw4hhr5EDGhELPlWGFZt0947TUeFXTVU"
                  clientKey:@"F0emzjq4GiXfANuuhAdsnmE7JaUmuFlRYg7aYTCp"];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
 
    self.tokentarget = [prefs objectForKey:@"tokentarget"];
    self.tokensource = [prefs objectForKey:@"tokensource"];
    self.targetkey = [prefs objectForKey:@"targetkey"];
    self.symkey = [prefs objectForKey:@"symkey"];
    self.tokentarget = [prefs objectForKey:@"tokentarget"];
    
    // Register for remote notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    // Extract the notification data
    //  NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    // Override point for customization after application launch.
    self.drawerController = (MMDrawerController *)self.window.rootViewController;
    self.drawerController.locked = FALSE;
    [self.drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    [self.drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    [self.drawerController setShowsShadow:YES];
    
    [self.drawerController setDrawerVisualStateBlock:^(MMDrawerController *drawerController, MMDrawerSide drawerSide, CGFloat percentVisible) {
        MMDrawerControllerDrawerVisualStateBlock block;
        block = [[MMExampleDrawerVisualStateManager sharedManager]
                 drawerVisualStateBlockForDrawerSide:drawerSide];
        
         [[NSNotificationCenter defaultCenter] postNotificationName:HIDEKEYBOARD object:nil];
        if(block){
            block(drawerController, drawerSide, percentVisible);
        }
    }];
    
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    NSString *did =[[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                     stringByReplacingOccurrencesOfString:@">" withString:@""]
                    stringByReplacingOccurrencesOfString: @" " withString: @""];
    self.tokensource = [NSString stringWithFormat:@"ID_%@",did];
    
//     SecKeyRef sec = [[SecKeyWrapper sharedWrapper] getPublicKeyRef];
     NSData *key = [[SecKeyWrapper sharedWrapper] getPublicKeyBits];
    
    if (key != nil)
        self.publickey = key;
    
    // Check to see if keys have been generated.
    if (	![[SecKeyWrapper sharedWrapper] getPublicKeyRef]		||
        ![[SecKeyWrapper sharedWrapper] getPrivateKeyRef]		||
        ![[SecKeyWrapper sharedWrapper] getSymmetricKeyBytes]) {
		
        [[SecKeyWrapper sharedWrapper] generateKeyPair:kAsymmetricSecKeyPairModulusSize];
		[[SecKeyWrapper sharedWrapper] generateSymmetricKey];
        
//        sec = [[SecKeyWrapper sharedWrapper] getPublicKeyRef];
        key = [[SecKeyWrapper sharedWrapper] getPublicKeyBits];
        
        self.publickey = key;
        
        NSLog(@"Build Key pair");
    }

    
    [[NSNotificationCenter defaultCenter] postNotificationName:CHANNELREADY object:[NSString stringWithFormat:@"ID_%@",did]];
    
    NSLog(@"Push Registered : %@",did);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    // Create empty photo object
    
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    
    //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NEWMESSAGE object:userInfo];
    
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"New Message"
                                                   description:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
                                                          type:TWMessageBarMessageTypeInfo];
    
    [self addFriend:[userInfo objectForKey:@"name"] withToken:[userInfo objectForKey:@"token"] withKey:[userInfo objectForKey:@"key"] withBadge:1];
    
    NSLog(@"didReceiveRemoteNotification");
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NEWMESSAGE object:nil];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

-(void) closeDrawer
{
    [self.drawerController closeDrawerAnimated:YES completion:nil];
}

-(NSArray *) getFriends
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Friends" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray *myProfile = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    return myProfile;
}

-(void) addFriend:(NSString *) name withToken:(NSString *) token withKey:(NSData *) key withBadge:(int) badge
{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"token" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"token = %@",token];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Friends" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray *myProfile = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    
    if ([myProfile count] == 0){
        
        Friends *friend = [NSEntityDescription
                           insertNewObjectForEntityForName:@"Friends"
                           inManagedObjectContext:self.managedObjectContext];
        
        friend.name = name;
        friend.token = token;
        friend.key = key;
        friend.badge = [NSNumber numberWithInt:0];
    }
    else
    {
        Friends *friend = [myProfile lastObject];
        int badgeCount =  [friend.badge intValue];
        badgeCount = badgeCount + badge;
        
        if (badge == -1)
             friend.badge = [NSNumber numberWithInt:0];
            else
        friend.badge = [NSNumber numberWithInt:badgeCount];
        
        [self saveContext];
    }
}

-(void) addMessage:(NSString *) message from:(NSString *)siod to:(NSString *)toid forDate:(NSDate *) date
{
    
    Messager *data = [NSEntityDescription
                      insertNewObjectForEntityForName:@"Messager"
                      inManagedObjectContext:self.managedObjectContext];
    
    data.message = message;
    data.soid = siod;
    data.toid = toid;
    data.date = date;
    data.dirty = [NSNumber numberWithBool:YES];
    data.read = [NSNumber numberWithBool:NO];
    data.uploaded = [NSNumber numberWithBool:NO];
    [self saveContext];
}

-(NSArray *) getMessages
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // fetchRequest.predicate = [NSPredicate predicateWithFormat:@"sid = %@",sid];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Messager" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray *myProfile = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    return  myProfile;
    
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Chat1" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Chat1.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
       // NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
        
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        
        //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
    }
    
    return _persistentStoreCoordinator;
}



#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
