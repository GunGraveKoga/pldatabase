//
//  OFError.h
//  TestObjFW
//
//  Created by Yury Vovk on 27.10.2017.
//  Copyright © 2017 Doctor Web, Ltd. All rights reserved.
//

#import <ObjFW/ObjFW.h>

typedef OFString *OFErrorDomain;

OF_ASSUME_NONNULL_BEGIN

extern OFString * const OFLocalizedDescriptionKey;
extern OFString * const OFFilePathErrorKey;
extern OFString * const OFStringEncodingErrorKey;
extern OFString * const OFUnderlyingErrorKey;
extern OFString * const OFURLErrorKey;
extern OFString * const OFLocalizedFailureReasonErrorKey;
extern OFString * const OFLocalizedRecoverySuggestionErrorKey;
extern OFString * const OFURLErrorFailingURLErrorKey;

extern OFErrorDomain const OFPOSIXErrorDomain;
extern OFErrorDomain const OFOSStatusErrorDomain;



@interface OFError : OFObject <OFCopying>
{
    @private
    ssize_t _code;
    OFErrorDomain _domain;
    OFDictionary *_userInfo;
}

@property (readonly) ssize_t code;
@property (readonly, copy) OFErrorDomain domain;
@property (readonly, copy) OFDictionary *userInfo;
@property(readonly, copy, nullable) OFString *localizedDescription;
@property(readonly, copy, nullable) OFString *localizedRecoverySuggestion;
@property(readonly, copy, nullable) OFString *localizedFailureReason;


+ (instancetype)errorWithDomain:(OFErrorDomain)domain code:(ssize_t)code userInfo:(OFDictionary *)userInfo;
- (instancetype)initWithDomain:(OFErrorDomain)domain code:(ssize_t)code userInfo:(OFDictionary *)userInfo;


@end

OF_ASSUME_NONNULL_END
