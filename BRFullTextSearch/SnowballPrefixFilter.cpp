//
//  SnowballPrefixFilter.cpp
//  BRFullTextSearch
//
//  Created by Matt on 4/9/15.
//  Copyright (c) 2015 Blue Rocket. All rights reserved.
//

#include "CLucene/_ApiHeader.h"
#include "SnowballPrefixFilter.h"

#include "CLucene/util/StringBuffer.h"
#include "CLucene/util/Misc.h"

namespace bluerocket{ namespace lucene{ namespace analysis {

	SnowballPrefixFilter::SnowballPrefixFilter(TokenStream *in, bool deleteTokenStream, const TCHAR* language) :
	TokenFilter(in, deleteTokenStream), stemmingFilter(_CLNEW SnowballFilter(this, language, false)) {
		unstemmedTerm[0] = '\0';
	}
	
	SnowballPrefixFilter::~SnowballPrefixFilter() {
		if ( stemmingFilter != NULL ) {
			_CLDELETE(stemmingFilter);
		}
	}
	
	Token* SnowballPrefixFilter::next(Token* token) {
		if ( unstemmedTerm[0] != '\0' ) {
			if ( !stemming ) {
				token->set(unstemmedTerm, token->startOffset(), token->endOffset(), token->type());
				token->setPositionIncrement(0);
				unstemmedTerm[0] = '\0'; // clear original
			}
			return token;
		} else if ( input->next(token) != NULL ) {
			// capture our un-stemmed token value to see if it changes when stemmed...
			TCHAR *term = token->termBuffer();
			size_t termLen = token->termLength();
			_tcsncpy(unstemmedTerm, term, termLen);
			unstemmedTerm[termLen] = '\0';
			
			// now run the stemming filter
			stemming = true;
			if ( stemmingFilter->next(token) ) {
				stemming = false;
				if ( _tcscmp(unstemmedTerm, token->termBuffer()) == 0 ) {
					// original and stemmed values are the same, clear original value
					unstemmedTerm[0] = '\0';
				}
				// return stemmed value
				return token;
			}
		}
		
		return NULL;
	}

} } } // namespace
