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
#import "PLSqliteResultSet.h"
#import "PLSqliteUnlockNotify.h"

#import "OFException+NSException.h"

/**
 * @internal
 *
 * SQLite #PLResultSet implementation.
 *
 * @par Thread Safety
 * PLSqliteResultSet instances implement no locking and must not be shared between threads
 * without external synchronization.
 */
 @implementation PLSqliteResultSet

/**
 * Initialize the ResultSet with an open database and an sqlite3 prepare statement.
 *
 * MEMORY OWNERSHIP WARNING:
 * We are passed an sqlite3_stmt reference owned by the PLSqlitePreparedStatement.
 * It will remain valid insofar as the PLSqlitePreparedStatement reference is retained.
 *
 * @par Designated Initializer
 * This method is the designated initializer for the PLSqliteResultSet class.
 */
- (instancetype) initWithPreparedStatement: (PLSqlitePreparedStatement *) stmt 
                  sqliteStatemet: (sqlite3_stmt *) sqlite_stmt
{
    self = [super init];
    
    /* Save our database and statement references. */
    _stmt = [stmt retain];
    _sqlite_stmt = sqlite_stmt;

    /* Save result information */
    _columnCount = sqlite3_column_count(_sqlite_stmt);
    
    return self;
}

- (void) dealloc {
    /* 'Check in' our prepared statement reference */
    [self close];

    /* Release the column cache. */
    if (_columnNames != nil)
        [_columnNames release];
    
    /* Release the statement. */
    [_stmt release];
    
    [super dealloc];
}

// property getter
- (BOOL) isClosed {
    if (_sqlite_stmt == NULL)
        return YES;

    return NO;
}

// From PLResultSet
- (void) close {
    if (_sqlite_stmt == NULL)
        return;

    /* Check ourselves back in and give up our statement reference */
    [_stmt checkinResultSet: self];
    _sqlite_stmt = NULL;
}

/**
 * @internal
 * Assert that the result set has not been closed
 */
- (void) assertNotClosed {
    if (_sqlite_stmt == NULL)
        [OFException raise:PLSqliteException format:@"Attempt to access already-closed result set."];
}

/* From PLResultSet */
- (BOOL) next {
    [self assertNotClosed];

    if ([self nextAndReturnError: NULL] == PLResultSetStatusRow)
        return YES;

    /* This depreciated API can not differentiate between an error or
     * the end of the result set. */
    return NO;
}

- (PLResultSetStatus) nextAndReturnError: (id *) error {
    [self assertNotClosed];
    
    int ret = pl_sqlite3_blocking_step(_sqlite_stmt);
    
    /* Inform the database of deadlock status */
    if (ret == SQLITE_BUSY || ret == SQLITE_LOCKED) {
        [_stmt.database setTxBusy];
    } else {
        [_stmt.database resetTxBusy];
    }

    /* No more rows available. */
    if (ret == SQLITE_DONE)
        return PLResultSetStatusDone;
    
    /* A row is available */
    if (ret == SQLITE_ROW)
        return PLResultSetStatusRow;



    /* An error has occured */
    [_stmt populateError: error withErrorCode: PLDatabaseErrorQueryFailed description: @"Could not retrieve the next result row"];
    return PLResultSetStatusError;
}

/* From PLResultSet */
- (BOOL) enumerateWithBlock: (void (^)(id<PLResultSet> rs, BOOL *stop)) block {
    return [self enumerateAndReturnError: NULL block: block];
}

/* From PLResultSet */
- (BOOL) enumerateAndReturnError: (id *) outError block: (void (^)(id<PLResultSet> rs, BOOL *stop)) block {
    BOOL stop = NO;
    
    /* Iterate over the results */
    PLResultSetStatus rss;
    while ((rss = [self nextAndReturnError: outError]) == PLResultSetStatusRow) {
        block(self, &stop);
        if (stop)
            break;
    }

    /* Handle completion invariant; the result set is expected to implicitly close when
     * all rows are iterated and *stop is not set. */
    if (stop == NO && rss == PLResultSetStatusDone) {
        [self close];
    }

    /* Handle error completion invariant. If an error occurs, the result set is expected
     * to implicitly close */
    if (rss == PLResultSetStatusError) {
        [self close];
        return NO;
    }
    
    return YES;
}


/* From PLResultSet */
- (int) columnIndexForName: (OFString *) name {
    [self assertNotClosed];
    
    /* Lazy initialization of the column name mapping. Profiling demonstrates that iPhone code doing a high
     * volume of queries avoids a significant performance penalty if the column name mapping is not used. */
    if (_columnNames == nil) {
        /* Create a column name cache */
        OFMutableDictionary *columnNames = [[OFMutableDictionary alloc] initWithCapacity: _columnCount];
        _columnNames = columnNames;

        for (int columnIndex = 0; columnIndex < _columnCount; columnIndex++) {
            /* Fetch the name */
            OFString *name = [OFString stringWithUTF8String: sqlite3_column_name(_sqlite_stmt, columnIndex)];
            
            /* Set the dictionary value */
            [columnNames setObject: [OFNumber numberWithInt: columnIndex] forKey: [name lowercaseString]];
        }
    }

    OFString *key = [name lowercaseString];
    OFNumber *idx = [_columnNames objectForKey: key];
    if (idx != nil) {
        return [idx intValue];
    }
    
    /* Not found */
    [OFException raise:PLSqliteException format: @"Attempted to access unknown result column %@", name];

    /* Unreachable */
    OF_UNREACHABLE;
}


/**
 * @internal
 * Validate the column index and return the column type
 */
- (int) validateColumnIndex: (int) columnIndex {
    [self assertNotClosed];

    int columnType;
    
    /* Verify that the index is in range */
    if (columnIndex > _columnCount - 1 || columnIndex < 0)
        [OFException raise:PLSqliteException format:@"Attempted to access out-of-range column index %d", columnIndex];
    /* Fetch the type */
    columnType = sqlite3_column_type(_sqlite_stmt, columnIndex);

    return columnType;
}

/* This beauty generates the PLResultSet value accessors for a given data type */
#define VALUE_ACCESSORS(ReturnType, MethodName, Expression) \
    - (ReturnType) MethodName ## ForColumnIndex: (int) columnIndex { \
        [self assertNotClosed]; \
        int columnType = [self validateColumnIndex: columnIndex]; \
        \
        /* Quiesce unused variable warning */ \
        if (YES || columnType == SQLITE_NULL) \
            return (Expression); \
    } \
    \
    - (ReturnType) MethodName ## ForColumn: (OFString *) column { \
        return [self MethodName ## ForColumnIndex: [self columnIndexForName: column]]; \
    }

/* bool */
VALUE_ACCESSORS(BOOL, bool, sqlite3_column_int(_sqlite_stmt, columnIndex))

/* int32_t */
VALUE_ACCESSORS(int32_t, int, sqlite3_column_int(_sqlite_stmt, columnIndex))

/* int64_t */
VALUE_ACCESSORS(int64_t, bigInt, sqlite3_column_int64(_sqlite_stmt, columnIndex))

/* date */
VALUE_ACCESSORS(OFDate *, date, columnType == SQLITE_NULL ? nil : 
                    [OFDate dateWithTimeIntervalSince1970: sqlite3_column_double(_sqlite_stmt, columnIndex)])

/* string */
VALUE_ACCESSORS(OFString *, string, columnType == SQLITE_NULL ? nil : 
                    [OFString stringWithUTF8String: (const char *)sqlite3_column_text(_sqlite_stmt, columnIndex)])

/* float */
VALUE_ACCESSORS(float, float, sqlite3_column_double(_sqlite_stmt, columnIndex))

/* double */
VALUE_ACCESSORS(double, double, sqlite3_column_double(_sqlite_stmt, columnIndex))

/* data */
VALUE_ACCESSORS(OFData *, data, columnType == SQLITE_NULL ? nil : 
                    [OFData dataWithItems: sqlite3_column_blob(_sqlite_stmt, columnIndex)
                                   count: sqlite3_column_bytes(_sqlite_stmt, columnIndex)])


/* From PLResultSet */
- (id) objectForColumnIndex: (int) columnIndex {
    [self assertNotClosed];

    int columnType = [self validateColumnIndex: columnIndex];
    switch (columnType) {
        case SQLITE_TEXT:
            return [self stringForColumnIndex: columnIndex];

        case SQLITE_INTEGER:
            return [OFNumber numberWithInt64: [self bigIntForColumnIndex: columnIndex]];

        case SQLITE_FLOAT:
            return [OFNumber numberWithDouble: [self doubleForColumnIndex: columnIndex]];

        case SQLITE_BLOB:
            return [self dataForColumnIndex: columnIndex];

        case SQLITE_NULL:
            return nil;

        default:
            [OFException raise:PLDatabaseException format:@"Unhandled SQLite column type %d", columnType];
    }

    /* Unreachable */
    OF_UNREACHABLE;
}


/* From PLResultSet */
- (id) objectForColumn: (OFString *) columnName {
    return [self objectForColumnIndex: [self columnIndexForName: columnName]];
}

/* From PLResultSet */
- (id) objectForKeyedSubscript: (id)key {
    return [self objectForColumn: key];
}

/* From PLResultSet */
- (id) objectAtIndexedSubscript: (uint64_t) index {
    return [self objectForColumnIndex: (int) index];
}


/* from PLResultSet */
- (BOOL) isNullForColumnIndex: (int) columnIndex {
    [self assertNotClosed];

    int columnType = [self validateColumnIndex: columnIndex];
    
    /* If the column has a null value, return YES. */
    if (columnType == SQLITE_NULL)
        return YES;

    /* Return NO for all other column types. */
    return NO;
}

/* from PLResultSet */
- (BOOL) isNullForColumn: (OFString *) columnName {
    return [self isNullForColumnIndex: [self columnIndexForName: columnName]];
}

@end
