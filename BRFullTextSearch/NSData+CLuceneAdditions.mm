//
//  NSData+CLuceneAdditions.m
//  BRFullTextSearch
//
//  Created by Matt on 2/21/15.
//  Copyright (c) 2015 Blue Rocket. All rights reserved.
//

#import "NSData+CLuceneAdditions.h"

@implementation NSData (CLuceneAdditions)

- (const TCHAR *)asCLuceneString {
	// we assume we're already null-terminated!
	return (const TCHAR *)[self bytes];
}

@end
