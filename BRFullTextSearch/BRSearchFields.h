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

extern NSString *const kBRSearchFieldNameIdentifier;
extern NSString *const kBRSearchFieldNameObjectType;
extern NSString *const kBRSearchFieldNameTitle;
extern NSString *const kBRSearchFieldNameValue;
extern NSString *const kBRSearchFieldNameTimestamp;

/** Type definition for a "type of" search object flag. */
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

#ifdef __cplusplus
}
#endif
