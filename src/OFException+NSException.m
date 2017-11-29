//
//  OFException + NSException.m
//  libbacktrace
//
//  Created by Yury Vovk on 29.09.17.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "OFException+NSException.h"
#import "__OFNSException.h"

OFString * const OFLocalizedReasonKey = @"OFLocalizedReasonKey";

@implementation OFException (NSException)

@dynamic name, reason;
@dynamic userInfo;
@dynamic callStackSymbols;

+ (instancetype)exceptionWithName:(OFExceptionName)name reason:(OFString *)reason userInfo:(OFDictionary *)userInfo {
    return [[[self alloc] initWithName:name reason:reason userInfo:userInfo] autorelease];
}

+ (void)raise:(OFExceptionName)name format:(OFConstantString *)format, ... {
    va_list arguments;
    va_start(arguments, format);
    
    [self raise:name format:format arguments:arguments];
}

+ (void)raise:(OFExceptionName)name format:(OFConstantString *)format arguments:(va_list)arguments {
    OFString *reason = [[OFString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    
    id exception = [self exceptionWithName:name reason:reason userInfo:nil];
    [reason release];
    
    @throw exception;
}

- (instancetype)initWithName:(OFExceptionName)name reason:(OFString *)reason userInfo:(OFDictionary *)userInfo {
    OF_INVALID_INIT_METHOD;
}

- (void)raise {
    @throw self;
}

- (OFExceptionName)name {
    if([self class] == [__OFNSException class])
        return [OFString stringWithUTF8String:"OFException"];
    
    return [self className];
}

- (OFString *)reason {
    return [self description];
}

- (OFDictionary *)userInfo {
    return nil;
}

- (OFArray<OFString*> *)callStackSymbols {
    return [self backtrace];
}

@end
