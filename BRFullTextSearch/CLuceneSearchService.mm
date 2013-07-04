//
//  CLuceneSearchService.m
//  BRFullTextSearch
//
//  Created by Matt on 6/28/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "CLuceneSearchService.h"

#import "CLucene.h"
#import "BRNoLockFactory.h"
#import "BRSnowballAnalyzer.h"
#import "CLuceneIndexUpdateContext.h"
#import "CLuceneSearchResult.h"
#import "CLuceneSearchResults.h"
#import "NSString+CLuceneAdditions.h"

static const char * kWriteQueueName = "us.bluerocket.CLucene.IndexWrite";
static const NSInteger kDefaultIndexUpdateOptimizeThreshold = 25;
static const NSInteger kDefaultIndexUpdateBatchBufferSize = 50;

static const NSTimeInterval kMaxWait = 300;

// our serial update queue... only one writer allowed
static dispatch_queue_t IndexWriteQueue;

using namespace lucene::analysis;
using namespace lucene::index;
using namespace lucene::document;
using namespace lucene::queryParser;
using namespace lucene::search;
using namespace lucene::store;

@implementation CLuceneSearchService {
	NSString *indexPath;
	NSArray *generalTextFields;
	NSInteger indexUpdateOptimizeThreshold;
	Directory *dir;
	std::auto_ptr<Analyzer> defaultAnalyzer;
	std::tr1::shared_ptr<Searcher> searcher;
	NSBundle *bundle;
	NSString *defaultAnalyzerLanguage;
}

@synthesize indexUpdateOptimizeThreshold;
@synthesize bundle, defaultAnalyzerLanguage;

- (id)init {
	NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
	NSString *path = [[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0]
					   stringByAppendingPathComponent:applicationName] stringByAppendingPathComponent:@"lucene.idx"];
	return [self initWithIndexPath:path];
}

- (id)initWithIndexPath:(NSString *)path {
	if ( (self = [super init]) ) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			IndexWriteQueue = dispatch_queue_create(kWriteQueueName, DISPATCH_QUEUE_SERIAL);
			//log4Info(@"Search index queue %s created", kWriteQueueName);
		});
		
		generalTextFields = @[kBRSearchFieldNameTitle, kBRSearchFieldNameValue];
		indexPath = path;
		indexUpdateOptimizeThreshold = kDefaultIndexUpdateOptimizeThreshold;
		bundle = [NSBundle mainBundle];
		defaultAnalyzerLanguage = @"en";

		// create Directory instance, using NoLockFactory because we have a serial queue for all update operations
		dir = FSDirectory::getDirectory([path cStringUsingEncoding:NSUTF8StringEncoding], BRNoLockFactory::getNoLockFactory());
		
		//log4Debug(@"%@ search index %@", (create ? @"Created" : @"Opened"), path);
	}
	return self;
}

- (void)dealloc {
	[self resetSearcher];
	if ( dir != NULL ) {
		dir->close();
		// we don't delete dir, we didn't create it
		dir = NULL;
	}
}

+ (NSSet *)stopWordsForStemmerProgram:(NSString *)lang bundle:(NSBundle *)bundle {
	static NSMutableDictionary *stopWordsCache;
	if ( stopWordsCache == nil ) {
		stopWordsCache = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	NSSet *result = [stopWordsCache objectForKey:lang];
	if ( result == nil ) {
		NSBundle *bun = (bundle != nil ? bundle : [NSBundle mainBundle]);
		NSString *stopWordsPath = [bun pathForResource:@"stop-words" ofType:@"txt" inDirectory:nil forLocalization:lang];
		if ( stopWordsPath != nil ) {
			NSArray *words = [[NSString stringWithContentsOfFile:stopWordsPath encoding:NSUTF8StringEncoding error:nil]
							  componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
			result = [NSSet setWithArray:words];
			result = [result filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"self != ''"]]; // remove empty strings
			[stopWordsCache setObject:result forKey:lang];
		}
	}
	return result;
}

+ (const TCHAR **)stopWordsArrayForStemmerProgram:(NSString *)lang bundle:(NSBundle *)bundle {
	NSSet *words = [self stopWordsForStemmerProgram:lang bundle:bundle];
	const TCHAR **result = (const TCHAR **)malloc(sizeof(TCHAR) * [words count] + 1);
	NSUInteger i = 0;
	for ( NSString *word in words ) {
		result[i++] = [word asCLuceneString];
	}
	result[i] = NULL;
	return result;
}

+ (BOOL)indexExistsAtPath:(NSString *)path {
	// we're merely testing for the existance of any file within the path directory
	return ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NULL] == YES
			&& [[[NSFileManager defaultManager] enumeratorAtPath:path] nextObject] != nil);
}

#pragma mark - Accessors

- (Searcher *)searcher {
	if ( searcher.get() == NULL ) {
		// create the index directory, if it doesn't already exist
		BOOL create = ([CLuceneSearchService indexExistsAtPath:indexPath] == NO);
		if ( create ) {
			// create modifier now, which will create the index if it doesn't exist
			dispatch_sync(IndexWriteQueue, ^{
				IndexModifier modifier(dir, [self defaultAnalyzer], (bool)create);
				modifier.close();
			});
		}
		searcher.reset(new IndexSearcher(dir));
	}
	return searcher.get();
}

- (std::auto_ptr<Analyzer>)analyzerForLanguage:(NSString *)lang {
	// create snowball analyzer, with stop words loaded from text file resource
	const TCHAR **stopWords = [CLuceneSearchService stopWordsArrayForStemmerProgram:lang bundle:bundle];
	const TCHAR *snowballLanguage;
	if ( [@"da" isEqualToString:lang] ) {
		snowballLanguage = _T("danish");
	} else if ( [@"de" isEqualToString:lang] ) {
		snowballLanguage = _T("german");
	} else if ( [@"es" isEqualToString:lang] ) {
		snowballLanguage = _T("spanish");
	} else if ( [@"fi" isEqualToString:lang] ) {
		snowballLanguage = _T("finnish");
	} else if ( [@"fr" isEqualToString:lang] ) {
		snowballLanguage = _T("french");
	} else if ( [@"it" isEqualToString:lang] ) {
		snowballLanguage = _T("italian");
	} else if ( [@"nl" isEqualToString:lang] ) {
		snowballLanguage = _T("dutch");
	} else if ( [@"no" isEqualToString:lang] ) {
		snowballLanguage = _T("norwegian");
	} else if ( [@"pt" isEqualToString:lang] ) {
		snowballLanguage = _T("portuguese");
	} else if ( [@"ru" isEqualToString:lang] ) {
		snowballLanguage = _T("russian");
	} else if ( [@"sv" isEqualToString:lang] ) {
		snowballLanguage = _T("swedish");
	} else {
		snowballLanguage = _T("english");
	}
	std::auto_ptr<Analyzer> a(new lucene::analysis::snowball::BRSnowballAnalyzer(snowballLanguage, stopWords));
	free(stopWords);
	return a;
}

- (Analyzer *)defaultAnalyzer {
	if ( defaultAnalyzer.get() == NULL ) {
		defaultAnalyzer.reset([self analyzerForLanguage:defaultAnalyzerLanguage].release());
	}
	return defaultAnalyzer.get();
}

#pragma mark - Supporting API

- (void)resetSearcher {
	if ( searcher.get() != NULL ) {
		searcher->close();
		searcher.reset();
	}
}

- (NSString *)userDefaultsIndexUpdateCountKey {
	return [NSString stringWithFormat:@"CLuceneIndexUpdateCount-%@", @"TODO"]; // TODO: hash of indexPath
}

#pragma mark - Bulk API

- (void)bulkUpdateIndex:(BRSearchServiceIndexUpdateBlock)updateBlock queue:(dispatch_queue_t)finishedQueue finished:(void (^)())finishedBlock {
	dispatch_async(IndexWriteQueue, ^{
		@autoreleasepool {
			NSString *defaultsUpdateKey = [self userDefaultsIndexUpdateCountKey];
			BOOL create = ([CLuceneSearchService indexExistsAtPath:indexPath] == NO);
			std::auto_ptr<IndexModifier> modifier(new IndexModifier(dir, [self defaultAnalyzer], (bool)create));
			CLuceneIndexUpdateContext *ctx = [[CLuceneIndexUpdateContext alloc] initWithIndexModifier:modifier.get()];
			@try {
				updateBlock(ctx);
				[self flushBufferedDocuments:ctx];
			} @finally {
				// keep track of index updates, to optimize index
				NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
				const NSInteger updateCount = [ud integerForKey:defaultsUpdateKey] + 1;
				if ( updateCount > indexUpdateOptimizeThreshold ) {
					//log4Debug(@"Optimizing search index; %ld updates have occurred", (long)updateCount);
					modifier->optimize();
					[ud setInteger:0 forKey:defaultsUpdateKey];
				} else {
					[ud setInteger:updateCount forKey:defaultsUpdateKey];
				}
				modifier->close();
				dispatch_async(dispatch_get_main_queue(), ^{
					[self resetSearcher];
				});
			}
			if ( finishedBlock != NULL ) {
				dispatch_queue_t callbackQueue = (finishedQueue != NULL ? finishedQueue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
				dispatch_async(callbackQueue, finishedBlock);
			}
		}
	});
}

- (void)bulkUpdateIndexAndWait:(BRSearchServiceIndexUpdateBlock)updateBlock {
	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block BOOL finished = NO;
	[self bulkUpdateIndex:updateBlock queue:NULL finished:^ {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
	}];
	
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMaxWait]];
	[condition unlock];
	if ( [NSThread isMainThread] ) {
		[self resetSearcher];
	}
}

- (void)addObjectToIndex:(id<BRIndexable>)object context:(id<BRIndexUpdateContext>)updateContext {
	CLuceneIndexUpdateContext *ctx = (CLuceneIndexUpdateContext *)updateContext;
	
	// delete any existing document now
	NSString *idValue = [self idValue:object];
	Term *idTerm = _CLNEW Term([kBRSearchFieldNameIdentifier asCLuceneString], [idValue asCLuceneString]);
#ifdef LOGGING
	int32_t deletedCount =
#endif
	[ctx modifier]->deleteDocuments(idTerm);
	log4Debug(@"Removed %d documents from search index", deletedCount);
	delete idTerm, idTerm = NULL;
	
	// create our Document to index, but buffer into context for inserting later for better performance
	Document *doc = _CLNEW Document();
	std::auto_ptr<Document> d(doc);
	[self populateDocument:doc withObject:object];
	[ctx addDocument:d];
	log4Debug(@"Buffered document %@ for indexing later (%lu buffered)", idValue, (unsigned long)[ctx documentCount]);
	
	if ( [ctx documentCount] >= kDefaultIndexUpdateBatchBufferSize ) {
		[self flushBufferedDocuments:updateContext];
	}
}

- (void)flushBufferedDocuments:(CLuceneIndexUpdateContext *)updateContext {
	[updateContext enumerateDocumentsUsingBlock:^(Document *doc, BOOL *remove) {
		log4Debug(@"Adding document %@ to index", [NSString stringWithCLuceneString:doc->get([kBRSearchFieldNameIdentifier asCLuceneString])]);
		[updateContext modifier]->addDocument(doc);
		*remove = YES;
	}];
}

#pragma mark - Internal support

- (NSString *)idValueForType:(BRSearchObjectType)objectType identifier:(NSString *)identifier {
	NSString *type = StringForBRSearchObjectType(objectType);
	return [type stringByAppendingString:identifier];
}

- (NSString *)idValue:(id<BRIndexable>)object {
	return [self idValueForType:[object indexObjectType] identifier:[object indexIdentifier]];
}


- (void)populateDocument:(Document *)doc withObject:(id<BRIndexable>)object {
	doc->add(* _CLNEW Field([kBRSearchFieldNameIdentifier asCLuceneString],
							[[self idValue:object] asCLuceneString],
							Field::STORE_YES | Field::INDEX_UNTOKENIZED,
							true));
	doc->add(* _CLNEW Field([kBRSearchFieldNameObjectType asCLuceneString],
							[StringForBRSearchObjectType([object indexObjectType]) asCLuceneString],
							Field::STORE_YES | Field::INDEX_UNTOKENIZED,
							true));

	NSDictionary *fields = [object indexFieldsDictionary];
	for ( NSString *fieldName in fields ) {
		int storeType = Field::STORE_YES;
		int indexType = Field::INDEX_TOKENIZED;
		if ( [object respondsToSelector:@selector(indexFieldStorageType:)] ) {
			switch ( [object indexFieldStorageType:fieldName] ) {
				case BRIndexableStorageTypeNone:
					storeType = Field::STORE_NO;
					break;
					
				case BRIndexableStorageTypeCompressed:
					storeType = Field::STORE_COMPRESS;
					break;
					
				default:
					// leave as LCStore_YES
					break;
			}
		}
		if ( [object respondsToSelector:@selector(indexFieldIndexType:)] ) {
			switch ( [object indexFieldIndexType:fieldName] ) {
				case BRIndexableIndexTypeNone:
					indexType = Field::INDEX_NO;
					break;
					
				case BRIndexableIndexTypeUntokenized:
					indexType = Field::INDEX_UNTOKENIZED;
					
				default:
					// leave as LCIndex_Tokenized
					break;
			}
		}
		Field *f = _CLNEW Field([fieldName asCLuceneString], storeType | indexType);
		id fieldValue = [fields objectForKey:fieldName];
		if ( [fieldValue isKindOfClass:[NSString class]] ) {
			f->setValue((TCHAR *)[fieldValue asCLuceneString], true);
		} else {
			NSAssert1(NO, @"Unsupported field value type: %@", NSStringFromClass([fieldValue class]));
		}
		doc->add(*f);
	}
}

#pragma mark - Incremental index API

- (void)addObjectToIndex:(id<BRIndexable>)object queue:(dispatch_queue_t)queue finished:(void (^)())finished {
	[self addObjectsToIndex:(object == nil ? nil : @[object]) queue:queue finished:finished];
}

- (void)addObjectsToIndex:(NSArray *)objects queue:(dispatch_queue_t)finishedQueue finished:(void (^)())finished {
	if ( [objects count] < 1 ) {
		if ( finished != NULL ) {
			dispatch_queue_t callbackQueue = (finishedQueue != NULL
											  ? finishedQueue
											  : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
			dispatch_async(callbackQueue, finished);
		}
		return;
	}
	
	[self bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
		for ( id<BRIndexable> obj in objects ) {
			[self addObjectToIndex:obj context:updateContext];
		}
	} queue:finishedQueue finished:finished];
}

- (void)addObjectToIndexAndWait:(id<BRIndexable>)object {
	if ( object == nil ) {
		return;
	}
	[self addObjectsToIndexAndWait:@[object]];
}

- (void)addObjectsToIndexAndWait:(NSArray *)objects {
	if ( [objects count] < 1 ) {
		return;
	}
	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block BOOL finished = NO;
	[self addObjectsToIndex:objects queue:NULL finished:^ {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
	}];
	
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMaxWait]];
	log4Debug(@"%@ %d objects to index", (finished ? @"Added" : @"Failed to add"), [objects count]);
	[condition unlock];
	if ( [NSThread isMainThread] ) {
		[self resetSearcher];
	}
}

#pragma mark - Remove from index

- (std::auto_ptr<Query>)queryForObjects:(BRSearchObjectType)type withIdentifiers:(NSSet *)identifiers {
	std::auto_ptr<Query> result;
	std::auto_ptr<BooleanQuery> rootQuery(new BooleanQuery(false));
	for ( NSString *identifier in identifiers ) {
		Term *term = new Term([kBRSearchFieldNameIdentifier asCLuceneString], [[self idValueForType:type identifier:identifier] asCLuceneString]);
		TermQuery *termQuery = new TermQuery(term); // assumes ownership of Term
		rootQuery->add(termQuery, BooleanClause::SHOULD); // rootQuery assumes ownership of TermQuery
	}
	result.reset(rootQuery.release());
	return result;
}

- (void)removeObjectsFromIndexWithQuery:(std::auto_ptr<Query>)query queue:(dispatch_queue_t)finishedQueue finished:(void (^)())finishedBlock {
	Query *q = query.release();
	[self bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
		std::auto_ptr<Query> localQuery(q);
		std::auto_ptr<Hits> hits([self searcher]->search(localQuery.get()));
		CLuceneIndexUpdateContext *ctx = (CLuceneIndexUpdateContext *)updateContext;
		IndexModifier *modifier = [ctx modifier];
		for ( size_t i = 0, len = hits->length(); i < len; i++ ) {
			modifier->deleteDocument(hits->id(i));
		}
	} queue:finishedQueue finished:finishedBlock];
}

- (void)removeObjectsFromIndex:(BRSearchObjectType)type withIdentifiers:(NSSet *)identifiers
						 queue:(dispatch_queue_t)queue finished:(void (^)())finished {
	if ( [identifiers count] < 1 ) {
		if ( finished != NULL ) {
			dispatch_queue_t callbackQueue = (queue != NULL ? queue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
			dispatch_async(callbackQueue, finished);
		}
		return;
	}

	// search for all matching objects to delete
	std::auto_ptr<Query> query = [self queryForObjects:type withIdentifiers:identifiers];
	[self removeObjectsFromIndexWithQuery:query queue:queue finished:finished];
}

- (void)removeObjectsFromIndexAndWait:(BRSearchObjectType)type withIdentifiers:(NSSet *)identifiers {
	if ( [identifiers count] < 1 ) {
		return;
	}
	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block BOOL finished = NO;
	[self removeObjectsFromIndex:type withIdentifiers:identifiers queue:NULL finished:^ {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
	}];
	
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMaxWait]];
	[condition unlock];
	if ( [NSThread isMainThread] ) {
		[self resetSearcher];
	}
}

- (void)removeObjectsFromIndexMatchingPredicate:(NSPredicate *)predicate
										  queue:(dispatch_queue_t)finishedQueue
									   finished:(void (^)())finished {
	std::auto_ptr<Query> query = [self queryForPredicate:predicate analyzer:nil];
	[self removeObjectsFromIndexWithQuery:query queue:finishedQueue finished:finished];
}

- (void)removeObjectsFromIndexMatchingPredicateAndWait:(NSPredicate *)predicate {
	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block BOOL finished = NO;
	[self removeObjectsFromIndexMatchingPredicate:predicate queue:NULL finished:^ {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
	}];
	
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMaxWait]];
	[condition unlock];
	if ( [NSThread isMainThread] ) {
		[self resetSearcher];
	}
}

#pragma mark - Search API

- (id<BRSearchResults>)search:(NSString *)query {
	std::auto_ptr<BooleanQuery> rootQuery(new BooleanQuery(false));
	QueryParser parser([kBRSearchFieldNameValue asCLuceneString], [self defaultAnalyzer]);
	for ( NSString *fieldName in generalTextFields ) {
		Query *q = parser.parse([query asCLuceneString], [fieldName asCLuceneString], [self defaultAnalyzer]);
		rootQuery.get()->add(q, true, false, false);
	}
	std::auto_ptr<Hits> hits([self searcher]->search(rootQuery.get()));
	return [[CLuceneSearchResults alloc] initWithHits:hits];
}

- (id<BRSearchResult>)findObject:(BRSearchObjectType)type withIdentifier:(NSString *)identifier {
	NSString *idValue = [self idValueForType:type identifier:identifier];
	Term *idTerm = _CLNEW Term([kBRSearchFieldNameIdentifier asCLuceneString], [idValue asCLuceneString]);
	std::auto_ptr<TermQuery> idQuery(_CLNEW TermQuery(idTerm)); // assumes ownership of idTerm
	std::auto_ptr<Hits> hits([self searcher]->search(idQuery.get()));
	CLuceneSearchResult *result = nil;
	if ( hits->length() > 0 ) {
		// return first match, taking owning the Hits pointer
		result = [[[CLuceneSearchResult searchResultClassForDocument:hits->doc(0)] alloc] initWithOwnedHits:hits index:0];
	}
	return result;
}

- (id<BRSearchResults>)searchWithQuery:(std::auto_ptr<Query>)query
							  sortBy:(NSString *)sortFieldName
							sortType:(BRSearchSortType)sortType
						   ascending:(BOOL)ascending {
	SortField *sortField = new SortField([sortFieldName asCLuceneString], (sortType == BRSearchSortTypeInteger
														  ? SortField::INT
														  : SortField::STRING), !ascending);
	
	// this ensures we have consistent results of sortField has duplicate values
	SortField *docField = (ascending ? SortField::FIELD_DOC() : new SortField(NULL, SortField::DOC, true));
	SortField *fields[] = {sortField, docField, NULL}; // requires NULL last element
	std::auto_ptr<Sort> sort(new Sort(fields)); // assumes ownership of fields
	std::auto_ptr<Hits> hits([self searcher]->search(query.get(), sort.get()));
	return [[CLuceneSearchResults alloc] initWithHits:hits sort:sort query:query searcher:searcher];
}

- (id<BRSearchResults>)search:(NSString *)query
					 sortBy:(NSString *)sortFieldName
				   sortType:(BRSearchSortType)sortType
				  ascending:(BOOL)ascending {
	std::auto_ptr<Query> rootQuery(new BooleanQuery(false));
	QueryParser parser([kBRSearchFieldNameValue asCLuceneString], [self defaultAnalyzer]);
	for ( NSString *fieldName in generalTextFields ) {
		Query *q = parser.parse([query asCLuceneString], [fieldName asCLuceneString], [self defaultAnalyzer]);
		((BooleanQuery *)rootQuery.get())->add(q, true, false, false);
	}
	return [self searchWithQuery:rootQuery sortBy:sortFieldName sortType:sortType ascending:ascending];
}

#pragma mark - Predicate search API

- (std::auto_ptr<Query>)queryForPredicate:(NSPredicate *)predicate analyzer:(Analyzer *)theAnalyzer {
	std::auto_ptr<Query> result;
	if ( [predicate isKindOfClass:[NSComparisonPredicate class]] ) {
		NSComparisonPredicate *comparison = (NSComparisonPredicate *)predicate;
		NSExpression *lhs = [comparison leftExpression];
		NSAssert1([lhs expressionType] == NSKeyPathExpressionType, @"Unsupported LHS expression type %d", [lhs expressionType]);
		NSExpression *rhs = [comparison rightExpression];
		NSAssert1([rhs expressionType] == NSConstantValueExpressionType, @"Unsupported RHS expression type %d", [lhs expressionType]);
		switch ( [comparison predicateOperatorType] ) {
			case NSEqualToPredicateOperatorType:
			{
				Term *term = new Term([[lhs keyPath] asCLuceneString], [[rhs constantValue] asCLuceneString]);
				result.reset(new TermQuery(term)); // TermQuery assumes ownership of idTerm
			}
				break;
				
			case NSLikePredicateOperatorType:
			case NSMatchesPredicateOperatorType:
			{
				if ( theAnalyzer == nil ) {
					theAnalyzer = [self defaultAnalyzer];
				}
				QueryParser parser([[lhs keyPath] asCLuceneString], theAnalyzer);
				Query *q = parser.parse([[rhs constantValue] asCLuceneString], [[lhs keyPath] asCLuceneString], theAnalyzer);
				result.reset(q);
			}
				break;
				
			case NSBeginsWithPredicateOperatorType:
			{
				Term *term = new Term([[lhs keyPath] asCLuceneString], [[rhs constantValue] asCLuceneString]);
				result.reset(new PrefixQuery(term)); // PrefixQuery assumes ownership of Term
			}
				break;
				
			default:
				NSAssert1(NO, @"Unsupported predicate operator type: %d", [comparison predicateOperatorType]);
				break;
		}
		
	} else if ( [predicate isKindOfClass:[NSCompoundPredicate class]] ) {
		NSCompoundPredicate *compound = (NSCompoundPredicate *)predicate;
		BooleanQuery *boolean = new BooleanQuery(false);
		BooleanClause::Occur occur;
		switch ( [compound compoundPredicateType] ) {
			case NSNotPredicateType:
				occur = BooleanClause::MUST_NOT;
				break;
				
			case NSAndPredicateType:
				occur = BooleanClause::MUST;
				break;
				
			default:
				occur = BooleanClause::SHOULD;
				break;
		}
		for ( NSPredicate *subpredicate in [compound subpredicates] ) {
			std::auto_ptr<Query> subQuery = [self queryForPredicate:subpredicate analyzer:theAnalyzer];
			boolean->add(subQuery.release(), occur); // transfer ownership of subQuery to boolean
		}
		result.reset(boolean);
	}
	return result;
}

- (id<BRSearchResults>)searchWithPredicate:(NSPredicate *)predicate
									sortBy:(NSString *)sortFieldName
								  sortType:(BRSearchSortType)sortType
								 ascending:(BOOL)ascending {
	std::auto_ptr<Query> query = [self queryForPredicate:predicate analyzer:[self defaultAnalyzer]];
	return [self searchWithQuery:query sortBy:sortFieldName sortType:sortType ascending:ascending];
}

@end
