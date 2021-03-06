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
        if(block)
        {
            block(drawerController, drawerSide, percentVisible);
        }
    }];
    
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    Me *me = [self getMe];
    
    // Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    NSString *did =[[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                     stringByReplacingOccurrencesOfString:@">" withString:@""]
                    stringByReplacingOccurrencesOfString: @" " withString: @""];

    me.token = [NSString stringWithFormat:@"ID_%@",did];
    
    //  The local storage was wiped
    if (me.publickey == nil)
    {
        [[SecKeyWrapper sharedWrapper] deleteSymmetricKey];
        [[SecKeyWrapper sharedWrapper] deleteAsymmetricKeys];
    }
    
    // Genereate the Symmetric Key used to wrapp the package
    if (	![[SecKeyWrapper sharedWrapper] getPublicKeyRef]		||
        ![[SecKeyWrapper sharedWrapper] getPrivateKeyRef]		||
        ![[SecKeyWrapper sharedWrapper] getSymmetricKeyBytes])
    {
        NSData *symkey;
        NSData *publickey;
        
        [[SecKeyWrapper sharedWrapper] generateKeyPair:kAsymmetricSecKeyPairModulusSize];
		[[SecKeyWrapper sharedWrapper] generateSymmetricKey];
        
        symkey = [[SecKeyWrapper sharedWrapper] getSymmetricKeyBytes];
        publickey = [[SecKeyWrapper sharedWrapper] getPublicKeyBits];
        
        me.symkey = symkey;
        me.publickey = publickey;
        
        [self saveContext];
        NSLog(@"Build Key pair");
    }
    
    
    [self saveContext];
    
    [self loadServerData:me.token];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CHANNELREADY object:[NSString stringWithFormat:@"ID_%@",did]];
    
    NSLog(@"Push Registered : %@",did);
}

-(void) loadServerData:(NSString *) stoken
{
    // Try and load data from cloud
     Me *me = [self getMe];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tokensource = %@",stoken];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Users" predicate:predicate];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error)
         {
             for(id convers in objects)
             {
                 me.publickey = [convers objectForKey:@"publickeysource"];
                 me.symkey = [convers objectForKey:@"symkeysource"];
                 me.name = [convers objectForKey:@"userName"];
                 [self saveContext];
                 break;
             }
         }
     }];
    
    
    //

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    // Create empty photo object
    
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NEWMESSAGE object:userInfo];
    
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"New Message"
                                                   description:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
                                                          type:TWMessageBarMessageTypeInfo];
    
    [self addFriend:[userInfo objectForKey:@"name"] withToken:[userInfo objectForKey:@"tokensource"] withSymKey:nil withPubKey:nil withBadge:1];
    
  //  [self addFriend:[userInfo objectForKey:@"name"] withToken:[userInfo objectForKey:@"tokensource"] withSymKey:[userInfo objectForKey:@"key"] withBadge:1];
    
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

-(Friends *) getFriend:(NSString *) friendToken
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"token" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"token = %@",friendToken];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Friends" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray *myProfile = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    Friends *friend = [myProfile lastObject];
    return friend;
}

-(void) addFriend:(NSString *) name withToken:(NSString *) token withSymKey:(NSData *) symkey  withPubKey:(NSData *)pubkey withBadge:(int) badge
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
        friend.symkey = symkey;
        friend.publickey = pubkey;
        friend.badge = [NSNumber numberWithInt:0];
    }
    else
    {
        Friends *friend = [myProfile lastObject];
        int badgeCount =  [friend.badge intValue];
        friend.name = name;
        badgeCount = badgeCount + badge;
        
        if (badge == -1)
            friend.badge = [NSNumber numberWithInt:0];
        else
            friend.badge = [NSNumber numberWithInt:badgeCount];
        
        if (symkey != nil)
            friend.symkey = symkey;
        
        if (pubkey != nil)
            friend.publickey = pubkey;
        
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

-(Me *) getMe
{
    Me *me;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Me" inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray *myProfile = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if ([myProfile count] == 0)
    {
        me = [NSEntityDescription
                    insertNewObjectForEntityForName:@"Me"
                    inManagedObjectContext:self.managedObjectContext];
        
        [self saveContext];
    }
    else
    {
        me = [myProfile lastObject];
    }
    
    return me;
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
