//
//  Util.m
//  OneLogin
//
//  Created by Jacob Bullock on 4/19/12.
//  Copyright (c) 2012 Kineticz Intractive LLC. All rights reserved.
//

#import "Util.h"

@implementation Util

//file path in docs folder
+ (NSString *)filePathForFileName:(NSString*) fileName
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (BOOL)checkForDocumentsFile:(NSString *)fileName
{
	NSFileManager *fm = [NSFileManager defaultManager];
	return [fm fileExistsAtPath:[self filePathForFileName:fileName]];
}


//file path in main bundle
+ (NSString *)localPathForFileName:(NSString*) fileName
{
	NSString *localPath = [[NSBundle mainBundle] bundlePath];
	return [localPath stringByAppendingPathComponent:fileName];
}



@end
