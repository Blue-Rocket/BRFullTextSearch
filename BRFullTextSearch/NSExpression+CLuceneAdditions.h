//
//  NSExpression+CLuceneAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 8/22/13.
//  Copyright (c) 2013 Blue Rocket. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CLucene.h"

@interface NSExpression (CLuceneAdditions)

- (const TCHAR *)constantValueCLuceneString;

@end
