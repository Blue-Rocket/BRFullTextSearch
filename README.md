FullTextSearch
==============

iOS Objective-C search engine.

This project provides a way to integrate full-text search capabilities
into your iOS project. First, it provides a protocol-based API for a 
simple search framework. Second, it provides a 
[CLucene](http://clucene.sourceforge.net/) based implementation of that
framework.

Example Usage
-------------

The following snippet shows how the API works. The `CLuceneSearchService`
reference is the only CLucene-specific portion of the code:

	id<BRSearchService> service = [[CLuceneSearchService alloc] initWithIndexPath:@"/some/path"];
	
	// add a document to the index
	id<BRIndexable> doc = [[BRSimpleIndexable alloc] initWithIdentifier:@"1" data:@{
						   kBRSearchFieldNameTitle : @"Special document",
						   kBRSearchFieldNameValue : @"This is a long winded note with really important details in it."
						   }];
	[service addObjectToIndexAndWait:doc];
	
	// search for documents and log contents of each result
	id<BRSearchResults> results = [service search:@"special"];
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		NSLog(@"Found result: %@", [result dictionaryRepresentation]);
	}];

Project Setup
-------------

After cloning the BRFulLTextSearch repository, you must initialize git submodules.
For example:

	git clone git@github.com:Blue-Rocket/BRFullTextSearch.git
	cd BRFullTextSearch
	git submodule update --init
	
This will pull in the relevant submodules, e.g. CLucene.

Project Integration
-------------------

You can integrate BRFullTextSearch into your project in a couple of ways. First,
the BRFullTextSearch Xcode project includes a target called 
**BRFullTextSearch.framework** that builds a static library framework. Build 
that target, which will produce a `BRFullTextSearch.framework` bundle at 
the root project directory. Copy that framework into your project and add it
as a build dependency. You must also add the following build dependencies:

 * libz
 * libdstc++

Finally, add `-ObjC` as an *Other Linker Flags* build setting.

The **SampleStaticLibraryProject** included in this repository is an example
project set up using the static library framework integration approach. You
must build **BRFullTextSearch.framework** first, then open this project. When
you run the project, it will index a set of documents using some Latin text.
You can then search for latin words using a simple UI.
