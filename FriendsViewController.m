//
//  FriendsViewController.m
//  OneMessage
//
//  Created by Troy Simon on 3/19/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import "FriendsViewController.h"
#import "JSAvatarImageFactory.h"
#import "InviteViewController.h"

@interface FriendsViewController ()
{
    AppDelegate *appdelegate;
}

@end

@implementation FriendsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessages) name:NEWMESSAGE object:nil];
    
    appdelegate = [[UIApplication sharedApplication] delegate];
}

-(void) loadMessages
{
    self.friends = [appdelegate getFriends];
    
    [self.tableView reloadData];
}

-(void) viewWillAppear:(BOOL)animated
{
    [self loadFriends];
}

-(IBAction)invite:(id)sender
{
    
}
-(void) loadFriends
{
    Me *me = [appdelegate getMe];
    
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Users"];
    
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [query orderByAscending:@"createdAt"];
    
    NSLog(@"Trying to retrieve from cache");
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error)
         {
             // The find succeeded.
             NSLog(@"Successfully retrieved %d friends from cache.", objects.count);
             [friends removeAllObjects];
             
             for(id friend in objects)
             {
                 if (![[friend objectForKey:@"tokensource"] isEqualToString:me.token])
                 {
                     [appdelegate addFriend:[friend objectForKey:@"userName"] withToken:[friend objectForKey:@"tokensource"] withSymKey:[friend objectForKey:@"symkeysource"] withPubKey:[friend objectForKey:@"publickeysource"] withBadge:0];
                 }
             }
             
             self.friends = [appdelegate getFriends];
             
             [self.tableView reloadData];
         }
         else
         {
             // Log details of the failure
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    // This will create a "invisible" footer
    return 0.01f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FriendCell";
    FriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Me *me = [appdelegate getMe];
    Friends *friend = [self.friends objectAtIndex:indexPath.row];
    
    // Check the status
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sourceToken = %@ and targetToken = %@) OR (targetToken = %@ and sourceToken = %@)",me.token,friend.token,me.token,friend.token];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation" predicate:predicate];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error)
         {
             PFObject *data =  [query getFirstObject];
             if (data != nil)
             {
                 // If both parties have accepted they are ready to chat
                 if (([[data objectForKey:@"targetAck"] intValue] + [[data objectForKey:@"sourceAck"] intValue] ) == 2)
                 {
                     cell.request.text = @"";
                     friend.approved = [NSNumber numberWithBool:YES];
                     [appdelegate saveContext];
                 }
                 else
                 {   // If I send message show waiting message
                     cell.request.text = @"Waiting";
                     friend.approved = [NSNumber numberWithBool:NO];
                     [appdelegate saveContext];
                     
                     // If I am recipient of request I need to accept the request
                     if ([[data objectForKey:@"targetToken"] isEqualToString:me.token] )
                     {
                         if ([[data objectForKey:@"targetAck"] intValue] == 0)
                         {
                             cell.request.text = @"Accept";
                             friend.approved = [NSNumber numberWithBool:NO];
                             [appdelegate saveContext];
                         }
                     }
                 }
             }
             else
             {
                 // Nothis is done so Invite
                 cell.request.text = @"Invite";
                 friend.approved = [NSNumber numberWithBool:NO];
                 [appdelegate saveContext];
             }
             
         }
         else
         {
             // Log details of the failure
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];
    
    // Handle message for people chatting
    cell.textLabel.text = friend.name;
    
    if ([friend.badge intValue] > 0)
        cell.detailTextLabel.text = @"New Message";
    else
        cell.detailTextLabel.text = @"";
    
    return cell;
}

// All done. Time to remove the public key from the keychain.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Friends *friend = [self.friends objectAtIndex:indexPath.row];
    Me *me = [appdelegate getMe];
    BOOL __block ok = FALSE;
    
    if ([friend.approved boolValue])
    {
      [self loadMessageCenter:me andFriend:friend];
    }
    
    else
    {
        // 1. Make sure there is a mutual invitation
        //    PFObject *data = [appdelegate isApprovedToChat:me withFriends:friend];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(sourceToken = %@ and targetToken = %@) OR (targetToken = %@ and sourceToken = %@)",me.token,friend.token,me.token,friend.token];
        
        PFQuery *query = [PFQuery queryWithClassName:@"Invitation" predicate:predicate];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (!error)
             {
                 PFObject *data =  [query getFirstObject];
                 if (data != nil)
                 {
                     // If sending, then set my ACK value
                     if ([[data objectForKey:@"sourceToken"] isEqualToString:me.token] )
                     {
                         if ([[data objectForKey:@"sourceAck"] intValue] == 0)
                         {
                             [data setObject:[NSNumber numberWithInt:1] forKey:@"sourceAck"];
                         }
                         else
                         {
                             [tableView reloadData];
                             
                         }
                     }
                     else
                     {
                         // If I receiving request then set my ACK value and push a notification
                         if ([[data objectForKey:@"targetAck"] intValue] == 0)
                         {
                             [data setObject:[NSNumber numberWithInt:1] forKey:@"targetAck"];
                             
                             // Send a notification
                             NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [NSString stringWithFormat:
                                                    @"%@ has accepted your request",friend.name],@"alert" ,
                                                   friend.name, @"name",
                                                   @"1",@"ack",
                                                   nil];
                             
                             [appdelegate sendPush:friend.token withData:data];
                         }
                     }
                     
                     // No update the server
                     if ([data isDirty])
                         [data saveInBackground];
                     
                     if (([[data objectForKey:@"targetAck"] intValue] + [[data objectForKey:@"sourceAck"] intValue] ) == 2)
                     {
                         friend.approved = [NSNumber numberWithBool:YES];
                         [appdelegate saveContext];
                         ok = TRUE;
                     }
                     else
                     {
                         friend.approved = [NSNumber numberWithBool:NO];
                         ok = FALSE;
                     }
                 }
             }
             else
             {
                 ok = FALSE;
                 // Log details of the failure
                 NSLog(@"Error: %@ %@", error, [error userInfo]);
             }
             
             if (ok)
             {
                 [self loadMessageCenter:me andFriend:friend];
              }
             else
             {
                 // Send the request to your friend
                 [appdelegate makeChatRequest:me withFriends:friend];
                 
                 [tableView reloadData];
             }
             
         }];
    }
}

-(void) loadMessageCenter:(Me *) me andFriend:(Friends *) friend
{
             me.lastchattoken = friend.token;

             appdelegate.tokentarget = friend.token;

             [appdelegate closeDrawer];

             friend.badge = [NSNumber numberWithInt:-1];
             [appdelegate saveContext];

             [[NSNotificationCenter defaultCenter] postNotificationName:NEWMESSAGE object:friend.name];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.friends count];
}



@end
