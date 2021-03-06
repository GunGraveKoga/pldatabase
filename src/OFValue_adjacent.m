//
//  OFValue_adjacent.m
//
//  Created by Yury Vovk on 02.11.2017.
//

#import "OFValue_adjacent.h"

@implementation OFValue_adjacent

- (instancetype)initWithBytes:(const void *)value objCType:(const char *)type {
    self = [super init];
    
    @try {
        size_t objCTypeStrLength = strlen(type);
        _objCType = [self allocMemoryWithSize:sizeof(char) count:objCTypeStrLength + 1];
        memset((void *)_objCType, 0, objCTypeStrLength + 1);
        memmove((void *)_objCType, type, objCTypeStrLength);
        
        _dataSize = of_sizeof_type_encoding(type);
        
        _data = [self allocMemoryWithSize:_dataSize count:1];
        
        memset(_data, 0, _dataSize);
        memmove(_data, value, _dataSize);
    } @catch (id e) {
        [self release];
        
        @throw e;
    }
    
    return self;
}

- (void)getValue:(void *)value {
    memmove(value, _data, _dataSize);
}

- (const char *)objCType {
    return _objCType;
}

- (void)getValue:(void *)value size:(size_t)size {
    
    if (size > _dataSize)
        @throw [OFInvalidArgumentException exception];
    
    memmove(value, _data, size);
}

- (uint32_t)hash {
    uint32_t hash;
    
    OF_HASH_INIT(hash);
    
    for (size_t i = 0; i < _dataSize; i++) {
        OF_HASH_ADD(hash, ((uint8_t *)_data)[i]);
    }
    
    OF_HASH_FINALIZE(hash);
    
    return hash;
}

- (bool)isEqual:(id)object {
    
    OFValue_adjacent *value;
    
    if (object == self)
        return true;
    
    if (![object isKindOfClass:[OFValue_adjacent class]])
        return false;
    
    value = object;
    
    if (value->_dataSize != _dataSize)
        return false;
    
    if (memcmp(value->_data, _data, _dataSize) != 0)
        return  false;
    
    
    return true;
    
}

@end
