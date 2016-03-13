//
//  BRSortDescriptor.h
//  BRFullTextSearch
//
//  Created by Matt on 25/02/16.
//  Copyright © 2016 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
	
/**
 * A search result field value sort type.
 *
 * When sorting search results by a particular field, all field values are assumed to
 * have the same data type, as specified by these constants.
 */
typedef NS_ENUM (unsigned int, BRSearchSortType) {
	/** Sort based on lexicographical order of field values. */
	BRSearchSortTypeString = 0,
	
	/** Sort based on integer order of field values. */
	BRSearchSortTypeInteger,
	
	/** Sort based on floating point order of field values. */
	BRSearchSortTypeFloat,
};
	
#ifdef __cplusplus
}
#endif

/**
 API for a description of sort characteristics.
 */
@protocol BRSortDescriptor <NSObject>

/** The name of the search document field to order the matches by. */
@property (nonatomic, readonly) NSString *sortFieldName;

/** The type of sort to use. */
@property (nonatomic, readonly) BRSearchSortType sortType;

/** YES to sort in ascending order, NO for descending. */
@property (nonatomic, readonly, getter=isAscending) BOOL ascending;

@end

NS_ASSUME_NONNULL_END
