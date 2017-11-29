/*
 * Copyright (c) 2008-2011 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of any contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
#import <ObjFW/ObjFW.h>
#import "PLSqliteStatementCache.h"
#import "OFValue.h"

#ifndef PLLog
#define PLLog(...) of_log(__VA_ARGS__)
#endif


@interface PLSqliteStatementCache (PrivateMethods)
- (void) removeAllStatementsHasLock: (BOOL) locked;
@end

/**
 * @internal
 *
 * Manages a cache of sqlite3_stmt instances, providing a mapping from query string to a sqlite3_stmt.
 *
 * The implementation naively evicts all statements should the cache become full. Future enhancement
 * may include implementing an LRU strategy, but it's not expected that many users will be executing
 * more unique queries than will fit in a reasonably sized cache.
 *
 * @par Thread Safety
 *
 * Unlike most classes in this library, PLSqliteStatementCache is thread-safe; this is intended to allow the safe
 * finalization/deallocation of SQLite ojects from multiple threads.
 *
 * Note, however, that the implementation is optimized for minimal contention.
 */
@implementation PLSqliteStatementCache

/**
 * Initialize the cache with the provided query @a capacity. The cache will discard sqlite3_stmt instances to stay
 * within the given capacity.
 *
 * @param capacity Maximum cache capacity.
 */
- (id) initWithCapacity: (size_t) capacity {
    self = [super init];
    
    _capacity = capacity;
    _availableStatements = [[OFMutableDictionary alloc] init];
    _allStatements = [[OFMutableSet alloc] init];
    
    if (!of_spinlock_new(&_lock)) {
        [self release];
        @throw [OFInitializationFailedException exceptionWithClass:[PLSqliteStatementCache class]];
    }

    return self;
}

- (void) dealloc {
    /* The sqlite statements have to be finalized explicitly */
    [self close];

    [_availableStatements release];

    if (_allStatements != nil) {
        [_allStatements release];
        _allStatements = nil;
    }

    of_spinlock_free(&_lock);

    [super dealloc];
}

/**
 * Register a sqlite3 prepared statement for the given @a query. This is used to support properly ordered finalization
 * of both sqlite3_stmt references and the backing sqlite3 database; all statements that will be checked out
 * via checkoutStatementForQueryString: must be registered apriori.
 *
 * @param stmt The statement to register.
 *
 */
- (void) registerStatement: (sqlite3_stmt *) stmt {
    of_spinlock_lock(&_lock); {
        [_allStatements addObject:[OFValue valueWithPointer:stmt]];
    }; of_spinlock_unlock(&_lock);
}

/**
 * Check in an sqlite3 prepared statement for the given @a query, making it available for re-use from the cache.
 * The statement will be reset (via sqlite3_reset()).
 *
 * @param stmt The statement to check in.
 * @param query The query string corresponding to this statement.
 *
 * @warning MEMORY OWNERSHIP WARNING: The receiver will claim ownership of the statement object.
 */
- (void) checkinStatement: (sqlite3_stmt *) stmt forQuery: (OFString *) query {
    of_spinlock_lock(&_lock); {
        OFValue *stmtVal = [OFValue valueWithPointer:stmt];
        /* If the statement pointer is not currently registered, there's nothing to do here. This should never occur. */
        if (![_allStatements containsObject: stmtVal]) {
            // TODO - Should this be an assert()?
            PLLog(@"[PLSqliteStatementCache]: Received an unknown statement %p during check-in.", stmt);
            of_spinlock_unlock(&_lock);
            return;
        }

        /* Bump the count */
        _size++;
        if (_size > _capacity) {
            [self removeAllStatementsHasLock: YES];
        }

        /* Fetch the statement set for this query */
        OFMutableArray* stmtArray = [_availableStatements objectForKey: query];
        if (stmtArray == nil) {
            stmtArray = [OFMutableArray array];
            [_availableStatements setObject: stmtArray forKey: query];
        }

        /* Claim ownership of the statement */
        sqlite3_reset(stmt);
        [stmtArray addObject:stmtVal];
    }; of_spinlock_unlock(&_lock);
}

/**
 * Check out a sqlite3 prepared statement for the given @a query, or NULL if none is cached.
 *
 * @param query The query string corresponding to this statement.
 *
 * @warning MEMORY OWNERSHIP WARNING: The caller is given ownership of the statement object, and MUST either deallocate
 * that object or provide it to PLSqliteStatementCache::checkinStatement:forQuery: for reclaimation.
 */
- (sqlite3_stmt *) checkoutStatementForQueryString: (OFString *) query {
    sqlite3_stmt *stmt;

    of_spinlock_lock(&_lock); {
        /* Fetch the statement set for this query */
        OFMutableArray* stmtArray = [_availableStatements objectForKey: query];
        if (stmtArray == nil || [stmtArray count] == 0) {
            of_spinlock_unlock(&_lock);
            return NULL;
        }

        /* Pop the statement from the array */
        stmt = (sqlite3_stmt *) [[stmtArray objectAtIndex:0] pointerValue];
        [stmtArray removeObjectAtIndex:0];

        /* Decrement the count */
        _size--;
    }; of_spinlock_unlock(&_lock);

    return stmt;
}

/**
 * Remove all unused statements from the cache. This will not invalidate active, in-use statements.
 */
- (void) removeAllStatements {
    [self removeAllStatementsHasLock: NO];
}

/**
 * Close the cache, invalidating <em>all</em> registered statements from the cache.
 *
 * @warning This will remove statements that may be in active use by PLSqlitePreparedStatement instances, and must
 * only be called by the PLSqliteDatabase prior to finalization.
 */
- (void) close {
    of_spinlock_lock(&_lock); {

        /* Finalize all registered statements */
        if (_allStatements != nil) {
            for (OFValue* stmt in [_allStatements allObjects]) {
                sqlite3_finalize((sqlite3_stmt *)[stmt pointerValue]);
                [_allStatements removeObject:stmt];
            }
        }

        /* Empty the statement cache of the now invalid references. */
        //[_availableStatements removeAllObjects];
    } of_spinlock_unlock(&_lock);
}

@end

@implementation PLSqliteStatementCache (PrivateMethods)

/**
 * Remove all unused statements from the cache. This will not invalidate active, in-use statements.
 *
 * @param locked If NO, the implementation will acquire a lock on _lock; otherwise,
 * it is assumed that _lock is already held.
 */
- (void) removeAllStatementsHasLock: (BOOL) locked {
    if (!locked)
        of_spinlock_lock(&_lock);
    
    /* Iterate over all cached queries and finalize their sqlite statements */
    [_availableStatements enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, bool *stop) {
        OFMutableArray* array = obj;
        for (OFValue* stmt in array) {
            sqlite3_finalize((sqlite3_stmt *)[stmt pointerValue]);
            [_allStatements removeObject:stmt];
        }
    }];
    
    /* Empty the statement cache of the now invalid references. */
    //[_availableStatements removeAllObjects];

    if (!locked)
        of_spinlock_unlock(&_lock);
}

@end
