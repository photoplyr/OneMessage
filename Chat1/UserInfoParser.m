//
//  UserInfoParser.m
//  OneLogin
//
//  Created by Jacob Bullock on 5/7/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import "UserInfoParser.h"

@implementation UserInfoParser

@synthesize userData = _userData;

- (id)init
{
    self = [super init];
    
    self.userData = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)dealloc
{
    self.userData = nil;


}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	NSString *value = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
	if([elementName isEqualToString:@"info"])
    {

    }
	else
    {
        [self.userData setObject:value forKey:elementName];
	}
    
	//[currentElementValue release];
	self.currentElementValue = nil;
    
    //NSLog(@"didEndElement completed");
}

@end
