//
//  XMLParser.m
//  OneLogin
//
//  Created by Jacob Bullock on 4/20/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import "XMLParser.h"

@implementation XMLParser

@synthesize currentElementValue = _currentElementValue;


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string { 
	
	if(!self.currentElementValue) 
    {
        NSMutableString * currentElementValue = [[NSMutableString alloc] initWithString:string];
		self.currentElementValue = currentElementValue;
   
    }
	else
    {
		[self.currentElementValue appendString:string];
    }
    //	NSLog(@"********CURRVAL*********: %@", currentElementValue);
}

- (void)dealloc
{
    self.currentElementValue = nil;

}

@end
