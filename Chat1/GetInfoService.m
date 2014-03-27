//
//  GetInfoService.m
//  OneLogin
//
//  Created by Jacob Bullock on 5/7/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import "GetInfoService.h"
#import "UserInfoParser.h"
#import "UserProxy.h"

@implementation GetInfoService

- (NSString *)action
{
    return @"sessions/get_info";
}

- (NSString *)completeNotification
{
    return GET_INFO_COMPLETE;
}

- (void)execute
{
    [super execute];
}

- (void)parseError
{
    /*
    NSMutableArray * temp = [NSMutableArray array];
    for(int i = 0; i < 10; i++)
    {
        [temp addObject:[Application dummy]];
    }
    
    [[ApplicationProxy instance] updateApplications:temp];
    */
    
    [self dispatchComplete];
}

- (void)parseData
{

    UserInfoParser * parser = [[UserInfoParser alloc] init];
    
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:self.responseData];
	[xmlParser setDelegate:parser];
	[xmlParser parse];
    
    
    NSLog(@"userData: %@", parser.userData);
    
    [UserProxy instance].userName = [parser.userData objectForKey:@"full_name"];
    [UserProxy instance].companyLogo = [parser.userData objectForKey:@"logo_url"];
    //[[ApplicationProxy instance] updateApplications:appParser.applications];

    [self dispatchComplete];

}

@end
