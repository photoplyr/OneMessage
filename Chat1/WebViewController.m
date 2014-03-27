//
//  WebViewController.m
//  OneLogin
//
//  Created by Troy Simon on 2/3/14.
//  Copyright (c) 2014 Troy Simon. All rights reserved.
//

#import "WebViewController.h"
#import "AppDelegate.h"
#import "ChatViewController.h"
#import "GetInfoService.h"
#import "Me.h"

@interface WebViewController ()
{
    AppDelegate *appdelegate;
}

@end

@implementation WebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    appdelegate = [[UIApplication sharedApplication] delegate];
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [[PersistentDataProxy instance] loadLocalData];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation: UIStatusBarAnimationSlide];
    
    [self showLogo];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation: UIStatusBarAnimationSlide];
}

-(void) viewWillAppear:(BOOL)animated
{
    [self showLogo];
    NSString * url;
    
    [[PersistentDataProxy instance] loadLocalData];
    NSDictionary * data = [PersistentDataProxy instance].localData;
    
    Me *me = [appdelegate getMe];
    
    //if([[data objectForKey:@"sessionKey"] isEqualToString:@""] || [data count] == 0)
    if (me.name == nil)
    {
        url = @"https://new.onelogin.com/mobile_sessions/new";
        NSURLRequest * loginRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [self.web loadRequest:loginRequest];
    }
    else
    {
        ChatViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"chatwindow"];
        [self.navigationController pushViewController:v animated:NO];
        
        NSLog(@"Load chat screen");
    }
    
}

-(void) showLogo
{
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation: UIStatusBarAnimationSlide];
    
    UIImage *image = [UIImage imageNamed: @"logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage: image];
    
    self.navigationItem.titleView = imageView;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString * token = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('token').getAttribute('data-token');"];
    
    NSLog(@"result: '%@'", token);
    
    if ([token length] > 0)
    {
        
        [UserProxy instance].sessionKey = token;
        [[PersistentDataProxy instance] saveLocalData];
        
        GetInfoService * infoService = [[GetInfoService alloc] initWithParams:nil];
        infoService.delegate = self;
        [infoService execute];
    }
}


-(void) webServiceDidFailWithError:(NSString *)error
{
    NSLog(@"!!!!!!!! ERROR TRYING TO GET USERS NAME !!!!!!!!");
}

- (void)webServiceDidFinishWithSuccess:(NSString *)data
{
    
    Me *me = [appdelegate getMe];
    me.name = [UserProxy instance].userName ;
    [appdelegate saveContext];
    
    [[NSUserDefaults standardUserDefaults] setObject:me.name forKey:APPNAME];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // going for the parsing
    PFObject *newMessage = [PFObject objectWithClassName:@"Users"];
    [newMessage setObject:me.token forKey:@"tokensource"];
    [newMessage setObject: me.publickey forKey:@"publickeysource"];
    [newMessage setObject: me.symkey forKey:@"symkeysource"];
    [newMessage setObject:me.name forKey:@"userName"];
    [newMessage saveInBackground];

    ChatViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"chatwindow"];
    [self.navigationController pushViewController:v animated:NO];
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL)shouldAutorotate
{
    NSLog(@"shouldAutoRotate...");
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
