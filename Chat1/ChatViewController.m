//
//  MainViewController.m
//  Chat1
//
//  Created by Troy Simon on 3/17/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import "ChatViewController.h"
#import "JSMessage.h"
#import "AppDelegate.h"
#import "Messager.h"
#import "NuRSAKey.h"

#define  MAX_ENTRIES_LOADED 100
@interface ChatViewController ()
{
    AppDelegate *appdelegate;
    NuRSAKey *keygen;
    NSString *className;
    BOOL isShowingAlertView;
    BOOL isFirstShown;
}

@end

@implementation ChatViewController

- (void)viewDidLoad
{
    self.delegate = self;
    self.dataSource = self;
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    
    //self.title = APPNAME;
    self.messageInputView.textView.placeHolder = @"New Message";
    self.sender = @"guest";
    
    [self setBackgroundColor:[UIColor whiteColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessages:) name:NEWMESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(channelReady:) name:CHANNELREADY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideKeyboard:) name:HIDEKEYBOARD object:nil];
    [super viewDidLoad];
}


-(void) hideKeyboard:(NSNotification *)note
{
    [self.messageInputView.textView resignFirstResponder];
}

- (void)channelReady:(NSNotification *)note
{
    NSString *o = (NSString *)[note object];
    [self subscribe:o];
    NSLog(@"Channel Ready %@",o);
}

-(void) unsubscribe:(NSString *) sid
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation removeObject:sid forKey:@"channels"];
    [currentInstallation saveInBackground];
}


-(void) subscribe:(NSString *) sid
{
    // When users indicate they are Giants fans, we subscribe them to that channel.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation addUniqueObject:sid forKey:@"channels"];
    [currentInstallation saveInBackground];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.messageInputView.textView.keyboardAppearance = UIKeyboardAppearanceDark;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.sender = [defaults stringForKey:APPNAME];
    
    if (self.sender == nil)
    {
        [self presentChatNameDialog];
    }
    
    [self loadMessages:nil];
    [self scrollToBottomAnimated:NO];
}

#pragma mark - Actions
-(void) loadMessages:(NSNotification *)note
{
     NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        self.title = [[prefs objectForKey:@"name"] uppercaseString];
    
    self.messages = [[NSMutableArray alloc] init];
    
    [self loadLocalChat];
}

-(IBAction)open:(id)sender
{
    [appdelegate.drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)loadLocalChat
{
    className = APPNAME;
    
    if (appdelegate.tokentarget == nil)
        return;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sourceToken = %@ and targetToken = %@) OR (targetToken = %@ and sourceToken = %@)",appdelegate.tokensource,appdelegate.tokentarget,appdelegate.tokensource,appdelegate.tokentarget];
    
    PFQuery *query = [PFQuery queryWithClassName:className predicate:predicate];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
//    if ([self.messages count] == 0)
//    {
//        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
//        
//        [query orderByAscending:@"createdAt"];
//        
//        NSLog(@"Trying to retrieve from cache");
//        
//        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
//         {
//             if (!error)
//             {
//                 // The find succeeded.
//                 NSLog(@"Successfully retrieved %d chats from cache.", objects.count);
//                 [self.messages removeAllObjects];
//                 
//                 for(id message in objects)
//                 {
//                     [self.messages addObject:[[JSMessage alloc] initWithText:[self decryptMessage:[message objectForKey:@"cryptext"]] sender:[message objectForKey:@"userName"] date:[message objectForKey:@"date"]]];
//                 }
//                 
//                 [self.tableView reloadData];
//                 
//                 [self scrollToBottomAnimated:YES];
//             }
//             else
//             {
//                 // Log details of the failure
//                 NSLog(@"Error: %@ %@", error, [error userInfo]);
//             }
//         }];
//        
//        return;
//    }
    
    __block int totalNumberOfEntries = 0;
    [query orderByAscending:@"createdAt"];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error)
     {
         if (!error)
         {
             // The count request succeeded. Log the count
             NSLog(@"There are currently %d entries", number);
             
             if (totalNumberOfEntries != number)
             {
                 totalNumberOfEntries = number;
                 
                 NSLog(@"Retrieving data");
                 int theLimit;
                 
                 if (totalNumberOfEntries - [self.messages count] > MAX_ENTRIES_LOADED)
                 {
                     theLimit = MAX_ENTRIES_LOADED;
                 }
                 else
                 {
                     theLimit = totalNumberOfEntries - [self.messages count];
                 }
                 
                 query.limit = theLimit;
                 
                 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
                  {
                      if (!error)
                      {
                          // The find succeeded.
                          NSLog(@"Successfully retrieved %d chats.", objects.count);
                          
                          if ([objects count] != [self.messages count])
                          {
                              //[self.messages addObjectsFromArray:objects];
                              [self.messages removeAllObjects];
                              
                              for(id message in objects)
                              {
                                  [self.messages addObject:[[JSMessage alloc] initWithText:[self decryptMessage:[message objectForKey:@"cryptext"]] sender:[message objectForKey:@"userName"] date:[message objectForKey:@"date"]]];
                              }
                              
                              [self.tableView reloadData];
                              [self scrollToBottomAnimated:YES];
                          }
                      }
                      else
                      {
                          // Log details of the failure
                          NSLog(@"Error: %@ %@", error, [error userInfo]);
                      }
                  }];
             }
             
         } else {
             // The request failed, we'll keep the chatData count?
             number = [self.messages count];
         }
     }];
    
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - Messages view delegate: REQUIRED
- (NSString *)decryptMessage:(NSData *)blob {
    return [[NSString alloc] initWithData:blob encoding:NSUTF8StringEncoding];
}



-(NSData *) encryptMessage:(NSString *) blog
{
    return  [blog dataUsingEncoding: NSUTF8StringEncoding];
}

- (NSString *)_decryptMessage:(NSData *)blob {
	NSMutableDictionary * message = nil;
	NSString * error = nil;
    //	NSString * peerName = nil;
	BOOL verified = NO;
	CCOptions pad = 0;
	SecKeyRef publicKeyRef = NULL;
	NSData * plainText = nil;
    
 	// THIS USES THE PUBLIC KEY!!!!!
	message = [NSPropertyListSerialization propertyListFromData:blob mutabilityOption:NSPropertyListMutableContainers format:nil errorDescription:&error];
	
	if (!error) {
		
        // Add peer public key.
		publicKeyRef = [[SecKeyWrapper sharedWrapper] addPeerPublicKey:appdelegate.tokensource
															   keyBits:(NSData *)[message objectForKey:[NSString stringWithUTF8String:(const char *)kPubTag]]];
        
		// Get the unwrapped symmetric key.
		NSData * symmetricKey = [[SecKeyWrapper sharedWrapper] unwrapSymmetricKey:(NSData *)[message objectForKey:[NSString stringWithUTF8String:(const char *)kSymTag]]];
		
		// Get the padding PKCS#7 flag.
		pad = [(NSNumber *)[message objectForKey:[NSString stringWithUTF8String:(const char *)kPadTag]] unsignedIntValue];
		
		// Get the encrypted message and decrypt.
		plainText = [[SecKeyWrapper sharedWrapper]	doCipher:(NSData *)[message objectForKey:[NSString stringWithUTF8String:(const char *)kMesTag]]
                                                        key:symmetricKey
                                                    context:kCCDecrypt
                                                    padding:&pad];
		
		
		// Verify the signature.
		verified = [[SecKeyWrapper sharedWrapper] verifySignature:plainText
														secKeyRef:publicKeyRef
														signature:(NSData *)[message objectForKey:[NSString stringWithUTF8String:(const char *)kSigTag]]];
		if (!verified)
            return  nil;
        
  		// Clean up by removing the peer public key.
        [[SecKeyWrapper sharedWrapper] removePeerPublicKey:appdelegate.tokensource];
	} else {
		LOGGING_FACILITY( 0, error );
		return  nil;
	}
	
	return [[NSString alloc] initWithData:plainText encoding:NSASCIIStringEncoding];
}


-(NSData *) _encryptMessage:(NSString *) blog
{
    NSString * error = nil;
    SecKeyRef peerPublicKeyRef = NULL;
    CCOptions pad = 0;
    
    NSMutableDictionary * messageHolder = [[NSMutableDictionary alloc] init];
    
    // Acquire handle to public key.
	peerPublicKeyRef = [[SecKeyWrapper sharedWrapper] addPeerPublicKey:appdelegate.tokentarget keyBits:appdelegate.targetkey];

    NSData * symmetricKey = [[SecKeyWrapper sharedWrapper] getSymmetricKeyBytes];
    
    NSData *plainText = [blog dataUsingEncoding:NSUTF8StringEncoding];
    
    LOGGING_FACILITY( peerPublicKeyRef, @"Could not establish client handle to public key." );
	
    // Add the public key.
    [messageHolder	setObject:[[SecKeyWrapper sharedWrapper] getPublicKeyBits]
                      forKey:[NSString stringWithUTF8String:(const char *)kPubTag]];
    
    // Add the signature to the message holder.
    [messageHolder	setObject:[[SecKeyWrapper sharedWrapper] getSignatureBytes:plainText]
                      forKey:[NSString stringWithUTF8String:(const char *)kSigTag]];
    
    // Add the encrypted message.
    [messageHolder	setObject:[[SecKeyWrapper sharedWrapper] doCipher:plainText key:symmetricKey context:kCCEncrypt padding:&pad]
                      forKey:[NSString stringWithUTF8String:(const char *)kMesTag]];
    
    // Add the padding PKCS#7 flag.
    [messageHolder	setObject:[NSNumber numberWithUnsignedInt:pad]
                      forKey:[NSString stringWithUTF8String:(const char *)kPadTag]];
    
    // Add the wrapped symmetric key.
    [messageHolder	setObject:[[SecKeyWrapper sharedWrapper] wrapSymmetricKey:symmetricKey keyRef:peerPublicKeyRef]
                      forKey:[NSString stringWithUTF8String:(const char *)kSymTag]];
    
    NSData * message = [NSPropertyListSerialization dataFromPropertyList:messageHolder format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];

    return message;
}

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    NSData * message = nil;
  
    text = [text capitalizedString];
    
    [self.messages addObject:[[JSMessage alloc] initWithText:text sender:sender date:date]];
    
    NSMutableArray *insertIndexPaths = [[NSMutableArray alloc] init];
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [insertIndexPaths addObject:newPath];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
    [self.tableView reloadData];
    message = [self encryptMessage:text];
    
    // going for the parsing
    PFObject *newMessage = [PFObject objectWithClassName:APPNAME];
    [newMessage setObject:text forKey:@"text"];
    [newMessage setObject:message forKey:@"cryptext"];
    
    [newMessage setObject:sender forKey:@"userName"];
    
    [newMessage setObject:appdelegate.tokensource forKey:@"sourceToken"];
    [newMessage setObject:appdelegate.tokentarget forKey:@"targetToken"];
    
    [newMessage setObject:appdelegate.tokensource forKey:@"device"];
    [newMessage setObject:date forKey:@"date"];
    [newMessage saveInBackground];
    
    // Send a notification to all devices subscribed to the "Giants" channel.
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithFormat:
                           @"Message from %@",sender],@"alert" ,
                          @"Increment", @"badge",
                          sender, @"name",
                          nil];
  
//    appdelegate.tokensource, @"token",
//    appdelegate.publickey, @"key",
    
    // Create time interval
    NSTimeInterval interval = 60*60*24*7; // 1 week
    
    PFPush *push = [[PFPush alloc] init];
    [push expireAfterTimeInterval:interval];
    [push setChannels:[NSArray arrayWithObjects:appdelegate.tokentarget, nil]];
    [push setData:data];
    [push sendPushInBackground];

    text = @"";
    [self scrollToBottomAnimated:YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSMessage * message = [self.messages objectAtIndex:indexPath.row];
    
    if ([message.sender isEqualToString:self.sender])
        return  JSBubbleMessageTypeOutgoing;
    else
        return  JSBubbleMessageTypeIncoming;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSMessage *message = [self.messages objectAtIndex:indexPath.row];
    
    if ([self.sender isEqualToString:(NSString *)message.sender])
        return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleGreenColor]];
    else
        return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleBlueColor]];
}

- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}

#pragma mark - Messages view delegate: OPTIONAL

- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row % 3 == 0)
    {
        return YES;
    }
    return NO;
}

//
//  *** Implement to customize cell further
//
- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([cell messageType] == JSBubbleMessageTypeOutgoing)
    {
        cell.bubbleView.textView.textColor = [UIColor whiteColor];
        
        if ([cell.bubbleView.textView respondsToSelector:@selector(linkTextAttributes)])
        {
            NSMutableDictionary *attrs = [cell.bubbleView.textView.linkTextAttributes mutableCopy];
            [attrs setValue:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
            
            cell.bubbleView.textView.linkTextAttributes = attrs;
        }
    }
    
    if (cell.timestampLabel)
    {
        cell.timestampLabel.textColor = [UIColor lightGrayColor];
        cell.timestampLabel.shadowOffset = CGSizeZero;
    }
    
    if (cell.subtitleLabel)
    {
        cell.subtitleLabel.textColor = [UIColor lightGrayColor];
    }
    
#if TARGET_IPHONE_SIMULATOR
    cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeNone;
#else
    cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeNone;
#endif
}

//  *** Implement to use a custom send button
//
//  The button's frame is set automatically for you
//
//  - (UIButton *)sendButtonForInputView
//

//  *** Implement to prevent auto-scrolling when message is added
//
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling
{
    return YES;
}

// *** Implemnt to enable/disable pan/tap todismiss keyboard
//
- (BOOL)allowsPanToDismissKeyboard
{
    return YES;
}

#pragma mark - Messages view data source: REQUIRED

- (JSMessage *)messageForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.row];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender
{
    return [[UIImageView alloc] initWithImage:[JSAvatarImageFactory avatarImageNamed:@"profile" croppedToCircle:YES]];
}

-(void)presentChatNameDialog
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"OneMessage Name"
                                                      message:@"Choose a OneMessage name, it can be changed later in the Options panel"
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Continue", nil];
    
    [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [message show];
    isShowingAlertView = YES;
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0)
    {
        
        if (appdelegate.tokensource == nil)
        {
            NSLog(@"---------- ERROR NO SOURCE TOKEN --------------");
            return;
        }
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSLog(@"Plain text input: %@",textField.text);
        self.sender = [textField.text capitalizedString ];
        [[NSUserDefaults standardUserDefaults] setObject:self.sender forKey:APPNAME];
        [[NSUserDefaults standardUserDefaults] synchronize];
        isShowingAlertView = NO;
        
        //Save Data to Parse
        
        // going for the parsing
        PFObject *newMessage = [PFObject objectWithClassName:@"Users"];
        //[newMessage setObject:appdelegate.tokentarget forKey:@"tokentarget"];
        [newMessage setObject:appdelegate.tokensource forKey:@"tokensource"];
        //[newMessage setObject:appdelegate.targetkey forKey:@"targetkey"];
        //[newMessage setObject: appdelegate.symkey forKey:@"symkey"];
        [newMessage setObject:self.sender forKey:@"userName"];
        [newMessage saveInBackground];
        
    }
    else if (isFirstShown)
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Ooops"
                              message:@"Something's gone wrong. To post in this room you must have a OneMessage name. Go to the options panel to define one"
                              delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:@"Dismiss", nil];
        [alert show];
        isFirstShown = NO;
    }
}


@end
