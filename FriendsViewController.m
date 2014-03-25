//
//  FriendsViewController.m
//  OneMessage
//
//  Created by Troy Simon on 3/19/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import "FriendsViewController.h"
#import "JSAvatarImageFactory.h"

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

-(void) loadFriends
{
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
                 if (![[friend objectForKey:@"tokensource"] isEqualToString:appdelegate.tokensource])
                 {
                     [appdelegate addFriend:[friend objectForKey:@"userName"] withToken:[friend objectForKey:@"tokensource"] withKey:[friend objectForKey:@"key"]  withBadge:0];
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
    static NSString *CellIdentifier = @"WebTabCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Friends *friend = [self.friends objectAtIndex:indexPath.row];
    cell.textLabel.text = friend.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Messages %@", [friend.badge stringValue]];
    cell.imageView.image = [JSAvatarImageFactory classicAvatarImageNamed:@"profile" croppedToCircle:YES];
    return cell;
}

// All done. Time to remove the public key from the keychain.
//[[SecKeyWrapper sharedWrapper] removePeerPublicKey:peer];

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Friends *friend = [self.friends objectAtIndex:indexPath.row];
    appdelegate.tokentarget = friend.token;
    appdelegate.targetkey = friend.key;
    
   [appdelegate closeDrawer];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setObject:appdelegate.tokentarget forKey:@"tokentarget"];
    [prefs setObject:appdelegate.tokensource forKey:@"tokensource"];
    [prefs setObject:appdelegate.targetkey forKey:@"targetkey"];
    [prefs setObject: appdelegate.symkey forKey:@"symkey"];
    [prefs setObject:friend.name forKey:@"name"];
    [prefs synchronize];
    
    [appdelegate addFriend:friend.name withToken:appdelegate.tokentarget withKey:friend.key withBadge:-1];
    
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
