//
//  BRTestSupport.h
//  BRFullTextSearch
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <XCTest/XCTest.h>

@interface BRTestSupport : XCTestCase

@property (nonatomic, readonly) NSBundle *bundle;

+ (NSString *)UUID;
+ (NSString *)temporaryPathWithPrefix:(NSString *)prefix suffix:(NSString *)suffix directory:(BOOL)directory;

@end
