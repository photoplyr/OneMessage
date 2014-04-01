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
#import "TWMessageBarManager.h"

#import "WebViewController.h"
@interface ChatViewController ()
{
    AppDelegate *appdelegate;
    NuRSAKey *keygen;
    NSString *className;
    BOOL isShowingAlertView;
    BOOL isFirstShown;
    Me *me;
}

@end

@implementation ChatViewController

- (void)viewDidLoad
{
    self.delegate = self;
    self.dataSource = self;
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    self.messages = [[NSMutableArray alloc] init];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    
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
    [appdelegate subscribe:o];
    NSLog(@"Channel Ready %@",o);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    me = [appdelegate getMe];
    
    self.messageInputView.textView.keyboardAppearance = UIKeyboardAppearanceDark;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.sender = [defaults stringForKey:APPNAME];
    
    if (appdelegate.tokentarget == nil)
    {
        appdelegate.tokentarget = me.lastchattoken;
    }
    [self loadSymKey];
    [self loadMessages:nil];
    [self scrollToBottomAnimated:NO];
}

#pragma mark - Actions

-(void) loadMessages:(NSNotification *)note
{
    NSDictionary *data  = (NSDictionary*)[note object];
    
    NSArray *allKeys = [data allKeys];
    BOOL retVal = [allKeys containsObject:@"tokensource"];
    
    if ((self.title != nil) && (retVal == true))
        if (![appdelegate.tokentarget isEqualToString:[data objectForKey:@"tokensource"]])
            return;
    
    [self loadLocalChat: [data objectForKey:@"obj"]];
}

-(IBAction)open:(id)sender
{
    [appdelegate.drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

-(void) loadSymKey
{
    if (appdelegate.tokentarget == nil)
        return;
    
    Friends *friend = [appdelegate getFriend:appdelegate.tokentarget];
    self.title = [friend.name uppercaseString];
    
    if (me.token == nil)
        return;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sourceToken = %@ and targetToken = %@) OR (targetToken = %@ and sourceToken = %@)",me.token,friend.token,me.token,friend.token];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Conversations" predicate:predicate];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error)
         {
             
             if ([objects count]  == 0)
             {
                 // Set the sym key
                 appdelegate.symkey = me.symkey;
                 
                 // Time to make a conversation
                 PFObject *newMessage = [PFObject objectWithClassName:@"Conversations"];
                 [newMessage setObject:me.token forKey:@"sourceToken"];
                 [newMessage setObject:friend.token forKey:@"targetToken"];
                 [newMessage setObject:me.symkey forKey:@"symkey"];
                 [newMessage saveInBackground];
             }
             else
             {
                 for(id convers in objects)
                 {
                     appdelegate.symkey = [convers objectForKey:@"symkey"];
                     break;
                 }
                 
             }
         }
         else
         {
             appdelegate.symkey = nil;
             // Log details of the failure
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];
}

- (void)loadLocalChat:(NSString *)oid
{
    if (appdelegate.tokentarget == nil)
        return;
    
    Friends *friend = [appdelegate getFriend:appdelegate.tokentarget];
    
    self.title = [friend.name uppercaseString];
    
    className = APPNAME;
    
    if (me.token == nil)
        return;
    
    NSPredicate *predicate;
    
    if (oid == nil)
        predicate = [NSPredicate predicateWithFormat:@"(sourceToken = %@ and targetToken = %@) OR (targetToken = %@ and sourceToken = %@)",me.token,friend.token,me.token,friend.token];
    else
        predicate = [NSPredicate predicateWithFormat:@"objectId = %@",oid];
    
    PFQuery *query = [PFQuery queryWithClassName:className predicate:predicate];
    
    if (oid != nil)
    {
        PFQuery *query = [PFQuery queryWithClassName:APPNAME];
        [query getObjectInBackgroundWithId:oid block:^(PFObject *message, NSError *error) {
            
            // Do something with the returned PFObject in the gameScore variable.
            [self.messages addObject:[[JSMessage alloc] initWithText:[self decryptMessage:[message objectForKey:@"cryptext"]] sender:[message objectForKey:@"userName"] date:[message objectForKey:@"date"]]];
            
            // Now insert a new row
            NSMutableArray *insertIndexPaths = [[NSMutableArray alloc] init];
            NSIndexPath *newPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [insertIndexPaths addObject:newPath];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
            [self.tableView endUpdates];
            [self.tableView reloadData];
            [self scrollToBottomAnimated:YES];
        }];
    }
    else
    {
        [query orderByAscending:@"createdAt"];
        [query countObjectsInBackgroundWithBlock:^(int number, NSError *error)
         {
             if (!error)
             {
                 // The count request succeeded. Log the count
                 NSLog(@"There are currently %d entries", number);
                 
                     NSLog(@"Retrieving data");
                     int theLimit;
                     
                     theLimit = MAX_ENTRIES_LOADED - (int)[self.messages count];
                     
                     if (theLimit >MAX_ENTRIES_LOADED)
                     theLimit = MAX_ENTRIES_LOADED;
                     
                     query.limit = theLimit;
                     
                     [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
                      {
                          if (!error)
                          {
                              // The find succeeded.
                              NSLog(@"Successfully retrieved %lu chats.", (unsigned long)objects.count);
                              
                              if ([objects count] != [self.messages count])
                              {
                                  [self.messages removeAllObjects];
                                  
                                  for(id message in objects)
                                  {
                                      [self.messages addObject:[[JSMessage alloc] initWithText:[self decryptMessage:[message objectForKey:@"cryptext"]] sender:[message objectForKey:@"userName"] date:[message objectForKey:@"date"]]];
                                  }
                              }
                              
                              [self.tableView reloadData];
                              [self scrollToBottomAnimated:YES];
                          }
                          else
                          {
                              // Log details of the failure
                              NSLog(@"Error: %@ %@", error, [error userInfo]);
                          }
                      }];
                 }
             
         }];
        
    }
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

#pragma mark - Messages view delegate: REQUIRED
- (NSString *)decryptMessage:(NSData *)blob {
    NSString *data = [self _decryptMessage:blob];
    
    return  data;
}

-(NSData *) encryptMessage:(NSString *) blog
{
    NSData *data = [self _encryptMessage:blog];
    return  data;
}

- (NSString *)_decryptMessage:(NSData *)blob {
    NSMutableDictionary * message = nil;
    NSString * error = nil;
    
    BOOL verified = NO;
    CCOptions pad = 0;
    SecKeyRef publicKeyRef = NULL;
    NSData * plainText = nil;
    
    message = [NSPropertyListSerialization propertyListFromData:blob mutabilityOption:NSPropertyListMutableContainers format:nil errorDescription:&error];
    
    if (!error) {
        
        // Add peer public key.
        publicKeyRef = [[SecKeyWrapper sharedWrapper] addPeerPublicKey:me.token
                                                               keyBits:(NSData *)[message objectForKey:[NSString stringWithUTF8String:(const char *)kPubTag]]];
        
        // Get the unwrapped symmetric key.
        NSData * symmetricKey = appdelegate.symkey;
        
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
        
        [[SecKeyWrapper sharedWrapper] removePeerPublicKey:me.token];
        
        if (!verified)
            return  nil;
        
        // Clean up by removing the peer public key.
        
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
    
    Friends *friend = [appdelegate getFriend:appdelegate.tokentarget];
    
    // Acquire handle to public key.
    peerPublicKeyRef = [[SecKeyWrapper sharedWrapper] addPeerPublicKey:friend.token keyBits:friend.publickey];
    
    //NSData * symmetricKey = [[SecKeyWrapper sharedWrapper] getSymmetricKeyBytes];
    NSData * symmetricKey = appdelegate.symkey;
    
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
    
    [[SecKeyWrapper sharedWrapper] removePeerPublicKey:friend.token];
    return message;
}

PFObject *newMessage;
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date
{
    Friends *friend = [appdelegate getFriend:appdelegate.tokentarget];
    
    
    if (![friend.approved boolValue])
    {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Message "
                                                       description:@"Your are not approved to send a message to this friend"
                                                              type:TWMessageBarMessageTypeError];
        
        return;
    }
    
    NSData * message = nil;
    
    text = [text capitalizedString];
    
    if ([text length] < 1)
        return;
    
    [self.messages addObject:[[JSMessage alloc] initWithText:text sender:me.name date:date]];
    
    NSMutableArray *insertIndexPaths = [[NSMutableArray alloc] init];
    NSIndexPath *newPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [insertIndexPaths addObject:newPath];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
    [self.tableView reloadData];
    message = [self encryptMessage:text];
    
    // going for the parsing
    newMessage = [PFObject objectWithClassName:APPNAME];
    [newMessage setObject:text forKey:@"text"];
    [newMessage setObject:message forKey:@"cryptext"];
    
    [newMessage setObject:me.name forKey:@"userName"];
    
    [newMessage setObject:me.token forKey:@"sourceToken"];
    [newMessage setObject:friend.token forKey:@"targetToken"];
    
    [newMessage setObject:me.token forKey:@"device"];
    [newMessage setObject:date forKey:@"date"];
    [newMessage saveInBackgroundWithTarget: self selector:@selector(nowPush: error:)];
    
    text = @"";
    //[self finishSend];
}


-(void) nowPush:(NSNumber *)result error:(NSError *)error
{
    
    if ([result boolValue])
    {
        
        [newMessage refresh];
        NSString *objectId = newMessage.objectId;
        
        // Send a notification to all devices subscribed to the "Giants" channel.
        NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSString stringWithFormat:
                               @"Message from %@",me.name],@"alert" ,
                              @"Increment", @"badge",
                              me.name, @"name",
                              objectId, @"obj",
                              me.token,@"tokensource",
                              nil];
        
        
        [appdelegate sendPush:appdelegate.tokentarget withData:data];
    }
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSMessage * message = [self.messages objectAtIndex:indexPath.row];
    
    if ([message.sender isEqualToString:me.name])
        return  JSBubbleMessageTypeOutgoing;
    else
        return  JSBubbleMessageTypeIncoming;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    JSMessage *message = [self.messages objectAtIndex:indexPath.row];
    
    if ([me.name isEqualToString:(NSString *)message.sender])
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
    {
        cell.bubbleView.textView.textColor = [UIColor whiteColor];
        
        if ([cell.bubbleView.textView respondsToSelector:@selector(linkTextAttributes)])
        {
            NSMutableDictionary *attrs = [cell.bubbleView.textView.linkTextAttributes mutableCopy];
            [attrs setValue:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
            
            cell.bubbleView.textView.linkTextAttributes = @{
                                                            NSForegroundColorAttributeName : [UIColor whiteColor],
                                                            NSUnderlineStyleAttributeName: [NSNumber numberWithInt: NSUnderlineStyleSingle]};
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
    cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeAll;
#endif
}

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
@end
