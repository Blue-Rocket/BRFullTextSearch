//
//  BRTestSupport.m
//  BRFullTextSearch
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRTestSupport.h"

@implementation BRTestSupport {
	NSBundle *bundle;
}

@synthesize bundle;

+ (NSString *)UUID {
	CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return uuidString;
}

+ (NSString *)temporaryPathWithPrefix:(NSString *)prefix suffix:(NSString *)suffix directory:(BOOL)directory {
	NSString *nameTemplate = (directory ? [prefix stringByAppendingString:@".XXXXXX"] : [NSString stringWithFormat:@"%@.XXXXXX%@", prefix, suffix]);
	NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:nameTemplate];
	const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
	char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
	strcpy(tempFileNameCString, tempFileTemplateCString);
	if ( directory ) {
		char *result = mkdtemp(tempFileNameCString);
		if ( !result ) {
			free(tempFileNameCString);
			log4Error(@"Failed to create temp directory %s", tempFileNameCString);
			return nil;
		}
	} else {
		int fileDescriptor = mkstemps(tempFileNameCString, (int)[suffix length]);
		if ( fileDescriptor == -1 ) {
			free(tempFileNameCString);
			log4Error(@"Failed to create temp file %s", tempFileNameCString);
			return nil;
		}
	}
	
	NSString * result = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString
																					length:strlen(tempFileNameCString)];
	free(tempFileNameCString);
	return result;
}

- (void)setUp {
	bundle = [NSBundle bundleForClass:[self class]];
}

@end
