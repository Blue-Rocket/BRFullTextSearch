//
//  NSExpression+CLuceneAdditions.m
//  BRFullTextSearch
//
//  Created by Matt on 8/22/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import "NSExpression+CLuceneAdditions.h"

#import "NSDate+BRFullTextSearchAdditions.h"
#import "NSString+CLuceneAdditions.h"

@implementation NSExpression (CLuceneAdditions)

- (const TCHAR *)constantValueCLuceneString {
	id val = [self constantValue];
	NSString *result = nil;
	if ( [val isKindOfClass:[NSString class]] ) {
		result = (NSString *)val;
	} else if ( [val isKindOfClass:[NSDate class]] ) {
		result = [(NSDate *)val asIndexTimestampString];
	} else {
		result = [val description];
	}
	return [result asCLuceneString];
}

@end
