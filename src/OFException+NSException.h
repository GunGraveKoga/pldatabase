//
//  OFException + NSException.h
//  libbacktrace
//
//  Created by Yury Vovk on 29.09.17.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>

typedef OFString *OFExceptionName;

extern OFString * const OFLocalizedReasonKey;

@interface OFException (NSException)

@property (readonly, copy) OFExceptionName name;
@property (readonly, copy) OFString *reason;
@property (readonly, copy) OFDictionary *userInfo;
@property (readonly, copy) OFArray<OFString*> *callStackSymbols;

+ (instancetype)exceptionWithName:(OFExceptionName)name reason:(OFString *)reason userInfo:(OFDictionary *)userInfo;
+ (void)raise:(OFExceptionName)name format:(OFConstantString *)format, ...;
+ (void)raise:(OFExceptionName)name format:(OFConstantString *)format arguments:(va_list)arguments;
- (instancetype)initWithName:(OFExceptionName)name reason:(OFString *)reason userInfo:(OFDictionary *)userInfo;
- (void)raise;

@end
