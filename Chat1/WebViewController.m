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
    
    //https://new.onelogin.com/login/mobile/ok
    
    if([[data objectForKey:@"sessionKey"] isEqualToString:@""] || [data count] == 0)
    {
        url = @"https://new.onelogin.com/mobile_sessions/new";
        //url = @"https://app.onelogin.us/mobile_sessions/new?device=ipad";
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

-(BOOL)passcodeExistsInKeychain
{
	return [SFHFKeychainUtils getPasswordForUsername: kKeychainPasscode
									  andServiceName: kKeychainServiceName
											   error: nil].length != 0;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString * token = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('token').getAttribute('data-token');"];
    
    NSLog(@"result: '%@'", token);
    
    if ([token length] > 0)
    {
        appdelegate.tokensource = token;
        
        [UserProxy instance].sessionKey = token;
        [[PersistentDataProxy instance] saveLocalData];
        
        ChatViewController *v = [self.storyboard instantiateViewControllerWithIdentifier:@"chatwindow"];
        [self.navigationController pushViewController:v animated:NO];
    }
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
