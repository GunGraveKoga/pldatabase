# pldatabase


## Introduction

PLDatabase provides a SQL database access library for Objective-C, focused on SQLite as an application database. The library supports both Mac OS X and iPhone development.
Plausible Database is provided free of charge under the BSD license, and may be freely integrated with any application.

## Building

### Requirements

SQLite3 library with support of  sqlite3_unlock_notify() interface.
See https://www.sqlite.org/compile.html for details.

### Compilation

You can compile pldatabase as standalone library or as a part of your application^

1. objfw-compile [sources list] -I/path/to/sqlite/headers -DPL_DB_PRIVATE -o <library_name> --lib <version> -L/path/to/sqlite/libraries -l<sqlite3_static_or_shared_lib>
2. objfw-compile [sources list] -I/path/to/sqlite/headers -DPL_DB_PRIVATE -o <application_name> -L/path/to/sqlite/libraries -l<sqlite3_static_or_shared_lib>

## Original GitHub Link

https://github.com/plausiblelabs/pldatabase

### P.S.

English is not my native language, if you find some kind of typos and grammar mistakes, please let me know.