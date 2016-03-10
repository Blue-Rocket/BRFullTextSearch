//
//  SearchFields.h
//  BRFullTextSearch
//
//  Created by Matt on 6/7/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#ifdef __cplusplus
extern "C" {
#endif

NS_ASSUME_NONNULL_BEGIN
	
/** Search field constant for the search document unique identifier value (`id`). */
extern NSString *const kBRSearchFieldNameIdentifier;

/** Search field constant for the search document object type value (`o`). */
extern NSString *const kBRSearchFieldNameObjectType;

/** Search field constant for a title value (`t`). */
extern NSString *const kBRSearchFieldNameTitle;

/** Search field constant for a name value (`v`). */
extern NSString *const kBRSearchFieldNameValue;

/** Search field constant for a date value (`s`). */
extern NSString *const kBRSearchFieldNameTimestamp;

/** Type definition for a "type of" search object flag. Values are arbitrary and application dependent. */
typedef char BRSearchObjectType;

/**
 * Create a string from a `BRSearchObjectType`.
 *
 * @param type the search object type
 * @return the search object type as a string
 */
extern NSString *StringForBRSearchObjectType(BRSearchObjectType type);

/**
 * Create a `BRSearchObjectType` from a string.
 *
 * If the given string does not have at least one character in it, the null
 * character will be returned (`\0`). Otherwise the string will be interpreted
 * as ASCII characters and the first character returned.
 *
 * @param string the string
 * @return the search object type
 */
extern BRSearchObjectType BRSearchObjectTypeForString(NSString *string);

NS_ASSUME_NONNULL_END
	
#ifdef __cplusplus
}
#endif
