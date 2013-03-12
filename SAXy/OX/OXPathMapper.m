//
//  OXPathMapper.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/28/13.
//

#import "OXPathMapper.h"
#import "OXComplexMapper.h"
#import "OXContext.h"
#import "OXUtil.h"
#import "OXProperty.h"

#pragma mark - OXPathMapper


@implementation OXPathMapper

#pragma mark - constructors

- (id)initMapperWithEnum:(OXMapperEnum)mapperEnum
{
    if (self = [super init]) {
        _mapperEnum = mapperEnum;
    }
    return self;
}

- (id)init
{
    return [self initMapperWithEnum:OX_PATH_MAPPER];
}

- (id)initMapperToType:(OXType *)toType toPath:(NSString *)toPath fromType:(OXType *)fromType fromPath:(NSString *)fromPath
{
    if (self = [self init]) {
        _toType = toType;
        _toPath = toPath;
        _fromType = fromType;
        _fromPath = fromPath;
    }
    return self;
}

- (id)initMapperToClass:(Class)toType toPath:(NSString *)toPath fromClass:(Class)fromType fromPath:(NSString *)fromPath
{
    if (self = [self init]) {
        _toType = [OXType cachedType:toType];
        _toPath = toPath;
        _fromType = [OXType cachedType:fromType];
        _fromPath = fromPath;  
    }
    return self;
}

- (id)initMapperToClass:(Class)toType toPath:(NSString *)toPath fromScalar:(const char *)fromEncodedType fromPath:(NSString *)fromPath
{
    if (self = [self init]) {
        _toType = [OXType cachedType:toType];
        _toPath = toPath;
        _fromType = [OXType cachedScalarType:fromEncodedType];
        _fromPath = fromPath;
    }
    return self;
}

- (id)initMapperToScalar:(const char *)toEncodedType toPath:(NSString *)toPath fromClass:(Class)fromType fromPath:(NSString *)fromPath
{
    if (self = [self init]) {
        _toType = [OXType cachedScalarType:toEncodedType];
        _toPath = toPath;
        _fromType = [OXType cachedType:fromType];
        _fromPath = fromPath;
    }
    return self;
}

#pragma mark - properties

@dynamic toPathRoot;
- (NSString *)toPathRoot
{
    return [OXUtil firstSegmentFromPath:_toPath separator:'.'];         //assume KVC dot-separators
}

@dynamic fromPathRoot;
- (NSString *)fromPathRoot
{
    return [OXUtil firstSegmentFromPath:_fromPath separator:'.'];       //assume KVC dot-separators
}

@dynamic toPathLeaf;
- (NSString *)toPathLeaf
{
    return [OXUtil lastSegmentFromPath:_toPath separator:'.'];          //assume KVC dot-separators
}

@dynamic fromPathLeaf;
- (NSString *)fromPathLeaf
{
    return [OXUtil lastSegmentFromPath:_fromPath separator:'.'];        //assume KVC dot-separators
}

#pragma mark - public


- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@ <- %@", NSStringFromClass(_toType.type), _toPath, _fromPath];
}

- (void)assignDefaultBlocks:(OXContext *)context
{
    BOOL isComplexKVC = [_toPath rangeOfString:@"."].location != NSNotFound;
    if (!_factory) {
        _factory = ^(NSString *path, OXContext *ctx) {
            OXPathMapper *mapper = ctx.currentMapper;
            return [[mapper.toType.type alloc] init];
        };
    }
//    if ([_toPath isEqualToString:@"address"])
//        NSLog(@"address");
    switch (self.toType.typeEnum) {
        case OX_CONTAINER: {
            //OXContainerType *containterType = (OXContainerType *)self.toType;
            if ( ! self.appender)
                self.appender = [context.transform appenderForContainer:self.toType.type];
            if ( ! self.enumerator)
                self.enumerator = [context.transform enumerationForContainer:self.toType.type];
            if ( ! _getter) {
                if (isComplexKVC) {
                    _getter = ^(NSString *key, id target, OXContext *ctx) {
                        return [target valueForKeyPath:key];   //call KVC getter
                    };
                } else {
                    _getter = ^(NSString *key, id target, OXContext *ctx) {
                        return [target valueForKey:key];   //call KVC getter
                    };
                }
            }
            if ( ! _setter) {
                if (isComplexKVC) {
                    _setter = ^(NSString *key, id value, id target, OXContext *ctx) {
                        [target setValue:value forKeyPath: key];  //set using KVC
                    };
                } else {
                    _setter = ^(NSString *key, id value, id target, OXContext *ctx) {
                        [target setValue:value forKey: key];  //set using KVC
                    };
                }
            }
            //Allow atomic/scalar container child types to be converted to/from string values, needed for NSDate, NSURL, etc.
            //TODO
            // 1) add childFromType property        - assuming NSString for now
            // 2) add dedicated toChildTransform    - using container property toTransform for now
            // 3) add dedicated fromChildTransform  - using container property fromTransform for now
            OXType *childType = _toType.containerChildType;
            if (childType.typeEnum == OX_ATOMIC || childType.typeEnum == OX_SCALAR) {
                Class fromClass = [NSString class];     //this assumtions prevents arrays of JSON numbers or booleans - to fix, have to store childFromType
                if ( ! self.toTransform)
                    self.toTransform = [context.transform transformerFrom:fromClass to:childType.type];     //hijack unused toTransform
                if ( ! self.fromTransform && _fromType)
                    self.fromTransform = [context.transform transformerFrom:childType.type to:fromClass];   //hijack unused fromTransform
            }
            break;
        }
        case OX_SCALAR: {
            BOOL requireTransform = _fromType ? ![_fromType.type isSubclassOfClass:[NSValue class]] : YES;  //don't complain about NSNumber mappings
            if ( ! self.toTransform && _fromType) {
                self.toTransform = [context.transform transformerFrom:_fromType.type toScalar:self.toType.scalarEncoding];     //_fromType.type is usualy a NSString
            }
            if ( ! self.fromTransform && _fromType) {
                self.fromTransform = [context.transform transformerScalar:_toType.scalarEncoding to:_fromType.type];
            }
            if (requireTransform) {
                if (!self.toTransform && !self.setter)
                    NSAssert2(NO, @"ERROR: missing required toTransform for %@->%@ scalar mapping", _fromType, _toType);
                if (!self.fromTransform && !self.getter)
                    NSAssert1(NO, @"ERROR: missing required fromTransform for %@->NSString scalar mapping", _toType);
            }
        }   //fall-through to OX_ATOMIC
        case OX_COMPLEX:
        case OX_ATOMIC: {
            if ( ! self.toTransform && _fromType)
                self.toTransform = [context.transform transformerFrom:_fromType.type to:_toType.type];
            if ( ! self.fromTransform && _fromType)
                self.fromTransform = [context.transform transformerFrom:_toType.type to:_fromType.type];
            //setter method
            if ( ! _setter) {
                if (isComplexKVC) {
                    if (self.toTransform) {   // is there a string->object converter?
                        _setter = ^(NSString *key, id value, id target, OXContext *ctx) {
                            OXPathMapper *mapper = ctx.currentMapper;
                            id obj = mapper.toTransform(value, ctx); //convert string->object
                            [target setValue:obj forKeyPath:key];  //set using KVC
                        };
                    } else {
                        _setter = ^(NSString *key, id value, id target, OXContext *ctx) {
                            [target setValue:value forKeyPath:key];  //set using KVC
                        };
                    }
                } else {
                    if (self.toTransform) {   // is there a string->object converter?
                        _setter = ^(NSString *key, id value, id target, OXContext *ctx) {
                            OXPathMapper *mapper = ctx.currentMapper;
                            id obj = mapper.toTransform(value, ctx); //convert string->object
                            [target setValue:obj forKey:key];  //set using KVC
                        };
                    } else {
                        _setter = ^(NSString *key, id value, id target, OXContext *ctx) {
                            [target setValue:value forKey:key];  //set using KVC
                        };
                    }
                }
            }
            //getter method
            if ( ! _getter) {
                if (isComplexKVC) {
                    if (self.fromTransform) {   // is there a object->string converter?
                        _getter = ^(NSString *key, id target, OXContext *ctx) {
                            id value = [target valueForKeyPath:key];
                            OXPathMapper *mapper = ctx.currentMapper;
                            return value==nil ? nil : mapper.fromTransform(value, ctx);
                        };
                    } else {
                        _getter = ^(NSString *key, id target, OXContext *ctx) {
                            return [target valueForKeyPath:key];   //call KVC getter
                        };
                    }
                } else {
                    if (self.fromTransform) {   // is there a object->string converter?
                        _getter = ^(NSString *key, id target, OXContext *ctx) {
                            id value = [target valueForKey:key];
                            OXPathMapper *mapper = ctx.currentMapper;
                            return value==nil ? nil : mapper.fromTransform(value, ctx);
                        };
                    } else {
                        _getter = ^(NSString *key, id target, OXContext *ctx) {
                            return [target valueForKey:key];   //call KVC getter
                        };
                    }
                }
            }
            break;
        }
        default:
            NSAssert3(NO, @"ERROR: unknown toType.typeEnum: %d for %@->%@ scalar mapping", self.toType.typeEnum, _fromType, _toType);
            break;
    }
}

- (NSArray *)addErrorMessage:(NSString *)errorMessage errors:(NSArray *)errors
{
    NSError *error = [NSError errorWithDomain:@"com.outsourcecafe.ox" code:99 userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    if (errors == nil)
        errors = [NSMutableArray array];
    if ([errors isKindOfClass:[NSMutableArray class]]) {
        [((NSMutableArray *)errors) addObject:error];
    } else {
        errors = [errors arrayByAddingObject:error];
    }
    return errors;
}

/**
 Complete the mapping using self-reflection and check for error states.  
 
 Mapping completion tasks:
   1) set the target Class (_toType.type) based on what we find in the OXProperty
 
 Validation tasks:
   1) make sure the property name exists in properties dictionary
   2) if target class is provided, make sure it matches what's found in OXProperty
   3) check container and scalar types have all required properties set
  */
- (NSArray *)verifyToTypeUsingSelfReflection:(OXContext *)context errors:(NSArray *)errors
{
    if (_parent.toType) {               //no parent, no properties
        if (!self.virtualProperty) {    //virtual? skip type checking, because this is not a real property
            OXProperty *toProperty = [_parent.toType.properties objectForKey:self.toPathRoot];  //look up poperty metadata
            if (toProperty == nil)
                errors = [self addErrorMessage:[NSString stringWithFormat:@"no %@.%@ property found in %@ -> %@ mapping", NSStringFromClass(_parent.toType.type), self.toPathRoot, _fromPath, _toPath] errors:errors];
            Class actualToClass = toProperty.type.type;                                 //grab type from property
            BOOL isComplexKVC = [_toPath rangeOfString:@"."].location != NSNotFound;    //is this a key path?
            if (isComplexKVC) {
                if (!_toType && !_toType.type) {    //key path special case - require explicit type declarations
                    //TODO this could be fixed by following KVC property chain to discover leaf class
                    errors = [self addErrorMessage:[NSString stringWithFormat:@"complex KVC property mappings require explicit type or scalar specification -> %@ mapping", self] errors:errors];
                }
            } else if (_toType && _toType.type) {
                if ( ! [actualToClass isEqual:_toType.type] ) {
                    if ([_toType.type isSubclassOfClass:actualToClass]) {
                        if ( ! [_parent.toType.type isSubclassOfClass:[OXContext class]] ) //normal for document result object
                            NSLog(@"WARNING: %@.%@ property in  %@ -> %@ mapping is polymorphic %@ to %@", NSStringFromClass(_parent.toType.type), self.toPathRoot, _fromPath, _toPath, NSStringFromClass(actualToClass), NSStringFromClass(_toType.type));
                    } else {
                        errors = [self addErrorMessage:[NSString stringWithFormat:@"property class conflict %@ != %@ in %@ -> %@ mapping", NSStringFromClass(actualToClass), NSStringFromClass(_parent.toType.type), _fromPath, _toPath] errors:errors];
                    }
                    if (_toType.typeEnum == OX_CONTAINER && _toType.containerChildType == nil) {
                        errors = [self addErrorMessage:[NSString stringWithFormat:@"container property has no child type in %@ mapping", self] errors:errors];
                    }
                }
            } else if (_toType && _toType.type == nil) {   //check for other attributes before overwriting with property type
                if (_toType.containerChildType) {
                    self.toType = [OXType typeContainer:actualToClass containing:_toType.containerChildType.type];
                }
                if (_toType.scalarEncoding) {
                    self.toType = [OXType scalarType:actualToClass scalarEncoding:_toType.scalarEncoding];
                }
            } else if (_toType == nil) {
                _toType = toProperty.type;
            }
            if (_toType.typeEnum == OX_SCALAR && _toType.scalarEncoding == nil) {
                errors = [self addErrorMessage:[NSString stringWithFormat:@"scalar property must have scalarEncoding in %@ mapping", self] errors:errors];
            }
            if (_toType.typeEnum == OX_CONTAINER && [_toType.type isSubclassOfClass:[NSDictionary class]]) {
                Class childType = _toType.containerChildType.type;
                if (_dictionaryKeyName == nil) {
                    errors = [self addErrorMessage:[NSString stringWithFormat:@"'dictionaryKeyName' is nil, it must point to a valid property of %@ in %@ mapping", NSStringFromClass(childType), self] errors:errors];
                } else {
                    OXType *oxChildType = [OXType cachedType:childType];
                    OXProperty *keyProp = [oxChildType.properties objectForKey:_dictionaryKeyName];
                    if (keyProp == nil && [_dictionaryKeyName rangeOfString:@"."].location == NSNotFound) {
                        errors = [self addErrorMessage:[NSString stringWithFormat:@"dictionaryKeyName: '%@' not a valid property of %@ class in %@ mapping", _dictionaryKeyName, NSStringFromClass(childType), self] errors:errors];
                    }
                }
            }
        }
        if (_toPath == nil) {
            errors = [self addErrorMessage:[NSString stringWithFormat:@"no 'toPath' in %@.%@ property for %@ -> %@ mapping", NSStringFromClass(_parent.toType.type), self.toPathRoot, _fromPath, _toPath] errors:errors];
        }
    }
    return errors;
}


- (NSArray *)configure:(OXContext *)context
{
    if (context == nil)
        NSAssert1(NO, @"ERROR: invalid nil context parameter in 'configure:(OXContext *)' method call on mapper: %@", self);
    NSArray *errors = nil;
    if (!_isConfigured) {
        NSAssert(context.transform != nil, @"context.transform != nil");
        errors = [self verifyToTypeUsingSelfReflection:context errors:errors];
        if (!errors) {
            [self assignDefaultBlocks:context];
            _isConfigured = YES;
        }
    }
    return errors;
}

@end

//
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


