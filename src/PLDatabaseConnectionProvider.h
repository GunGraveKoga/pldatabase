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


#import <ObjFW/OFObject.h>

#import "PLDatabase.h"

/**
 * A protocol for opening new or existing PLDatabase connections, and returning those connections for
 * re-use upon completion.
 *
 * @par Thread Safety
 * Thread-safe. May be used from any thread.
 *
 * @par Implementation Notes
 *
 * Implementations must be immutable and/or thread-safe, and must be usable from any thread without external
 * locking.
 */
@protocol PLDatabaseConnectionProvider <OFObject>

/**
 * Returns a database connection.
 *
 * @param error A pointer to an NSError object variable. If an error occurs, this
 * pointer will contain an error object indicating why the transaction could not
 * be started.
 *
 * @return A database connection, or nil on error.
 */
- (id<PLDatabase>) getConnectionAndReturnError: (id *) error;

/**
 * Called to return the given connection for re-use. The connection may be immediately closed.
 */
- (void) closeConnection: (id<PLDatabase>) connection;

@end