# BRFullTextSearch

Objective-C full text search engine.

This project provides a way to integrate full-text search capabilities into your iOS
or OS X project. First, it provides a protocol-based API for a simple text indexing
and search framework. Second, it provides a [CLucene](http://clucene.sourceforge.net/)
based implementation of that framework.

# Example Usage

The following snippet shows how the API works. The `CLuceneSearchService` reference
is the only CLucene-specific portion of the code:

```objc
id<BRSearchService> service = [[CLuceneSearchService alloc] initWithIndexPath:@"/some/path"];

// add a document to the index
id<BRIndexable> doc = [[BRSimpleIndexable alloc] initWithIdentifier:@"1" data:@{
					   kBRSearchFieldNameTitle : @"Special document",
					   kBRSearchFieldNameValue : @"This is a long winded note with really important details in it."
					   }];
NSError *error = nil;
[service addObjectToIndexAndWait:doc error:&error];

// search for documents and log contents of each result
id<BRSearchResults> results = [service search:@"special"];
[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
	NSLog(@"Found result: %@", [result dictionaryRepresentation]);
}];
```


# Sample projects

There are several sample projects included in the source distribution:

 * [SampleCocoaPodsProject](SampleCocoaPodsProject/) - a Core Data based iOS application using CocoaPods integration
 * [SampleCoreDataProject](SampleCoreDataProject/) - a Core Data based iOS application using dependent project integration
 * [SampleDependentProject](SampleDependentProject) - a basic iOS application using dependent project integration
 * [SampleOSXCocoaPodsProject](SampleOSXCocoaPodsProject/) - a Core Data based OS X application using CocoaPods integration
 * [SampleStaticLibraryProject](SampleStaticLibraryProject/) - a basic iOS application using static library integration

# Predicate queries

The `BRSearchService` API supports `NSPredicate` based queries:

```objc
- (id<BRSearchResults>)searchWithPredicate:(NSPredicate *)predicate
                                    sortBy:(NSString *)sortFieldName
                                  sortType:(BRSearchSortType)sortType
                                 ascending:(BOOL)ascending;
```

This method of querying can be quite useful when constructing a query out of user-supplied query text.
For example, you could support _prefix_ based queries (for example, searching for `ca*` to match `cat`):

```objc
// get query as string, from text field for Example
NSString * query = ...;

static NSExpression *ValueExpression;
if ( ValueExpression == nil ) {
    ValueExpression = [NSExpression expressionForKeyPath:kBRSearchFieldNameValue];
}
NSArray *tokens = [[query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                   componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:([tokens count] * 2)];
for ( NSString *token in tokens ) {
    [predicates addObject:[NSComparisonPredicate predicateWithLeftExpression:ValueExpression
                                                             rightExpression:[NSExpression expressionForConstantValue:token]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:NSLikePredicateOperatorType
                                                                     options:0]];
    [predicates addObject:[NSComparisonPredicate predicateWithLeftExpression:ValueExpression
                                                             rightExpression:[NSExpression expressionForConstantValue:token]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:NSBeginsWithPredicateOperatorType
                                                                     options:0]];
}
NSPredicate *predicateQuery = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
searchResults = [searchService searchWithPredicate:predicateQuery sortBy:nil sortType:0 ascending:NO];
```

# Batch API

When indexing many documents at once, `BRSearchService` provides a set of methods specifically designed
for efficient bulk operations:

```objc
// bulk block callback function.
typedef void (^BRSearchServiceIndexUpdateBlock)(id <BRIndexUpdateContext> updateContext);

// perform a bulk operation, calling the passed on block
- (void)bulkUpdateIndex:(BRSearchServiceIndexUpdateBlock)updateBlock
                  queue:(dispatch_queue_t)finishedQueue
               finished:(BRSearchServiceUpdateCallbackBlock)finished;

// from within the block, the following methods can be used (notice the updateContext parameter):

- (void)addObjectToIndex:(id <BRIndexable> )object context:(id <BRIndexUpdateContext> )updateContext;

- (int)removeObjectFromIndex:(BRSearchObjectType)type withIdentifier:(NSString *)identifier
                     context:(id <BRIndexUpdateContext> )updateContext;

- (int)removeObjectsFromIndexMatchingPredicate:(NSPredicate *)predicate
                                       context:(id <BRIndexUpdateContext> )updateContext;

- (int)removeAllObjectsFromIndex:(id <BRIndexUpdateContext> )updateContext;
```

Here's an example of a bulk operation that adds 100,000 documents to the index; notice the strategic
use of `@autoreleasepool` to keep a lid on memory use during the operation:

```objc
id<BRSearchService> service = ...;
[service bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {

    if ( [updateContext respondsToSelector:@selector(setOptimizeWhenDone:)] ) {
        updateContext.optimizeWhenDone = YES;
    }

    // add a bunch of documents to the index, in small autorelease batches
    for ( int i = 0; i < 100000; i+= 1000 ) {
        @autoreleasepool {
            for ( int j = 0; j < 1000; j++ ) {
                id<BRIndexable> doc = ...;
                [service addObjectToIndex:doc context:updateContext];
            }
        }
    }

} queue:dispatch_get_main_queue() finished:^(int updateCount, NSError *error) {
    // all finished here
}];
```

# Core Data support

It's pretty easy to integrate BRFullTextSearch with Core Data, to maintain a search
index while changes are persisted in Core Data. One way is to listen for the
`NSManagedObjectContextDidSaveNotification` notification and process Core Data
changes as index delete and update operations. The **SampleCoreDataProject** iOS project
contains an example of this integration. The app allows you to create small _sticky
notes_ and search the text of those notes. See the
[CoreDataManager](SampleCoreDataProject/SampleCoreDataProject/CoreDataManager.m) class in the sample
project, whose `maintainSearchIndexFromManagedObjectDidSave:` method handles this.

The **SampleOSXCocoaPodsProject** OS X project also contains an example of this integration.
See the [CoreDataManager](SampleOSXCocoaPodsProject/SampleOSXCocoaPodsProject/CoreDataManager.m)
class in that project for details.


# Project Integration

You can integrate BRFullTextSearch via [CocoaPods](http://cocoapods.org/), or
manually as either a dependent project or static framework.

## via CocoaPods

Install CocoaPods if not already available:

```bash
$ [sudo] gem install cocoapods
$ pod setup
```

Change to the directory of your Xcode project, and create a file named `Podfile` with
contents similar to this:

	platform :ios, '5.0'
	pod 'BRFullTextSearch', '~> 1.0'

Install into your project:

``` bash
$ pod install
```

Open your project in Xcode using the **.xcworkspace** file CocoaPods generated.

**Note:** the `use_frameworks!` option is not supported, see #4. Any pull requests
to allow for building as a dynamic framework are very welcome!

**Note:** CocoaPods as of version 0.39 might not produce a valid project for this pod.
You can work around it by running `pod` like this:

``` bash
$ COCOAPODS_DISABLE_DETERMINISTIC_UUIDS=YES pod install
```
or you can manually modify the target membership of any files that are the cause of linker
errors to be included in the `BRFullTextSearch` target in Xcode.

## via static framework

Using this approach you'll build a static library framework that you can manually
integrate into your own project. After cloning the BRFullTextSearch repository,
first initialize git submodules. For example:

	git clone https://github.com/Blue-Rocket/BRFullTextSearch.git
	cd BRFullTextSearch
	git submodule update --init

This will pull in the relevant submodules, e.g. CLucene.

The BRFullTextSearch Xcode project includes a target called
**BRFullTextSearch.framework** that builds a static library framework. Build that
target, which will produce a `Framework/Release/BRFullTextSearch.framework` bundle at
the root project directory. Copy that framework into your project and add it as a
build dependency.

You must also add the following linker build dependencies, which you can do by
clicking the **+** button in the **Link Binary With Libraries** section of the
**Build Phases** tab in the project settings:

 * libz
 * libstdc++

Next, add `-ObjC` as an *Other Linker Flags* build setting. If you do not have any
C++ sources in your project, you probably also need to add `-stdlib=libstdc++` to
this setting as well.

Finally, you'll need to add the path to the directory containing the
`BRFullTextSearch.framework` bundle as a **Framework Search Paths** value in the
**Build Settings** tab of the project settings.

The **SampleStaticLibraryProject** included in this repository is an example project
set up using the static library framework integration approach. You must build
**BRFullTextSearch.framework** first, then open this project. When you run the
project, it will index a set of documents using some Latin text. You can then search
for latin words using a simple UI.

## via dependent project

Another way you can integrate BRFullTextSearch into your project is to add the
BRFullTextSearch Xcode project as a dependent project of your project. The
BRFullTextSearch Xcode project includes a target called **BRFullTextSearch** that
builds a static library. You can use that target as a dependency in your own project.

After cloning the BRFullTextSearch repository, first initialize git submodules. For
example:

	git clone https://github.com/Blue-Rocket/BRFullTextSearch.git
	cd BRFullTextSearch
	git submodule update --init

This will pull in the relevant submodules, e.g. CLucene.

Then drag the **BRFullTextSearch.xcodeproj** onto your project in the Project
Navigator. Then go to the **Build Phases** tab of your project's settings. Expand the
**Target Dependencies** section and click the **+** button. You should see the
**BRFullTextSearch** static library target as an available option. Select that and
click the **Add** button.

You must also add the following linker build dependencies, which you can do by
clicking the **+** button in the **Link Binary With Libraries** section of the
**Build Phases** tab in the project settings:

 * libz
 * libstdc++

Next, add `-ObjC` as an *Other Linker Flags* build setting.

Finally, you'll need to add the path to the directory containing the
*BRFullTextSearch.xcodeproj* file as a **Header Search Paths** value in the **Build
Settings** tab of the project settings. If you have added BRFullTextSearch as a git
submodule to your own project, then the path might be something like
**"$(PROJECT_DIR)/../BRFullTextSearch"**.
