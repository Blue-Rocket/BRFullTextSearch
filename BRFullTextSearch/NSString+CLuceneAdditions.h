//
//  NSString+CLuceneAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 7/1/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "CLucene.h"

@interface NSString (CLuceneAdditions)

// these helpers aid in dealing with CLucene's wchar_t use for strings
- (const TCHAR *)asCLuceneString;
+ (NSString *)stringWithCLuceneString:(const TCHAR *)charText;

@end
