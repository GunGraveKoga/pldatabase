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
#import "PLSqliteMigrationManager.h"
#include <assert.h>


@implementation PLSqliteMigrationVersionManager
@end

@implementation PLSqliteMigrationManager

// from PLDatabaseMigrationVersionManager protocol
- (BOOL) beginExclusiveTransactionForDatabase: (id<PLDatabase>) database error: (id *) outError {
    return [database executeUpdateAndReturnError: outError statement: @"BEGIN EXCLUSIVE TRANSACTION"];
}


// from PLDatabaseMigrationVersionManager protocol
- (BOOL) rollbackTransactionForDatabase: (id<PLDatabase>) database error: (id *) outError {
    return [database rollbackTransactionAndReturnError: outError];
}


// from PLDatabaseMigrationVersionManager protocol
- (BOOL) commitTransactionForDatabase: (id<PLDatabase>) database error: (id *) outError {
    return [database commitTransactionAndReturnError: outError];
}


// from PLDatabaseMigrationVersionManager protocol
- (BOOL) version: (int *) version forDatabase: (id<PLDatabase>) database error: (id *) outError {
    id<PLResultSet> rs;
    
    assert(version != NULL);
    
    /* Execute the query */
    rs = [database executeQueryAndReturnError: outError statement: @"PRAGMA user_version"];
    if (rs == nil)
        return NO;
    
    /* Get the version */
    BOOL hasNext = [rs nextAndReturnError:NULL];
    assert(hasNext == YES); // Should not happen
    *version = [rs intForColumn: @"user_version"];
    [rs close];
    
    return YES;
}


// from PLDatabaseMigrationVersionManager protocol
- (BOOL) setVersion: (int) version forDatabase: (id<PLDatabase>) database error: (id *) outError {    
    /* NOTE! We use stringWithFormat because:
     *   A) It's safe (only inserting an integer)
     *   B) Pragma doesn't seem to work with prepared statements.
     *
     * This is not a pattern to follow -- ALWAYS use prepared statements and
     * save yourself from being the 5 billionth person to create a SQL injection
     * attack vector.
     */
    return [database executeUpdateAndReturnError: outError statement: [OFString stringWithFormat: @"PRAGMA user_version = %d", version]];
}

@end
