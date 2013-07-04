//
//  BRSearchFields.m
//  BRFullTextSearch
//
//  Created by Matt on 6/7/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRSearchFields.h"

NSString * const kBRSearchFieldNameIdentifier = @"id";
NSString * const kBRSearchFieldNameObjectType = @"o";
NSString * const kBRSearchFieldNameTitle = @"t";
NSString * const kBRSearchFieldNameValue = @"v";
NSString * const kBRSearchFieldNameTimestamp = @"s";

NSString * StringForBRSearchObjectType(BRSearchObjectType type) {
	const char data[] = {type, '\0'};
	return [NSString stringWithCString:data encoding:NSASCIIStringEncoding];
}

BRSearchObjectType BRSearchObjectTypeForString(NSString * string) {
	if ( [string length] < 1 ) {
		return '\0';
	}
	return [string cStringUsingEncoding:NSASCIIStringEncoding][0];
}
