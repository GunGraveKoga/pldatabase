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
#import "PlausibleDatabase.h"
#import "PLDatabaseConstants.h"

#if !defined(ERROR_HANDLER_CLASS)
    #import "OFError.h"
    #define ERROR_HANDLER_CLASS OFError
    #define ERROR_DESCRIPTION_KEY OFErrorDescription
    #define VENDOR_ERROR_CODE_KEY OFVendorErrorCode
    #define VENDOR_ERROR_DESCRIPTION_KEY OFVendorErrorString
#endif

/** 
 * Generic Database Exception
 * @ingroup exceptions
 */
OFString *PLDatabaseException = @"PLDatabaseException";

/** Plausible Database NSError Domain
 * @ingroup globals */
OFString *PLDatabaseErrorDomain = @"PLDatabaseErrorDomain";

/**
 * Key to retrieve the optionally provided SQL query which caused the error from an NSError in the PLDatabaseErrorDomain, as an OFString
 * @ingroup globals
 */
OFString *PLDatabaseErrorQueryStringKey = @"PLDatabaseErrorQueryStringKey";

/**
  * Key to retrieve the native database error code from an NSError in the PLDatabaseErrorDomain, as an NSNumber
  * @ingroup globals
  */
OFString *PLDatabaseErrorVendorErrorKey = @"PLDatabaseErrorVendorErrorKey";

/** 
 * Key to retrieve the native database error string from an NSError in the PLDatabaseErrorDomain, as an OFString
 * @ingroup globals
 */
OFString *PLDatabaseErrorVendorStringKey = @"PLDatabaseErrorVendorStringKey";

/**
 * @internal
 * Implementation-private utility methods.
 */
@implementation PlausibleDatabase

/**
 * @internal
 *
 * Create a new NSError in the PLDatabaseErrorDomain.
 *
 * @param errorCode The error code.
 * @param localizedDescription A localized error description.
 * @param queryString The optional query which caused the error.
 * @param nativeCode The native SQL driver's error code.
 * @param nativeString The native SQL driver's non-localized error string.
 * @return A NSError that may be returned to the API caller.
 */
+ (id) errorWithCode: (PLDatabaseError) errorCode localizedDescription: (OFString *) localizedDescription 
                queryString: (OFString *) queryString vendorError: (OFNumber *) vendorError
                vendorErrorString: (OFString *) vendorErrorString 
{
    OFMutableDictionary *userInfo;

    /* Create the userInfo dictionary */
    userInfo = [OFMutableDictionary dictionaryWithKeysAndObjects: 
                ERROR_DESCRIPTION_KEY, localizedDescription,
                PLDatabaseErrorVendorErrorKey, vendorError,
                PLDatabaseErrorVendorStringKey, vendorErrorString,
                VENDOR_ERROR_CODE_KEY, vendorError,
                VENDOR_ERROR_DESCRIPTION_KEY, vendorErrorString,
                nil];
    
    /* Optionally insert the query string. */
    if (queryString != nil)
        [userInfo setObject: queryString forKey: PLDatabaseErrorQueryStringKey];
    
    /* Return the NSError */
    //return [NSError errorWithDomain: PLDatabaseErrorDomain code: errorCode userInfo: userInfo];
    return [ERROR_HANDLER_CLASS errorWithSource:PLDatabaseErrorDomain code:errorCode userInfo:userInfo];
}

@end