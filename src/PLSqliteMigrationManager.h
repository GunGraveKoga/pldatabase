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

#import "PLDatabaseMigrationManager.h"

/**
 * Implements database schema versioning using SQLite's per-database user_version field
 * (see http://www.sqlite.org/pragma.html#version).
 *
 * Additionally implements the requisite SQLite locking.
 *
 * @warning This class depends on, and modifies, the SQLite per-database user_version
 * field. Users of this class must not modify or rely upon the value of the user_version. This class
 * will not correctly function if the user_version is externally modified.
 *
 * @par Thread Safety
 * PLSqliteMigrationVersionManager instances implement no locking and must not be shared between threads.
 */
@interface PLSqliteMigrationManager : OFObject <PLDatabaseMigrationVersionManager, PLDatabaseMigrationTransactionManager>

@end

/* Provide a compatibility alias for the legacy class name. */
/**
 * @deprecated Replaced by PLSqliteMigrationManager.
 */
__attribute__((deprecated("PLSqliteMigrationVersionManager is deprecated!!! Use PLSqliteMigrationManager insted")))
@interface PLSqliteMigrationVersionManager : PLSqliteMigrationManager
@end
