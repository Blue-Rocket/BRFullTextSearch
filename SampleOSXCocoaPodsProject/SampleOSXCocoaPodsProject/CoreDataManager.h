//
//  CoreDataManager.h
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

@protocol BRSearchService;

@interface CoreDataManager : NSObject

@property (nonatomic, strong) id<BRSearchService> searchService;

@end
