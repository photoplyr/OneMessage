//
//  Util.h
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject

+ (NSString *)filePathForFileName:(NSString*) fileName;
+ (BOOL)checkForDocumentsFile:(NSString *)fileName;
+ (NSString *)localPathForFileName:(NSString*) fileName;

@end
