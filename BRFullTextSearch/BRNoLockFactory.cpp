//
//  BRNoLockFactory.cpp
//  BRFullTextSearch
//
//  This is a replacement for lucene::store::NoLockFactory, which causes a crash because
//  its singleton lock is deleted by IndexWriter.close(). To fix that, we don't use a
//  singleton lock in this implementation.
//
//  Created by Matt on 7/3/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#include "CLucene/_ApiHeader.h"
#include "BRNoLockFactory.h"
#include "_Lock.h"
#include "CLucene/util/Misc.h"

CL_NS_DEF(store)

BRNoLockFactory* BRNoLockFactory::singleton = NULL;

void BRNoLockFactory::_shutdown(){
	_CLDELETE(BRNoLockFactory::singleton);
}

BRNoLockFactory* BRNoLockFactory::getNoLockFactory()
{
	if ( singleton == NULL ) {
		singleton = _CLNEW BRNoLockFactory();
	}
	return singleton;
}

lucene::store::LuceneLock* BRNoLockFactory::makeLock( const char* /*lockName*/ )
{
	// always return new lock instance, because IndexWriter.close() assumes ownership and deletes this instance!
	return _CLNEW lucene::store::NoLock();
}

void BRNoLockFactory::clearLock( const char* /*lockName*/ )
{
}

CL_NS_END
