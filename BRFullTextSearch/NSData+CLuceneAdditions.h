//
//  NSData+CLuceneAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 2/21/15.
//  Copyright (c) 2015 Blue Rocket. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CLucene/_ApiHeader.h"

@interface NSData (CLuceneAdditions)

/**
 Get TCHAR data suitable for passing into CLucene. Note the pointer is only valid as long
 as the receiver is also valid.
 
 @return Pointer to Lucene string bytes
 */
- (const TCHAR *)asCLuceneString;

@end
