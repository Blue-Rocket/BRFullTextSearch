//
//  CoreDataManager.h
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BRSearchService;

@interface CoreDataManager : NSObject

@property (nonatomic, strong) id<BRSearchService> searchService;

@end
