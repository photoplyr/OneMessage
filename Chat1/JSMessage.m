//
//  Created by Jesse Squires
//  http://www.hexedbits.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSMessagesViewController
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//  http://opensource.org/licenses/MIT
//

#import "JSMessage.h"

@implementation JSMessage

#pragma mark - Initialization

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                        date:(NSDate *)date
{
    self = [super init];
    if (self) {
        _text = text ? text : @" ";
        _sender = sender;
        _date = date;
    }
    return self;
}


- (instancetype)initWithImage:(NSData *)image
                      sender:(NSString *)sender
                        date:(NSDate *)date
{
    self = [super init];
    if (self) {
        _image = image;
        _sender = sender;
        _date = date;
    }
    return self;
}


- (void)dealloc
{
    _text = nil;
    _sender = nil;
    _date = nil;
    _image = nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        
        if (_image != nil)
        _image   = [aDecoder decodeObjectForKey:@"image"];
        _text = [aDecoder decodeObjectForKey:@"text"];
        _sender = [aDecoder decodeObjectForKey:@"sender"];
        _date = [aDecoder decodeObjectForKey:@"date"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (self.image != nil)
         [aCoder encodeObject:self.image forKey:@"image"];
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.sender forKey:@"sender"];
    [aCoder encodeObject:self.date forKey:@"date"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    
    if (self.image != nil)
        return [[[self class] allocWithZone:zone] initWithImage:[self.image copy]
                                                        sender:[self.sender copy]
                                                          date:[self.date copy]];
        else
            
    return [[[self class] allocWithZone:zone] initWithText:[self.text copy]
                                                    sender:[self.sender copy]
                                                      date:[self.date copy]];
}

@end
