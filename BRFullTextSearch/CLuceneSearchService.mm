//
//  CLuceneSearchService.mm
//  BRFullTextSearch
//
//  Created by Matt on 6/28/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "CLuceneSearchService.h"

#import "CLucene.h"
#import "CLucene/_ApiHeader.h"
#import "ConstantScoreQuery.h"
#import "BRNoLockFactory.h"
#import "BRSnowballAnalyzer.h"
#import "CLuceneIndexUpdateContext.h"
#import "CLuceneSearchResult.h"
#import "CLuceneSearchResults.h"
#import "NSData+CLuceneAdditions.h"
#import "NSExpression+CLuceneAdditions.h"
#import "NSString+CLuceneAdditions.h"
#import "CLucene/util/_MD5Digester.h"

#define queue_retain(queue) if ( queue != NULL ) { dispatch_retain(queue); }
#define queue_release(queue) if ( queue != NULL ) { dispatch_release(queue); }

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
		defaultAnalyzerLanguage = [[NSLocale preferredLanguages] firstObject];
		
		NSFileManager *fm = [NSFileManager new];
		if ( ![fm fileExistsAtPath:indexPath] ) {
			[fm createDirectoryAtPath:indexPath withIntermediateDirectories:YES attributes:nil error:nil];
		}

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
	const TCHAR **result = (const TCHAR **)malloc(sizeof(TCHAR*) * [words count] + 1);
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

- (std::tr1::shared_ptr<Searcher>)searcher {
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
	return searcher;
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
	char *dirHash = NULL;
	if ( indexPath != nil ) {
		dirHash = lucene::util::MD5String((char *)[indexPath cStringUsingEncoding:NSUTF8StringEncoding]);
	}
	NSString *result = [NSString stringWithFormat:@"CLuceneIndexUpdateCount-%s", dirHash];
	if ( dirHash != NULL ) {
		free(dirHash);
	}
	return result;
}

#pragma mark - Bulk API

- (void)bulkUpdateIndex:(BRSearchServiceIndexUpdateBlock)updateBlock queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceUpdateCallbackBlock)finishedBlock {
	queue_retain(finishedQueue);
	dispatch_async(IndexWriteQueue, ^{
		@autoreleasepool {
			NSError *error = nil;
			int finishedUpdateCount = 0;
			try {
				NSString *defaultsUpdateKey = [self userDefaultsIndexUpdateCountKey];
				BOOL create = ([CLuceneSearchService indexExistsAtPath:indexPath] == NO);
				std::auto_ptr<IndexModifier> modifier(new IndexModifier(dir, [self defaultAnalyzer], (bool)create));
				CLuceneIndexUpdateContext *ctx = [[CLuceneIndexUpdateContext alloc] initWithIndexModifier:modifier.get()];
				@try {
					updateBlock(ctx);
					[self flushBufferedDocuments:ctx];
					finishedUpdateCount = ctx.updateCount;
				} @finally {
					// keep track of index updates, to optimize index
					NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
					const NSInteger updateCount = [ud integerForKey:defaultsUpdateKey] + 1;
					if ( updateCount > indexUpdateOptimizeThreshold ) {
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
			} catch ( CLuceneError &ex ) {
				finishedUpdateCount = -1;
				error = [NSError errorWithDomain:BRSearchServiceErrorDomain code:ex.number() userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithCLuceneString:ex.twhat()]}];
				NSLog(@"Error %d adding object to index: %@", ex.number(), [NSString stringWithCLuceneString:ex.twhat()]);
			}
			if ( finishedBlock != NULL ) {
				dispatch_queue_t callbackQueue = (finishedQueue != NULL ? finishedQueue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
				dispatch_async(callbackQueue, ^{
					finishedBlock(finishedUpdateCount, error);
				});
			}
		}
		queue_release(finishedQueue);
	});
}

- (BOOL)bulkUpdateIndexAndWait:(BRSearchServiceIndexUpdateBlock)updateBlock error:(NSError *__autoreleasing *)error {
	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block BOOL finished = NO;
	__block NSError *updateError = nil;
	[self bulkUpdateIndex:updateBlock queue:NULL finished:^(int updateCount, NSError *localError) {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
		updateError = localError;
	}];
	
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMaxWait]];
	[condition unlock];
	if ( [NSThread isMainThread] ) {
		[self resetSearcher];
	}
	if ( error != nil ) {
		*error = updateError;
	}
	return (finished && updateError == nil);
}

- (void)addObjectToIndex:(id<BRIndexable>)object context:(id<BRIndexUpdateContext>)updateContext {
	CLuceneIndexUpdateContext *ctx = (CLuceneIndexUpdateContext *)updateContext;
	
	// delete any existing document now
	[self removeObjectFromIndex:[object indexObjectType] withIdentifier:[object indexIdentifier] context:updateContext];
	
	// create our Document to index, but buffer into context for inserting later for better performance
	Document *doc = new Document();
	std::auto_ptr<Document> d(doc);
	[self populateDocument:doc withObject:object];
	[ctx addDocument:d];
	//log4Debug(@"Buffered document %@ for indexing later (%lu buffered)", [self idValue:object], (unsigned long)[ctx documentCount]);
	
	if ( [ctx documentCount] >= kDefaultIndexUpdateBatchBufferSize ) {
		[self flushBufferedDocuments:updateContext];
	}
}

- (int)removeObjectFromIndex:(BRSearchObjectType)type withIdentifier:(NSString *)identifier context:(id<BRIndexUpdateContext>)updateContext {
	CLuceneIndexUpdateContext *ctx = (CLuceneIndexUpdateContext *)updateContext;
	Term *idTerm = new Term([kBRSearchFieldNameIdentifier asCLuceneString], [[self idValueForType:type identifier:identifier] asCLuceneString]);
	int32_t deletedCount = [ctx modifier]->deleteDocuments(idTerm);
	//log4Debug(@"Removed %d documents from search index", deletedCount);
	ctx.updateCount += deletedCount;
	_CLLDECDELETE(idTerm);
	return deletedCount;
}

- (void)flushBufferedDocuments:(CLuceneIndexUpdateContext *)updateContext {
	[updateContext enumerateDocumentsUsingBlock:^(Document *doc, BOOL *remove) {
		//log4Debug(@"Adding document %@ to index", [NSString stringWithCLuceneString:doc->get([kBRSearchFieldNameIdentifier asCLuceneString])]);
		[updateContext modifier]->addDocument(doc);
		updateContext.updateCount++;
		*remove = YES;
	}];
}

- (int)removeObjectsFromIndexMatchingPredicate:(NSPredicate *)predicate context:(id<BRIndexUpdateContext>)updateContext  {
	std::auto_ptr<Query> query = [self queryForPredicate:predicate analyzer:nil parent:nil];
	return [self removeObjectsFromIndexWithQuery:query context:(CLuceneIndexUpdateContext *)updateContext];
}

- (int)removeObjectsFromIndexWithQuery:(std::auto_ptr<Query>)query context:(id<BRIndexUpdateContext>)updateContext {
	CLuceneIndexUpdateContext *ctx = (CLuceneIndexUpdateContext *)updateContext;
	std::auto_ptr<Hits> hits([ctx searcher]->search(query.get()));
	ctx.updateCount += (uint32_t)hits->length();
	IndexModifier *modifier = [ctx modifier];
	// Hmm: length() returns size_t, while id() expects int32_t... why the mismatch?
	for ( int32_t i = 0, len = (int32_t)hits->length(); i < len; i++ ) {
		modifier->deleteDocument(hits->id(i));
	}
	return (int)hits->length();
}

- (int)removeAllObjectsFromIndex:(id<BRIndexUpdateContext>)updateContext {
	CLuceneIndexUpdateContext *ctx = (CLuceneIndexUpdateContext *)updateContext;
	IndexModifier *modifier = [ctx modifier];
	int32_t docCount = modifier->docCount();
	int32_t i;
	for ( i = 0; i < docCount; i++ ) {
		modifier->deleteDocument(i);
	}
	return (int)docCount;
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
	doc->add(* new Field([kBRSearchFieldNameIdentifier asCLuceneString],
							[[self idValue:object] asCLuceneString],
							Field::STORE_YES | Field::INDEX_UNTOKENIZED,
							true));
	doc->add(* new Field([kBRSearchFieldNameObjectType asCLuceneString],
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
		id fieldValue = [fields objectForKey:fieldName];
		const int fieldFlags = (storeType | indexType);
		if ( [fieldValue isKindOfClass:[NSArray class]] || [fieldValue isKindOfClass:[NSSet class]] ) {
			for ( id oneValue in fieldValue ) {
				[self populateDocument:doc field:fieldName flags:fieldFlags value:oneValue];
			}
		} else {
			[self populateDocument:doc field:fieldName flags:fieldFlags value:fieldValue];
		}
	}
}

- (void)populateDocument:(Document *)doc field:(NSString *)fieldName flags:(int)flags value:(id)fieldValue {
	Field *f = new Field([fieldName asCLuceneString], flags);
	if ( [fieldValue isKindOfClass:[NSString class]] ) {
		NSData *fieldStringData = [fieldValue asCLuceneStringData];
		f->setValue((TCHAR *)[fieldStringData asCLuceneString], true);
	} else {
		NSAssert1(NO, @"Unsupported field value type: %@", NSStringFromClass([fieldValue class]));
	}
	doc->add(*f);
}


#pragma mark - Incremental index API

- (void)addObjectToIndex:(id<BRIndexable>)object queue:(dispatch_queue_t)queue finished:(BRSearchServiceCallbackBlock)finished {
	queue_retain(queue);
	[self addObjectsToIndex:(object == nil ? nil : @[object]) queue:queue finished:finished];
	queue_release(queue);
}

- (void)addObjectsToIndex:(NSArray *)objects queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceCallbackBlock)finished {
	if ( [objects count] < 1 ) {
		if ( finished != NULL ) {
			dispatch_queue_t callbackQueue = (finishedQueue != NULL
											  ? finishedQueue
											  : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
			dispatch_async(callbackQueue, ^{
				finished(nil);
			});
		}
		return;
	}
	[self bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
		for ( id<BRIndexable> obj in objects ) {
			[self addObjectToIndex:obj context:updateContext];
		}
	} queue:finishedQueue finished:^(int updateCount, NSError *error) {
		if ( finished != NULL ) {
			finished(error);
		}
	}];
}

- (void)addObjectToIndexAndWait:(id<BRIndexable>)object error:(NSError *__autoreleasing *)error {
	if ( object == nil ) {
		return;
	}
	[self addObjectsToIndexAndWait:@[object] error:error];
}

- (void)addObjectsToIndexAndWait:(NSArray *)objects error:(NSError *__autoreleasing *)error {
	if ( [objects count] < 1 ) {
		return;
	}
	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block BOOL finished = NO;
	[self addObjectsToIndex:objects queue:NULL finished:^(NSError *localError) {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
		if ( error != nil ) {
			*error = localError;
		}
	}];
	
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMaxWait]];
	//log4Debug(@"%@ %lu objects to index", (finished ? @"Added" : @"Failed to add"), (unsigned long)[objects count]);
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
		TermQuery *termQuery = new TermQuery(term);
		rootQuery->add(termQuery, true, BooleanClause::SHOULD); // rootQuery assumes ownership of TermQuery
		_CLLDECDELETE(term);
	}
	result.reset(rootQuery.release());
	return result;
}

- (void)removeObjectsFromIndexWithQuery:(std::auto_ptr<Query>)query queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceUpdateCallbackBlock)finishedBlock {
	Query *q = query.release();
	[self bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
		std::auto_ptr<Query> localQuery(q);
		[self removeObjectsFromIndexWithQuery:localQuery context:(CLuceneIndexUpdateContext *)updateContext];
	} queue:finishedQueue finished:finishedBlock];
}

- (void)removeObjectsFromIndex:(BRSearchObjectType)type withIdentifiers:(NSSet *)identifiers
						 queue:(dispatch_queue_t)queue finished:(BRSearchServiceUpdateCallbackBlock)finished {
	if ( [identifiers count] < 1 ) {
		if ( finished != NULL ) {
			dispatch_queue_t callbackQueue = (queue != NULL ? queue : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
			dispatch_async(callbackQueue, ^{
				finished(0, nil);
			});
		}
		return;
	}

	// search for all matching objects to delete
	std::auto_ptr<Query> query = [self queryForObjects:type withIdentifiers:identifiers];
	[self removeObjectsFromIndexWithQuery:query queue:queue finished:finished];
}

- (int)removeObjectsFromIndexAndWait:(BRSearchObjectType)type withIdentifiers:(NSSet *)identifiers error:(NSError *__autoreleasing *)error {
	if ( [identifiers count] < 1 ) {
		return 0;
	}
	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block int result = 0;
	__block BOOL finished = NO;
	[self removeObjectsFromIndex:type withIdentifiers:identifiers queue:NULL finished:^(int updateCount, NSError *localError) {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
		result = updateCount;
		if ( error != nil ) {
			*error = localError;
		}
	}];
	
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMaxWait]];
	[condition unlock];
	if ( [NSThread isMainThread] ) {
		[self resetSearcher];
	}
	return result;
}

- (void)removeObjectsFromIndexMatchingPredicate:(NSPredicate *)predicate
										  queue:(dispatch_queue_t)finishedQueue
									   finished:(BRSearchServiceUpdateCallbackBlock)finished {
	std::auto_ptr<Query> query = [self queryForPredicate:predicate analyzer:nil parent:nil];
	[self removeObjectsFromIndexWithQuery:query queue:finishedQueue finished:finished];
}

- (int)removeObjectsFromIndexMatchingPredicateAndWait:(NSPredicate *)predicate error:(NSError *__autoreleasing *)error {
	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block int result = 0;
	__block BOOL finished = NO;
	[self removeObjectsFromIndexMatchingPredicate:predicate queue:NULL finished:^(int updateCount, NSError *localError) {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
		result = updateCount;
		if ( error != nil ) {
			*error = localError;
		}
	}];
	
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:kMaxWait]];
	[condition unlock];
	if ( [NSThread isMainThread] ) {
		[self resetSearcher];
	}
	return result;
}

#pragma mark - Search API

- (id<BRSearchResults>)search:(NSString *)query {
	if ( [query length] < 1 ) {
		return nil;
	}
	std::auto_ptr<BooleanQuery> rootQuery(new BooleanQuery(false));
	QueryParser parser([kBRSearchFieldNameValue asCLuceneString], [self defaultAnalyzer]);
	for ( NSString *fieldName in generalTextFields ) {
		try {
			Query *q = parser.parse([query asCLuceneString], [fieldName asCLuceneString], [self defaultAnalyzer]);
			rootQuery.get()->add(q, true, BooleanClause::SHOULD);
		} catch ( CLuceneError &ex ) {
			NSLog(@"Error %d parsing query [%@]: %@", ex.number(), query, [NSString stringWithCLuceneString:ex.twhat()]);
		}
	}
	std::auto_ptr<Hits> hits([self searcher]->search(rootQuery.get()));
	std::auto_ptr<Sort> sort;
	std::auto_ptr<Query> resultQuery(rootQuery);
	return [[CLuceneSearchResults alloc] initWithHits:hits sort:sort query:resultQuery searcher:[self searcher]];
}

- (id<BRSearchResult>)findObject:(BRSearchObjectType)type withIdentifier:(NSString *)identifier {
	NSString *idValue = [self idValueForType:type identifier:identifier];
	Term *idTerm = new Term([kBRSearchFieldNameIdentifier asCLuceneString], [idValue asCLuceneString]);
	std::auto_ptr<TermQuery> idQuery(new TermQuery(idTerm));
	std::auto_ptr<Hits> hits([self searcher]->search(idQuery.get()));
	CLuceneSearchResult *result = nil;
	if ( hits->length() > 0 ) {
		// return first match, taking owning the Hits pointer
		result = [[[CLuceneSearchResult searchResultClassForDocument:hits->doc(0)] alloc] initWithOwnedHits:hits index:0];
	}
	_CLLDECDELETE(idTerm);
	return result;
}

- (id<BRSearchResults>)searchWithQuery:(std::auto_ptr<Query>)query
							  sortBy:(NSString *)sortFieldName
							sortType:(BRSearchSortType)sortType
						   ascending:(BOOL)ascending {
	std::tr1::shared_ptr<Searcher> s = [self searcher];
	if ( sortFieldName != nil ) {
		SortField *sortField = new SortField([sortFieldName asCLuceneString], (sortType == BRSearchSortTypeInteger
															  ? SortField::INT
															  : SortField::STRING), !ascending);
		
		// this ensures we have consistent results of sortField has duplicate values
		SortField *docField = (ascending ? SortField::FIELD_DOC() : new SortField(NULL, SortField::DOC, true));
		SortField *fields[] = {sortField, docField, NULL}; // requires NULL last element
		std::auto_ptr<Sort> sort(new Sort(fields)); // assumes ownership of fields
		std::auto_ptr<Hits> hits(s->search(query.get(), sort.get()));
		return [[CLuceneSearchResults alloc] initWithHits:hits sort:sort query:query searcher:s];
	}
	std::auto_ptr<Hits> hits(s->search(query.get()));
	std::auto_ptr<Sort> sort;
	return [[CLuceneSearchResults alloc] initWithHits:hits sort:sort query:query searcher:s];
}

- (id<BRSearchResults>)search:(NSString *)query
					 sortBy:(NSString *)sortFieldName
				   sortType:(BRSearchSortType)sortType
				  ascending:(BOOL)ascending {
	if ( [query length] < 1 ) {
		return nil;
	}
	std::auto_ptr<Query> rootQuery(new BooleanQuery(false));
	QueryParser parser([kBRSearchFieldNameValue asCLuceneString], [self defaultAnalyzer]);
	for ( NSString *fieldName in generalTextFields ) {
		try {
			Query *q = parser.parse([query asCLuceneString], [fieldName asCLuceneString], [self defaultAnalyzer]);
			((BooleanQuery *)rootQuery.get())->add(q, true, BooleanClause::SHOULD);
		} catch ( CLuceneError &ex ) {
			NSLog(@"Error %d parsing query [%@]: %@", ex.number(), query, [NSString stringWithCLuceneString:ex.twhat()]);
		}
	}
	return [self searchWithQuery:rootQuery sortBy:sortFieldName sortType:sortType ascending:ascending];
}

#pragma mark - Predicate search API

- (std::auto_ptr<Query>)queryForPredicate:(NSPredicate *)predicate analyzer:(Analyzer *)theAnalyzer parent:(NSCompoundPredicate *)parent {
	std::auto_ptr<Query> result;
	if ( [predicate isKindOfClass:[NSComparisonPredicate class]] ) {
		NSComparisonPredicate *comparison = (NSComparisonPredicate *)predicate;
		NSExpression *lhs = [comparison leftExpression];
		NSAssert1([lhs expressionType] == NSKeyPathExpressionType, @"Unsupported LHS expression type %lu", (unsigned long)[lhs expressionType]);
		NSExpression *rhs = [comparison rightExpression];
		NSAssert1([rhs expressionType] == NSConstantValueExpressionType, @"Unsupported RHS expression type %lu", (unsigned long)[rhs expressionType]);
		switch ( [comparison predicateOperatorType] ) {
			case NSEqualToPredicateOperatorType:
			case NSNotEqualToPredicateOperatorType:
			{
				Term *term = new Term([[lhs keyPath] asCLuceneString], [rhs constantValueCLuceneString]);
				result.reset(new TermQuery(term));
				_CLLDECDELETE(term);
			}
				break;
				
			case NSLikePredicateOperatorType:
			case NSMatchesPredicateOperatorType:
			{
				if ( theAnalyzer == nil ) {
					theAnalyzer = [self defaultAnalyzer];
				}
				QueryParser parser([[lhs keyPath] asCLuceneString], theAnalyzer);
				try {
					Query *q = parser.parse([rhs constantValueCLuceneString], [[lhs keyPath] asCLuceneString], theAnalyzer);
					result.reset(q);
				} catch ( CLuceneError &ex ) {
					NSLog(@"Error %d parsing query [%@]: %@", ex.number(), [lhs keyPath], [NSString stringWithCLuceneString:ex.twhat()]);
				}
			}
				break;
				
			case NSBeginsWithPredicateOperatorType:
			{
				Term *term = new Term([[lhs keyPath] asCLuceneString], [rhs constantValueCLuceneString]);
				result.reset(new PrefixQuery(term));
				_CLLDECDELETE(term);
			}
				break;
				
			case NSLessThanPredicateOperatorType:
			case NSLessThanOrEqualToPredicateOperatorType:
			case NSGreaterThanPredicateOperatorType:
			case NSGreaterThanOrEqualToPredicateOperatorType:
			{
				// if we are part of a parent with 2 children, and we are the 2nd child, and the 1st child is for the same constant expression,
				// then form a closed range query;
				const bool lessExpression = ([comparison predicateOperatorType] == NSLessThanPredicateOperatorType
											 || [comparison predicateOperatorType] == NSLessThanOrEqualToPredicateOperatorType);
				NSExpression *lowerExpression = nil;
				bool lowerInclusive = false;
				NSExpression *upperExpression = nil;
				bool upperInclusive = false;
				
				if ( parent != nil && [[parent subpredicates] count] > 1 ) {
					NSPredicate *closingRangePredicate = nil;
					NSUInteger myPosition = [[parent subpredicates] indexOfObjectIdenticalTo:predicate];
					bool firstPredicate = false;
					if ( myPosition == 0 ) {
						firstPredicate = true;
						closingRangePredicate = [parent subpredicates][1];
					} else if ( myPosition + 1 == [[parent subpredicates] count] ) {
						closingRangePredicate = [parent subpredicates][myPosition - 1];
					} else {
						// in the middle, so try previous predicate first
						NSPredicate *otherPredicate = [parent subpredicates][myPosition - 1];
						if ( [otherPredicate isKindOfClass:[NSComparisonPredicate class]]
							&& [[[(NSComparisonPredicate *)otherPredicate leftExpression] keyPath] isEqualToString:[lhs keyPath]] ) {
							// use previous
							closingRangePredicate = otherPredicate;
						} else {
							// try following predicate
							otherPredicate = [parent subpredicates][myPosition + 1];
							firstPredicate = false;
							if ( [otherPredicate isKindOfClass:[NSComparisonPredicate class]]
								&& [[[(NSComparisonPredicate *)otherPredicate leftExpression] keyPath] isEqualToString:[lhs keyPath]] ) {
								// use following
								closingRangePredicate = otherPredicate;
							}
						}
					}
					if ( [closingRangePredicate isKindOfClass:[NSComparisonPredicate class]] ) {
						NSComparisonPredicate *closingRangeComparison = (NSComparisonPredicate *)closingRangePredicate;
						NSExpression *closingRangeLhs = [closingRangeComparison leftExpression];
						NSAssert1([closingRangeLhs expressionType] == NSKeyPathExpressionType, @"Unsupported LHS expression type %lu", (unsigned long)[closingRangeLhs expressionType]);
						if ( [[closingRangeLhs keyPath] isEqualToString:[lhs keyPath]] ) {
							if ( lessExpression && ([closingRangeComparison predicateOperatorType] == NSGreaterThanPredicateOperatorType
												   || [closingRangeComparison predicateOperatorType] == NSGreaterThanOrEqualToPredicateOperatorType) ) {
								if ( firstPredicate ) {
									return result;
								}
								lowerExpression = [closingRangeComparison rightExpression];
								lowerInclusive = ([closingRangeComparison predicateOperatorType] == NSGreaterThanOrEqualToPredicateOperatorType);
								NSAssert1([lowerExpression expressionType] == NSConstantValueExpressionType, @"Unsupported RHS expression type %lu", (unsigned long)[lowerExpression expressionType]);
							} else if ( !lessExpression && ([closingRangeComparison predicateOperatorType] == NSLessThanPredicateOperatorType
															|| [closingRangeComparison predicateOperatorType] == NSLessThanOrEqualToPredicateOperatorType) ) {
								if ( firstPredicate ) {
									return result;
								}
								upperExpression = [closingRangeComparison rightExpression];
								upperInclusive = ([closingRangeComparison predicateOperatorType] == NSLessThanOrEqualToPredicateOperatorType);
								NSAssert1([upperExpression expressionType] == NSConstantValueExpressionType, @"Unsupported RHS expression type %lu", (unsigned long)[upperExpression expressionType]);
							}
						}
					}
				}
				if ( lessExpression )  {
					upperExpression = rhs;
					upperInclusive = ([comparison predicateOperatorType] == NSLessThanOrEqualToPredicateOperatorType);
				} else {
					lowerExpression = rhs;
					lowerInclusive = ([comparison predicateOperatorType] == NSGreaterThanOrEqualToPredicateOperatorType);
				}
				result.reset(new ConstantScoreRangeQuery([[lhs keyPath] asCLuceneString],
														 [lowerExpression constantValueCLuceneString], [upperExpression constantValueCLuceneString],
														 lowerInclusive, upperInclusive));
			}
				break;
				
			default:
				NSAssert1(NO, @"Unsupported predicate operator type: %lu", (unsigned long)[comparison predicateOperatorType]);
				break;
		}
		
	} else if ( [predicate isKindOfClass:[NSCompoundPredicate class]] ) {
		NSCompoundPredicate *compound = (NSCompoundPredicate *)predicate;
		NSMutableArray *subpredicates = [[NSMutableArray alloc] initWithCapacity:[[compound subpredicates] count]];
		
		// special case for AND (NOT (...)), which we don't want to end up as a MUST (MUST NOT (...)) BooleanQuery
		// because that will never match anything
		NSMutableArray *childNotCompoundPredicates = nil;
		for ( NSPredicate *subpredicate in [compound subpredicates] ) {
			if ( [subpredicate isKindOfClass:[NSCompoundPredicate class]] && [(NSCompoundPredicate *)subpredicate compoundPredicateType] == NSNotPredicateType ) {
				if ( childNotCompoundPredicates == nil ) {
					childNotCompoundPredicates = [NSMutableArray arrayWithCapacity:[[compound subpredicates] count]];
				}
				[childNotCompoundPredicates addObject:subpredicate];
			} else {
				[subpredicates addObject:subpredicate];
			}
		}
		
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
		
		for ( NSPredicate *subpredicate in subpredicates ) {
			std::auto_ptr<Query> subQuery = [self queryForPredicate:subpredicate analyzer:theAnalyzer parent:compound];
			// subQuery might be NULL (in case of range query)
			if ( subQuery.get() != NULL ) {
				
				// check for !=
				if ( [subpredicate isKindOfClass:[NSComparisonPredicate class]]
					&& [(NSComparisonPredicate *)subpredicate predicateOperatorType] == NSNotEqualToPredicateOperatorType ) {
					occur = BooleanClause::MUST_NOT;
				}
				
				boolean->add(subQuery.get(), true, occur); // transfer ownership of subQuery to boolean
				subQuery.release();
			}
		}
		if ( [childNotCompoundPredicates count] > 0 ) {
			occur = BooleanClause::MUST_NOT;
			for ( NSCompoundPredicate *subNot in childNotCompoundPredicates ) {
				for ( NSPredicate *subpredicate in [subNot subpredicates] ) {
					std::auto_ptr<Query> subQuery = [self queryForPredicate:subpredicate analyzer:theAnalyzer parent:compound];
					// subQuery might be NULL (in case of range query)
					if ( subQuery.get() != NULL ) {
						// check for !=
						if ( [subpredicate isKindOfClass:[NSComparisonPredicate class]]
							&& [(NSComparisonPredicate *)subpredicate predicateOperatorType] == NSNotEqualToPredicateOperatorType ) {
							occur = BooleanClause::MUST_NOT;
						}
						
						boolean->add(subQuery.get(), true, occur); // transfer ownership of subQuery to boolean
						subQuery.release();
					}
				}
			}
		}
		result.reset(boolean);
	}
	return result;
}

- (id<BRSearchResults>)searchWithPredicate:(NSPredicate *)predicate
									sortBy:(NSString *)sortFieldName
								  sortType:(BRSearchSortType)sortType
								 ascending:(BOOL)ascending {
	std::auto_ptr<Query> query = [self queryForPredicate:predicate analyzer:[self defaultAnalyzer] parent:nil];
	return [self searchWithQuery:query sortBy:sortFieldName sortType:sortType ascending:ascending];
}

@end
