//
//  BRIndexUpdateContext.h
//  BRFullTextSearch
//
//  Created by Matt on 6/20/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

/**
 * A search engine implementation-specific context for batch index update operations.
 *
 * The `BRSearchService` batch API methods accept an object conforming to this protocol,
 * to aid keeping track of any necessary state to complete a batch set of operations.
 */
@protocol BRIndexUpdateContext <NSObject>

@optional

/** Boolean flag to request that the index should be optimized for searching when the update is complete. */
@property (nonatomic) BOOL optimizeWhenDone;

@end
