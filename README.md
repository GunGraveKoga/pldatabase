# pldatabase


## Introduction

PLDatabase provides a SQL database access library for Objective-C, focused on SQLite as an application database. The library supports both Mac OS X and iPhone development.
Plausible Database is provided free of charge under the BSD license, and may be freely integrated with any application.

## Building

### Requirements
OFDataArray class extension with -initWithBytes:(const void *)length:(size_t) and +dataWithBytes:(const void *)length:(size_t) methods that create instance of OFDataArray with passed bytes

OFException subclass supporting +exceptionWithName:(OFString *)name format:(OFConstantString *)format, ... initialisation method
If you want implement this class by yourself, you must pass preprocessor directives at compilation:

1. -DUNIVERSAL_EXCEPTION=ClasName

Pleas look at PLSqliteDatabase.m & PLSqlitePreparedStatement.m & PLSqliteResultSet.m for example

Error holder class (similar to NSError), that implement errorWithSource:(OFString*)code:(int32_t)userInfo:(OFDicitonary *) initialization method.
If you want implement this class by yourself, you must pass preprocessor directives at compilation:

1. -DERROR_HANDLER_CLASS=ClassName
2. -DERROR_DESCRIPTION_KEY=@"YourDescriptionKey"
3. -DVENDOR_ERROR_CODE_KEY=@"YourVendorErrorCodeKey"
4. -DVENDOR_ERROR_DESCRIPTION_KEY=@"YourVendorDescriptionKey"

Pleas, look at PlausibleDatabase.m for example

All these classes was implemented by me. You can get them at https://github.com/GunGraveKoga/ObjFW-Additional-Classes

Also you must compile sqlite3 library with support of  sqlite3_unlock_notify() interface.
See https://www.sqlite.org/compile.html for details.

### Compilation

You can compile pldatabase as standalone library or as a part of your application^

1. <platform>-objfw-compile [sources list] -I/path/to/sqlite/headers -DPL_DB_PRIVATE -o <library_name> --lib <version> -L/path/to/sqlite/libraries -l<sqlite3_static_or_shared_lib>
2. <platform>-objfw-compile [sources list] -I/path/to/sqlite/headers -DPL_DB_PRIVATE -o <application_name> -L/path/to/sqlite/libraries -l<sqlite3_static_or_shared_lib>

## Original GitHub Link

https://github.com/plausiblelabs/pldatabase

### P.S.

English is not my native language, if you find some kind of typos and grammar mistakes, please let me know.