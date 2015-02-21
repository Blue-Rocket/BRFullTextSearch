//
//  NSString+CLuceneAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 7/1/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "CLucene/_ApiHeader.h"

@interface NSString (CLuceneAdditions)

/**
 Get a Lucene character string. Note the returned data is only valid for as long as the receiver
 is valid, and only "simple" strings (like field names) should use this. For full character support
 use the @c asCLuceneStringData method.
 
 @return A pointer to character data encoded as a null-terminated Lucene string.
 */
- (const TCHAR *)asCLuceneString;

/**
 Get a null-terminated Lucene string data object. This is suitable for all Lucene strings,
 and the caller can call @c asCLuceneString on the returned NSData to get the TCHAR data.
 
 @return A new NSData with bytes copied from the receiver.
 */
- (NSData *)asCLuceneStringData;

+ (NSString *)stringWithCLuceneString:(const TCHAR *)charText;

@end
