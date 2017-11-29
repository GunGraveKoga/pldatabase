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

#import "OFError.h"

/** 
 * Generic Database Exception
 * @ingroup exceptions
 */
OFString * const PLDatabaseException = @"PLDatabaseException";

/** Plausible Database NSError Domain
 * @ingroup globals */
OFString * const PLDatabaseErrorDomain = @"PLDatabaseErrorDomain";

/**
 * Key to retrieve the optionally provided SQL query which caused the error from an NSError in the PLDatabaseErrorDomain, as an OFString
 * @ingroup globals
 */
OFString * const PLDatabaseErrorQueryStringKey = @"PLDatabaseErrorQueryStringKey";

/**
  * Key to retrieve the native database error code from an NSError in the PLDatabaseErrorDomain, as an NSNumber
  * @ingroup globals
  */
OFString * const PLDatabaseErrorVendorErrorKey = @"PLDatabaseErrorVendorErrorKey";

/** 
 * Key to retrieve the native database error string from an NSError in the PLDatabaseErrorDomain, as an OFString
 * @ingroup globals
 */
OFString * const PLDatabaseErrorVendorStringKey = @"PLDatabaseErrorVendorStringKey";

OFString * const OFVendorErrorCodeKey = @"OFVendorErrorCodeKey";
OFString * const OFVendorErrorStringKey = @"OFVendorErrorStringKey";

@implementation OFError (PLDataBaseError)

- (OFString *)vendorErrorString {
    return _userInfo[OFVendorErrorStringKey];
}

- (int)vendorErrorCode {
    return ((OFNumber *)_userInfo[OFVendorErrorCodeKey]).intValue;
}

@end

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
 * @param vendorError The native SQL driver's error code.
 * @param vendorErrorString The native SQL driver's non-localized error string.
 * @return A NSError that may be returned to the API caller.
 */
+ (id) errorWithCode: (PLDatabaseError) errorCode localizedDescription: (OFString *) localizedDescription 
                queryString: (OFString *) queryString vendorError: (OFNumber *) vendorError
                vendorErrorString: (OFString *) vendorErrorString 
{
    OFMutableDictionary *userInfo;

    /* Create the userInfo dictionary */
    userInfo = [OFMutableDictionary dictionaryWithKeysAndObjects: 
                OFLocalizedDescriptionKey, localizedDescription,
                PLDatabaseErrorVendorErrorKey, vendorError,
                PLDatabaseErrorVendorStringKey, vendorErrorString,
                OFVendorErrorCodeKey, vendorError,
                OFVendorErrorStringKey, vendorErrorString,
                nil];
    
    /* Optionally insert the query string. */
    if (queryString != nil)
        [userInfo setObject: queryString forKey: PLDatabaseErrorQueryStringKey];
    
    /* Return the NSError */
    //return [NSError errorWithDomain: PLDatabaseErrorDomain code: errorCode userInfo: userInfo];
    return [OFError errorWithDomain:PLDatabaseErrorDomain code:errorCode userInfo:userInfo];
}

@end
