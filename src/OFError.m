//
//  OFError.m
//  TestObjFW
//
//  Created by Yury Vovk on 27.10.2017.
//  Copyright © 2017 Doctor Web, Ltd. All rights reserved.
//

#import "OFError.h"

OFString * const OFLocalizedDescriptionKey = @"OFLocalizedDescriptionKey";

OFString * const OFFilePathErrorKey = @"OFFilePathErrorKey";
OFString * const OFStringEncodingErrorKey = @"OFStringEncodingErrorKey";
OFString * const OFUnderlyingErrorKey = @"OFUnderlyingErrorKey";
OFString * const OFURLErrorKey = @"OFURLErrorKey";
OFString * const OFLocalizedFailureReasonErrorKey = @"OFLocalizedFailureReasonErrorKey";
OFString * const OFLocalizedRecoverySuggestionErrorKey = @"OFLocalizedRecoverySuggestionErrorKey";
OFString * const OFURLErrorFailingURLErrorKey = @"OFURLErrorFailingURLErrorKey";

OFErrorDomain const OFPOSIXErrorDomain = @"OFPOSIXErrorDomain";
OFErrorDomain const OFOSStatusErrorDomain = @"OFOSStatusErrorDomain";

@implementation OFError

@synthesize code = _code;
@synthesize domain = _domain;
@synthesize userInfo = _userInfo;

@dynamic localizedDescription, localizedFailureReason, localizedRecoverySuggestion;

- (instancetype)init {
    OF_INVALID_INIT_METHOD;
    
    OF_UNREACHABLE;
}

+ (instancetype)errorWithDomain:(OFErrorDomain)domain code:(ssize_t)code userInfo:(OFDictionary *)userInfo {
    return [[[self alloc] initWithDomain:domain code:code userInfo:userInfo] autorelease];
}

- (instancetype)initWithDomain:(OFErrorDomain)domain code:(ssize_t)code userInfo:(OFDictionary *)userInfo {
    self = [super init];
    
    _code = code;
    _domain = [domain copy];
    _userInfo = [userInfo copy];
    
    return self;
}

- (OFString *)localizedRecoverySuggestion {
    return [[[_userInfo objectForKey:OFLocalizedRecoverySuggestionErrorKey] retain] autorelease];
}

- (OFString *)localizedFailureReason {
    return [[[_userInfo objectForKey:OFLocalizedFailureReasonErrorKey] retain] autorelease];
}

- (OFString *)localizedDescription {
    return [[[_userInfo objectForKey:OFLocalizedDescriptionKey] retain] autorelease];
}

- (id)copy {
    return [[OFError alloc] initWithDomain:_domain code:_code userInfo:_userInfo];
}

- (OFString *)description {
    return [self localizedDescription];
}

- (void)dealloc {
    [_domain release];
    [_userInfo release];
    
    [super dealloc];
}

@end
