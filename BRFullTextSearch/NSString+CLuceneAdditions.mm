//
//  NSString+CLuceneAdditions.m
//  BRFullTextSearch
//
//  Created by Matt on 7/1/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "NSString+CLuceneAdditions.h"

@implementation NSString (CLuceneAdditions)

- (const TCHAR *)asCLuceneString {
	return (const TCHAR *)[self cStringUsingEncoding:NSUTF32LittleEndianStringEncoding];
}

- (NSData *)asCLuceneStringData {
	NSData *bytes = [self dataUsingEncoding:NSUTF32LittleEndianStringEncoding];
	NSMutableData *terminated = [NSMutableData dataWithData:bytes];
	TCHAR eof = '\0';
	[terminated appendBytes:&eof length:sizeof(TCHAR)];
	return terminated;
}

+ (NSString *)stringWithCLuceneString:(const TCHAR *)charText {
	if ( charText == NULL ) {
		return nil;
	}
	const NSUInteger len = wcslen(charText) * sizeof(TCHAR);
    NSString *result = [[NSString alloc] initWithBytes:charText length:len encoding:NSUTF32LittleEndianStringEncoding];
	// might return nil here
	if ( result == nil ) {
		NSLog(@"Error decoding CLucene string length %lu to NSString", (unsigned long)len);
	}
	return result;
}

@end
