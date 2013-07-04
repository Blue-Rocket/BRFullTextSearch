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
+ (NSString *)stringWithCLuceneString:(const TCHAR *)charText {
    return [[NSString alloc] initWithBytes:charText
									length:wcslen(charText) * sizeof(*charText)
								  encoding:NSUTF32LittleEndianStringEncoding];
}

@end
