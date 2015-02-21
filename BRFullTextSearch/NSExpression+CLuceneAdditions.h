//
//  NSExpression+CLuceneAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 8/22/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "CLucene/_ApiHeader.h"

@interface NSExpression (CLuceneAdditions)

- (const TCHAR *)constantValueCLuceneString;

@end
