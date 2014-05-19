//
//  BRNoLockFactory.h
//  BRFullTextSearch
//
//  Created by Matt on 7/3/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#ifndef __BRCLucene__BRNoLockFactory__
#define __BRCLucene__BRNoLockFactory__

#include "CLucene/store/LockFactory.h"

CL_NS_DEF(store)

/**
 * A replacement for `lucene::store::NoLockFactory`, which causes a crash because
 * its singleton lock is deleted by `IndexWriter.close()`. To fix that, we don't use a
 * singleton lock in this implementation.
 */
class CLUCENE_EXPORT BRNoLockFactory : public lucene::store::LockFactory {
public:
	static BRNoLockFactory* singleton;
	static BRNoLockFactory* getNoLockFactory();
	static CLUCENE_LOCAL void _shutdown();

	lucene::store::LuceneLock* makeLock( const char* lockName );
	void clearLock( const char* lockName );
};

CL_NS_END

#endif /* defined(__BRCLucene__BRNoLockFactory__) */
