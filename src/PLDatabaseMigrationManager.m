/*
 * Copyright (c) 2008 Plausible Labs Cooperative, Inc.
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
#import "PLDatabaseMigrationManager.h"
#include <assert.h>

/**
 *
 * The PLDatabaseMigrationManager implements transactional, versioned migration/initialization of
 * database schema and data.
 *
 * Arbitrary migrations may be supplied via a PLDatabaseMigrationDelegate. The database versioning
 * meta-data is maintained by a supplied PLDatabaseMigrationVersionManager. This class makes no
 * assumptions about the migrations applied or the methods used to retrieve or update
 * database schema versions.
 *
 *
 * @par Thread Safety
 * Thread-safe. May be used from any thread.
 */
@implementation PLDatabaseMigrationManager

/**
 * Initialize a new migration manager.
 *
 * @param lockManager An object implementing the PLDatabaseMigrationTransactionManager protocol.
 * @param versionManager An object implementing the PLDatabaseMigrationVersionManager protocol.
 * @param delegate An object implementing the formal PLDatabaseMigrationDelegate protocol.
 */
- (id) initWithTransactionManager: (id<PLDatabaseMigrationTransactionManager>) lockManager
                   versionManager: (id<PLDatabaseMigrationVersionManager>) versionManager
                         delegate: (id<PLDatabaseMigrationDelegate>) delegate;
{
    assert(delegate != nil);
    assert(lockManager != nil);
    assert(versionManager != nil);
    
    self = [super init];
    
    /* Save the delegates/providers */
    _delegate = delegate; // cyclic reference, can not retain
    _txManager = [lockManager retain];
    _versionManager = [versionManager retain];
    
    return self;
}

/**
 * @deprecated Replaced by PLDatabaseMigrationManager::initWithTransactionManager:versionManager:delegate:
 */
- (id) initWithConnectionProvider: (id<PLDatabaseConnectionProvider>) connectionProvider
               transactionManager: (id<PLDatabaseMigrationTransactionManager>) lockManager
                   versionManager: (id<PLDatabaseMigrationVersionManager>) versionManager
                         delegate: (id<PLDatabaseMigrationDelegate>) delegate;
{
    if ((self = [self initWithTransactionManager: lockManager versionManager: versionManager delegate: delegate]) == nil)
        return nil;

    /* Save the connection provider */
    _connectionProvider = [connectionProvider retain];

    return self;
}


- (void) dealloc {
    [_connectionProvider release];
    [_txManager release];
    [_versionManager release];

    [super dealloc];
}

/**
 * Perform any pending migrations on @a database using the receiver's PLDatabaseMigrationDelegate.
 *
 * @param db The database connection upon which migrations will be performed.
 * @param outError A pointer to an NSError object variable. If an error occurs, this
 * pointer will contain an error object indicating why the migration could not be completed.
 * If no error occurs, this parameter will be left unmodified. You may specify NULL for this
 * parameter, and no error information will be provided.
 * @return YES on successful migration, or NO if migration failed. If NO is returned, all modifications
 * will be rolled back.
 */
- (BOOL) migrateDatabase: (id<PLDatabase>) db error: (id *) outError {
    int currentVersion;
    int newVersion;

    /* Start a transaction, we'll do *all modifications* within this one transaction */
    if (![_txManager beginExclusiveTransactionForDatabase: db error: outError])
        return NO;
    
    /* Fetch the current version. We default the new version to the current version -- failure to do so
     * will result in the database version being reset should the delegate forget to set the version
     * on a migration returning YES but implementing no changes. */
    if (![_versionManager version: &currentVersion forDatabase: db error: outError])
        goto rollback;
    
    newVersion = currentVersion;
    
    /* Run the migration */
    if (![_delegate migrateDatabase: db currentVersion: currentVersion newVersion: &newVersion error: outError])
        goto rollback;
    
    if (![_versionManager setVersion: newVersion forDatabase: db error: outError])
        goto rollback;
    
    if (![_txManager commitTransactionForDatabase: db error: outError])
        goto rollback;

    /* Succeeded */
    return YES;
    
rollback:
    [_txManager rollbackTransactionForDatabase: db error: NULL];
    return NO;
}

/**
 * @deprecated Replaced by PLDatabaseMigrationManager::migrateDatabase:error:
 */
- (BOOL) migrateAndReturnError: (id *) outError {
    id<PLDatabase> db;
    
    /* Open the database connection */
    db = [_connectionProvider getConnectionAndReturnError: outError];
    if (db == nil) {
        return NO;
    }

    /* Attempt the migration */
    BOOL result = [self migrateDatabase: db error: outError];

    /* Return our connection to the provider */
    [_connectionProvider closeConnection: db];

    return result;
}

@end
