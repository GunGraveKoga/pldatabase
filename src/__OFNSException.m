//
//  __OFNSException.m
//  libbacktrace
//
//  Created by Yury Vovk on 29.09.17.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "__OFNSException.h"
#if defined(OF_APPLE_RUNTIME)
#import <objc/objc.h>
#import <objc/runtime.h>
#endif

static const char *
__OFNSException_typeEncodingForSelector(Class class, SEL selector)
{
#if defined(OF_OBJFW_RUNTIME)
    return class_getMethodTypeEncoding(class, selector);
#else
    Method m;
    
    if ((m = class_getInstanceMethod(class, selector)) == NULL)
        return NULL;
    
    return method_getTypeEncoding(m);
#endif
}

static struct {
    Class isa;
} placeholder;

static IMP __parentAllocMethod = NULL;

@interface __OFNSException__Placeholder : OFException
@end

@implementation __OFNSException {
    OFExceptionName _name;
    OFString *_reason;
    OFDictionary *_userInfo;
}

+ (void)load {
    if(self == [__OFNSException class]) {
        placeholder.isa = [__OFNSException__Placeholder class];
        
        __parentAllocMethod = [OFException replaceClassMethod:@selector(alloc) withMethodFromClass:[__OFNSException class]];
    }
}

+ (void)unload {
    SEL selector = @selector(alloc);
    Class cls = [OFException class];
    
    (void)class_replaceMethod(cls, selector, __parentAllocMethod, __OFNSException_typeEncodingForSelector(cls, selector));
}

+ alloc {
    if(self == [OFException class])
        return (id)&placeholder;
    
    if(__parentAllocMethod != NULL) {
        SEL selector = @selector(alloc);
        
        typedef id(*__OFException_alloc)(id, SEL);
        
        __OFException_alloc __alloc = (__OFException_alloc)__parentAllocMethod;
        
        return __alloc(self, selector);
    }
    
    return of_alloc_object(self, 0, 0, NULL);
}

- init {
    self = [super init];
    
    _name = nil;
    _reason = nil;
    _userInfo = nil;
    
    return self;
}

- (instancetype)initWithName:(OFExceptionName)name reason:(OFString *)reason userInfo:(OFDictionary *)userInfo {
    self = [super init];
    
    _name = [name copy];
    _reason = [reason copy];
    _userInfo = [userInfo copy];
    
    return self;
}

- (OFExceptionName)name {
    if(_name == nil)
        return [super name];
    
    return _name;
}

- (OFString *)reason {
    if(_reason == nil)
        return [self description];
    
    return _reason;
}

- (OFDictionary *)userInfo {
    return _userInfo;
}

- (OFString *)description {
    if(_name != nil) {
        OFMutableString *description = [OFMutableString string];
        
        [description appendFormat:@"An exception of type %@ occurred!\n", _name];
        
        if(_userInfo[OFLocalizedReasonKey] != nil) {
            [description appendString:OF_LOCALIZED(_userInfo[OFLocalizedReasonKey], @"%[reason]", @"reason", _reason)];
        }
        else {
            [description appendString:_reason];
        }
        
        [description makeImmutable];
        
        return description;
        
    }
    
    return [OFString stringWithUTF8String:"An exception of type OFException occurred!"];
}

- (void)dealloc {
    [_name release];
    [_reason release];
    [_userInfo release];
    
    [super dealloc];
}

@end

@implementation __OFNSException__Placeholder

- init {
    return (id)[[__OFNSException alloc] init];
}

- (instancetype)initWithName:(OFExceptionName)name reason:(OFString *)reason userInfo:(OFDictionary *)userInfo {
    return (id)[[__OFNSException alloc] initWithName:name reason:reason userInfo:userInfo];
}

@end
