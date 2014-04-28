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
#import "PhotoViewController.h"

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
    
    self.progress = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 320, 5)];
    [self.view addSubview:self.progress];
    
    [self.view bringSubviewToFront:self.progress];
    
    if (appdelegate.tokentarget == nil)
    {
        appdelegate.tokentarget = me.lastchattoken;
    }
    
    [self loadSymKey];
    [self loadMessages:nil];
    [self scrollToBottomAnimated:NO];
}


#pragma mark - Camera Actions
- (IBAction)camera:(id)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera] == YES){
        // Create image picker controller
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        // Set source to the camera
        imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
//        imagePicker.allowsEditing = YES;
//        imagePicker.showsCameraControls = YES;
//        // Delegate is self
        imagePicker.delegate = self;
        
        // Show image picker
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Access the uncropped image from info dictionary
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    // Dismiss controller
    [picker  dismissViewControllerAnimated:YES completion:nil];
    
    image = [self scaleAndRotateImage:image];
    
    // Upload image
    NSData *imageData = UIImagePNGRepresentation(image);
    [self uploadImage:imageData];
}


- (UIImage *)scaleAndRotateImage:(UIImage *)image {
    int kMaxResolution = 640; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

-(void) uploadImage:(NSData *) imageData
{
    Friends *friend = [appdelegate getFriend:appdelegate.tokentarget];
    
    
    if (![friend.approved boolValue])
    {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"Message "
                                                       description:@"Your are not approved to send a message to this friend"
                                                              type:TWMessageBarMessageTypeError];
        
        return;
    }
    
    PFFile *imageFile = [PFFile fileWithName:@"Image.png" data:imageData];
    
    //HUD creation here (see example for code)
    
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Hide old HUD, show completed HUD (see example for code)
            
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *newMessage = [PFObject objectWithClassName:APPNAME];
            [newMessage setObject:imageFile forKey:@"imageFile"];
            
            [newMessage setObject:me.name forKey:@"userName"];
            
            [newMessage setObject:me.token forKey:@"sourceToken"];
            [newMessage setObject:friend.token forKey:@"targetToken"];
            
            [newMessage setObject:me.token forKey:@"device"];
            [newMessage setObject:[NSDate date] forKey:@"date"];
            [newMessage setObject:[NSNumber numberWithBool:YES] forKey:@"imageAttached"];
            
            [newMessage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    self.progress.progress  = 0;
                    
                    NSLog(@"Uploaded photos!");
                    [self loadLocalChat:nil];
                }
                else{
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        }
        else{
            // [HUD hide:YES];
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    } progressBlock:^(int percentDone) {
        
        self.progress.progress = (float)percentDone/100;
        // Update your progress spinner here. percentDone will be between 0 and 100.
        //HUD.progress = (float)percentDone/100;
    }];
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
                                  
                                  if ([[message objectForKey:@"imageAttached"] intValue] == 1)
                                  {
                                      PFFile *thumbnail = [message objectForKey:@"imageFile"];
                                      NSData *data = thumbnail.getData;
                                      
                                      [self.messages addObject:[[JSMessage alloc] initWithImage:data sender:[message objectForKey:@"userName"] date:[message objectForKey:@"date"]]];
                                  }
                                  else
                                  {
                                      [self.messages addObject:[[JSMessage alloc] initWithText:[self decryptMessage:[message objectForKey:@"cryptext"]] sender:[message objectForKey:@"userName"] date:[message objectForKey:@"date"]]];
                                  }
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
        // LOGGING_FACILITY( 0, error );
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
    
    [newMessage setObject:[NSNumber numberWithBool:NO] forKey:@"imageAttached"];
    
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
    
    if (message.image == nil)
    {
        if ([me.name isEqualToString:(NSString *)message.sender])
            return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleGreenColor]];
        else
            return [JSBubbleImageViewFactory bubbleImageViewForType:type color:[UIColor js_bubbleBlueColor]];
    }
    else
    {
        return  nil;
    }
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    JSMessage *message = [self.messages objectAtIndex:indexPath.row];
    
    if ([ message image] != nil)
    {
        
        PhotoViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"photo"];
        [self.navigationController pushViewController:v animated:YES];
        v.imageData = [message image];
    }
    
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
