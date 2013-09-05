FullTextSearch
==============

iOS Objective-C full-text search engine.

This project provides a way to integrate full-text search capabilities
into your iOS project. First, it provides a protocol-based API for a 
simple text indexing and search framework. Second, it provides a 
[CLucene](http://clucene.sourceforge.net/) based implementation of that
framework.

Example Usage
-------------

The following snippet shows how the API works. The `CLuceneSearchService`
reference is the only CLucene-specific portion of the code:

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

Core Data integration
---------------------

It's pretty easy to integrate `BRFullTextSearch` with Core Data, to
maintain a search index while changes are persisted in Core Data. One
way is to listen for the `NSManagedObjectContextDidSaveNotification`
notification and process Core Data changes as index delete and update
operations. The **SampleCoreDataProject** project contains an example of
this integration. The app allows you to create small _sticky notes_ and
search the text of those notes. See the
[CoreDataManager](https://github.com/Blue-Rocket/BRFullTextSearch/blob/master/SampleCoreDataProject/SampleCoreDataProject/CoreDataManager.m)
class in the sample project, whose
`maintainSearchIndexFromManagedObjectDidSave:` method handles this.

Project Setup
-------------

After cloning the BRFullTextSearch repository, you must initialize git submodules.
For example:

	git clone git@github.com:Blue-Rocket/BRFullTextSearch.git
	cd BRFullTextSearch
	git submodule update --init
	
This will pull in the relevant submodules, e.g. CLucene.

Static Framework Project Integration
------------------------------------

You can integrate BRFullTextSearch into your project in a couple of ways. First,
the BRFullTextSearch Xcode project includes a target called 
**BRFullTextSearch.framework** that builds a static library framework. Build 
that target, which will produce a `BRFullTextSearch.framework` bundle at 
the root project directory. Copy that framework into your project and add it
as a build dependency.

You must also add the following linker build dependencies, which you can do by
clicking the **+** button in the **Link Binary With Libraries** section of the 
**Build Phases** tab in the project settings:

 * libz
 * libstdc++

Next, add `-ObjC` as an *Other Linker Flags* build setting.

Finally, you'll need to add the path to the directory containing the 
`BRFullTextSearch.framework` bundle as a **Framework Search Paths** value
in the **Build Settings** tab of the project settings.

The **SampleStaticLibraryProject** included in this repository is an example
project set up using the static library framework integration approach. You
must build **BRFullTextSearch.framework** first, then open this project. When
you run the project, it will index a set of documents using some Latin text.
You can then search for latin words using a simple UI.

Dependent Project Integration
-----------------------------

The other way you can integrate BRFullTextSearch into your project is to add
the BRFullTextSearch Xcode project as a dependent project of your project. The 
BRFullTextSearch Xcode project includes a target called 
**BRFullTextSearch** that builds a static library. You can use that target as
a dependency in your own project.

To do this, drag the **BRFullTextSearch.xcodeproj** onto your project in the 
Project Navigator. Then go to the **Build Phases** tab of your project's 
settings. Expand the **Target Dependencies** section and click the **+** button.
You should see the **BRFullTextSearch** static library target as an available
option. Select that and click the **Add** button.

You must also add the following linker build dependencies, which you can do by
clicking the **+** button in the **Link Binary With Libraries** section of the 
**Build Phases** tab in the project settings:

 * libz
 * libstdc++

Next, add `-ObjC` as an *Other Linker Flags* build setting.

Finally, you'll need to add the path to the directory containing the 
*BRFullTextSearch.xcodeproj* file as a **Header Search Paths** value in 
the **Build Settings** tab of the project settings. If you have added 
BRFullTextSearch as a git submodule to your own project, then the path
might be something like **"$(PROJECT_DIR)/../BRFullTextSearch"**.
