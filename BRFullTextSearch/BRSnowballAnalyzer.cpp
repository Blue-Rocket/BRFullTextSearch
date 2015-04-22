//
//  BRSnowballAnalyzer.cpp
//  BRFullTextSearch
//
//  Created by Matt on 7/3/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#include "CLucene/_ApiHeader.h"
#include "BRSnowballAnalyzer.h"
#include "SnowballPrefixFilter.h"
#include "CLucene/util/Misc.h"
#include "CLucene/util/CLStreams.h"
#include "CLucene/analysis/Analyzers.h"
#include "CLucene/analysis/standard/StandardTokenizer.h"
#include "CLucene/analysis/standard/StandardFilter.h"

CL_NS_USE(analysis)
CL_NS_USE(util)
CL_NS_USE2(analysis,standard)

CL_NS_DEF2(analysis,snowball)

class BRSnowballAnalyzer::SavedStreams : public TokenStream {
public:
	StandardTokenizer* tokenStream;
	TokenStream* filteredTokenStream;
	
	SavedStreams():tokenStream(NULL), filteredTokenStream(NULL)
	{
	}
	
	~SavedStreams() {
		if ( filteredTokenStream != NULL ) {
			_CLDELETE(filteredTokenStream);
			// that should also have deleted tokenStream
		}
	}
	
	void close(){}
	Token* next(Token* token) {return NULL;}
};

/** Builds the named analyzer with no stop words. */
BRSnowballAnalyzer::BRSnowballAnalyzer(const TCHAR* language) {
    this->language = STRDUP_TtoT(language);
	stopSet = NULL;
}

/** Builds the named analyzer with the given stop words. */
BRSnowballAnalyzer::BRSnowballAnalyzer(const TCHAR* language, const TCHAR** stopWords, bool prefixModeEnabled) {
	this->language = STRDUP_TtoT(language);
	
	stopSet = _CLNEW CLTCSetList(true);
	StopFilter::fillStopTable(stopSet,stopWords);
	prefixMode = prefixModeEnabled;
}

BRSnowballAnalyzer::~BRSnowballAnalyzer(){
	SavedStreams* t = reinterpret_cast<SavedStreams*>(this->getPreviousTokenStream());
	if (t) _CLDELETE(t->filteredTokenStream);
	_CLDELETE_CARRAY(language);
	if ( stopSet != NULL )
		_CLDELETE(stopSet);
}

TokenStream* BRSnowballAnalyzer::tokenStream(const TCHAR* fieldName, CL_NS(util)::Reader* reader) {
	return this->tokenStream(fieldName,reader,false);
}

/** Constructs a {@link StandardTokenizer} filtered by a {@link
 StandardFilter}, a {@link LowerCaseFilter} and a {@link StopFilter}. */
TokenStream* BRSnowballAnalyzer::tokenStream(const TCHAR* fieldName, CL_NS(util)::Reader* reader, bool deleteReader) {
	BufferedReader* bufferedReader = reader->__asBufferedReader();
	TokenStream* result;
	
	if ( bufferedReader == NULL )
		result =  _CLNEW StandardTokenizer( _CLNEW FilteredBufferedReader(reader, deleteReader), true );
	else
		result = _CLNEW StandardTokenizer(bufferedReader, deleteReader);
	
	result = _CLNEW StandardFilter(result, true);
    result = _CLNEW CL_NS(analysis)::LowerCaseFilter(result, true);
	if (stopSet != NULL) {
		result = _CLNEW CL_NS(analysis)::StopFilter(result, true, stopSet);
	}
	if ( !stemmingDisabled ) {
		if ( prefixMode ) {
			result = _CLNEW bluerocket::lucene::analysis::SnowballPrefixFilter(result, true, language);
		} else {
			result = _CLNEW SnowballFilter(result, language, true);
		}
	}
    return result;
}

TokenStream* BRSnowballAnalyzer::reusableTokenStream(const TCHAR* fieldName, Reader* reader){
	SavedStreams* streams = reinterpret_cast<SavedStreams*>(getPreviousTokenStream());
	if (streams == NULL) {
		streams = _CLNEW SavedStreams();
		setPreviousTokenStream(streams);
		
		BufferedReader* bufferedReader = reader->__asBufferedReader();
		if ( bufferedReader == NULL )
			streams->tokenStream = _CLNEW StandardTokenizer( _CLNEW FilteredBufferedReader(reader, false), true);
		else
			streams->tokenStream = _CLNEW StandardTokenizer(bufferedReader);
		
		streams->filteredTokenStream = _CLNEW StandardFilter(streams->tokenStream, true);
		streams->filteredTokenStream = _CLNEW LowerCaseFilter(streams->filteredTokenStream, true);
		streams->filteredTokenStream = _CLNEW StopFilter(streams->filteredTokenStream, true, stopSet);
		if ( !stemmingDisabled ) {
			if ( prefixMode ) {
				streams->filteredTokenStream = _CLNEW bluerocket::lucene::analysis::SnowballPrefixFilter(streams->filteredTokenStream, true, language);
			} else {
				streams->filteredTokenStream = _CLNEW SnowballFilter(streams->filteredTokenStream, language, true);
			}
		}
	} else {
		streams->tokenStream->reset(reader);
	}
	
	return streams->filteredTokenStream;
}

bool BRSnowballAnalyzer::getPrefixMode() {
	return prefixMode;
}

void BRSnowballAnalyzer::setPrefixMode(bool mode) {
	prefixMode = mode;
}

bool BRSnowballAnalyzer::getStemmingDisabled() {
	return stemmingDisabled;
}

void BRSnowballAnalyzer::setStemmingDisabled(bool disabled) {
	stemmingDisabled = disabled;
}

CL_NS_END2
