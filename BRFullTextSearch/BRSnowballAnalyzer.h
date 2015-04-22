//
//  BRSnowballAnalyzer.h
//  BRFullTextSearch
//
//  Created by Matt on 7/3/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#ifndef __BRFullTextSearch__BRSnowballAnalyzer__
#define __BRFullTextSearch__BRSnowballAnalyzer__

#include "CLucene/analysis/AnalysisHeader.h"

CL_CLASS_DEF(util,BufferedReader)
CL_NS_DEF2(analysis,snowball)

/** 
 * Filters {@link StandardTokenizer} with {@link StandardFilter}, {@link
 * LowerCaseFilter}, {@link StopFilter} and {@link SnowballFilter}.
 *
 * Available stemmers are listed in {@link net.sf.snowball.ext}.  The name of a
 * stemmer is the part of the class name before "Stemmer", e.g., the stemmer in
 * {@link EnglishStemmer} is named "English".
 */
class CLUCENE_CONTRIBS_EXPORT BRSnowballAnalyzer : public Analyzer {
	TCHAR* language;
	CLTCSetList* stopSet;
	bool prefixMode;
	bool stemmingDisabled = false;
	
	class SavedStreams;
	
public:
	/** Builds the named analyzer with no stop words and prefix mode disabled. */
	BRSnowballAnalyzer(const TCHAR* language=_T("english"));
	
	/** Builds the named analyzer with the given stop words. */
	BRSnowballAnalyzer(const TCHAR* language, const TCHAR** stopWords, bool prefixModeEnabled = false);
	
	~BRSnowballAnalyzer();
	
	
	bool getPrefixMode();
	void setPrefixMode(bool mode);

	bool getStemmingDisabled();
	void setStemmingDisabled(bool disabled);
	
	/** Constructs a {@link StandardTokenizer} filtered by a {@link
	 StandardFilter}, a {@link LowerCaseFilter} and a {@link StopFilter}. */
	TokenStream* tokenStream(const TCHAR* fieldName, CL_NS(util)::Reader* reader);
	TokenStream* tokenStream(const TCHAR* fieldName, CL_NS(util)::Reader* reader, bool deleteReader);
	TokenStream* reusableTokenStream(const TCHAR* fieldName, CL_NS(util)::Reader* reader);
};

CL_NS_END2

#endif /* defined(__BRFullTextSearch__BRSnowballAnalyzer__) */
