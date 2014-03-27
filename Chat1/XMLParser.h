//
//  XMLParser.h
//  OneLogin
//
//  Created by Jacob Bullock on 4/20/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic, retain) NSMutableString * currentElementValue;

@end
