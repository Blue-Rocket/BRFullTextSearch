//
//  BRFullTextSearch.h
//  BRFullTextSearch
//
//  Created by Matt on 7/3/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#ifndef BRFullTextSearch_BRFullTextSearch_h
#define BRFullTextSearch_BRFullTextSearch_h

#include <BRFullTextSearch/CLucene/StdHeader.h>
#include <BRFullTextSearch/CLucene/index/IndexReader.h>
#include <BRFullTextSearch/CLucene/index/IndexWriter.h>
#include <BRFullTextSearch/CLucene/index/MultiReader.h>
#include <BRFullTextSearch/CLucene/index/Term.h>
#include <BRFullTextSearch/CLucene/search/IndexSearcher.h>
#include <BRFullTextSearch/CLucene/search/MultiSearcher.h>
#include <BRFullTextSearch/CLucene/search/DateFilter.h>
#include <BRFullTextSearch/CLucene/search/WildcardQuery.h>
#include <BRFullTextSearch/CLucene/search/FuzzyQuery.h>
#include <BRFullTextSearch/CLucene/search/PhraseQuery.h>
#include <BRFullTextSearch/CLucene/search/PrefixQuery.h>
#include <BRFullTextSearch/CLucene/search/RangeQuery.h>
#include <BRFullTextSearch/CLucene/search/BooleanQuery.h>
#include <BRFullTextSearch/CLucene/search/TermQuery.h>
#include <BRFullTextSearch/CLucene/search/SearchHeader.h>
#include <BRFullTextSearch/CLucene/search/Similarity.h>
#include <BRFullTextSearch/CLucene/search/Sort.h>
#include <BRFullTextSearch/CLucene/search/Hits.h>
#include <BRFullTextSearch/CLucene/search/Explanation.h>
#include <BRFullTextSearch/CLucene/document/Document.h>
#include <BRFullTextSearch/CLucene/document/Field.h>
#include <BRFullTextSearch/CLucene/document/DateField.h>
#include <BRFullTextSearch/CLucene/document/DateTools.h>
#include <BRFullTextSearch/CLucene/document/NumberTools.h>
#include <BRFullTextSearch/CLucene/store/Directory.h>
#include <BRFullTextSearch/CLucene/store/FSDirectory.h>
#include <BRFullTextSearch/CLucene/store/RAMDirectory.h>
#include <BRFullTextSearch/CLucene/queryParser/QueryParser.h>
#include <BRFullTextSearch/CLucene/analysis/standard/StandardAnalyzer.h>
#include <BRFullTextSearch/CLucene/analysis/Analyzers.h>
#include <BRFullTextSearch/CLucene/util/BitSet.h>
#include <BRFullTextSearch/CLucene/util/CLStreams.h>
#include <BRFullTextSearch/CLucene/util/PriorityQueue.h>

// the following are not in the standard CLucene.h file
#include <BRFullTextSearch/CLucene/index/IndexModifier.h>
#include <BRFullTextSearch/BRNoLockFactory.h>
#include <BRFullTextSearch/BRSnowballAnalyzer.h>

#endif
