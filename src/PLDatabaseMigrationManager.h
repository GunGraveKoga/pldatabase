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


#import <ObjFW/OFObject.h>

#import "PLDatabaseConnectionProvider.h"

#import "PLDatabaseMigrationTransactionManager.h"
#import "PLDatabaseMigrationVersionManager.h"
#import "PLDatabaseMigrationDelegate.h"

OF_ASSUME_NONNULL_BEGIN

@protocol PLDatabaseMigrationDelegate;

@interface PLDatabaseMigrationManager : OFObject {
@private
    /** The connection provider. */
    id<PLDatabaseConnectionProvider> _connectionProvider;

    /** Lock manager used to start/commit transactions */
    id<PLDatabaseMigrationTransactionManager> _txManager;

    /** The version manager used to read/set the database version. */
    id<PLDatabaseMigrationVersionManager> _versionManager;

    /** The delegate used to perform migrations. */
    id<PLDatabaseMigrationDelegate> _delegate;
}

- (id) initWithTransactionManager: (id<PLDatabaseMigrationTransactionManager>) lockManager
                   versionManager: (id<PLDatabaseMigrationVersionManager>) versionManager
                         delegate: (id<PLDatabaseMigrationDelegate>) delegate;

- (BOOL) migrateDatabase: (id<PLDatabase>) database error: (id _Nullable * _Nullable) outError;

- (id) initWithConnectionProvider: (id<PLDatabaseConnectionProvider>) connectionProvider
               transactionManager: (id<PLDatabaseMigrationTransactionManager>) lockManager
                   versionManager: (id<PLDatabaseMigrationVersionManager>) versionManager
                         delegate: (id<PLDatabaseMigrationDelegate>) delegate __attribute__((deprecated("This method is deprecated!!! Replaced by PLDatabaseMigrationManager::initWithTransactionManager:versionManager:delegate:")));

- (BOOL) migrateAndReturnError: (id _Nullable * _Nullable) outError __attribute__((deprecated("This method is deprecated!!! Replaced by PLDatabaseMigrationManager::migrateDatabase:error:")));

@end

OF_ASSUME_NONNULL_END

