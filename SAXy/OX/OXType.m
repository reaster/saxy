//
//  OXType2.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/27/13.
//

#import "OXType.h"
#import "OXProperty.h"
#import "OXContext.h"
#import "OXTransform.h"
#import "OXUtil.h"


@implementation OXType
{
    NSDictionary *_properties;
}

#pragma mark - constructors

- (id)initType:(Class)type typeEnum:(OXTypeEnum)typeEnum
{
    if (self = [self init]) {
        _type = type;
        _typeEnum = typeEnum;
    }
    return self;
}

+ (id)type:(Class)type typeEnum:(OXTypeEnum)typeEnum
{
    return [[OXType alloc] initType:type typeEnum:typeEnum];
}

- (id)initScalarType:(Class)type scalarEncoding:(const char *)scalarEncoding
{
    if (self = [self init]) {
        _type = type ? type : [NSNumber class]; //if not specified, use NSNumber
        _typeEnum = OX_SCALAR;
        _scalarEncoding = scalarEncoding;
    }
    return self;
}

+ (id)scalarType:(Class)typeWrapper scalarEncoding:(const char *)scalarEncoding
{
    return [[OXType alloc] initScalarType:typeWrapper scalarEncoding:scalarEncoding];
}


- (id)initTypeContainer:(Class)type containing:(Class)childType
{
    if (self = [self init]) {
        _type = type;
        //don't use cachedTypes for containers if childType is not NSObject
        _typeEnum = OX_CONTAINER;
        if (childType) {
            _containerChildType = [OXType type:childType typeEnum:[OXType guessTypeEnumFromClass:childType]];
//        } else {
//            _containerChildType = [OXType type:[NSObject class] typeEnum:[OXType guessTypeEnumFromClass:[NSObject class]]];
        }
    }
    return self;
}

+ (id)typeContainer:(Class)type containing:(Class)childType
{
    return [[OXType alloc] initTypeContainer:type containing:childType];
}

- (id)initWithType:(Class)type typeEnum:(OXTypeEnum)typeEnum
{
    if (self = [super init]) {
        _type = type;
        _typeEnum = typeEnum;
    }
    return self;
}

#pragma mark - caches

+ (OXType *)cachedScalarType:(const char *)encodedType
{
    if (encodedType == Nil)
        return nil;
    static NSMutableDictionary *_scalarTypeCache;
    if (_scalarTypeCache == nil)
        _scalarTypeCache = [NSMutableDictionary dictionaryWithCapacity:21];
    NSString *key = [[NSString alloc] initWithUTF8String:encodedType];
    OXType *result = [_scalarTypeCache objectForKey:key];
    if (result == nil) {
        result = [OXType scalarType:[NSNumber class] scalarEncoding:encodedType];
        [_scalarTypeCache setObject:result forKey:key];
    }
    return result;
}

+ (OXType *)cachedType:(Class)type
{
    if (type == nil) // || [type isSubclassOfClass:[NSValue class]])          //don't cache scalar wrapper - needs a special key - use cachedScalarType
        return nil;
    static NSMutableDictionary *_typeCache;
    if (_typeCache == nil)
        _typeCache = [NSMutableDictionary dictionaryWithCapacity:21];
    NSString *key = NSStringFromClass(type);
    OXType *result = [_typeCache objectForKey:key];
    if (result == nil) {
        OXTypeEnum typeEnum = [OXType guessTypeEnumFromClass:type];
        result = [[OXType alloc] initWithType:type typeEnum:typeEnum];
        [_typeCache setObject:result forKey:key];
    }
    return result;
}

#pragma mark - public

+ (OXTypeEnum)guessTypeEnumFromClass:(Class)type
{
//    if ([type isSubclassOfClass:[NSValue class]]) {   //can't treat as scalar without encoding data
//        return OX_SCALAR;
//    } else
    if ([OXUtil knownSimpleType:type] ) {
        return OX_ATOMIC;
    } else if ([OXUtil knownCollectionType:type]) {
        return OX_CONTAINER;
    } else {
        return OX_COMPLEX;
    }
}

- (NSString *)description
{
    switch (_typeEnum) {
        case OX_SCALAR:
            return [OXUtil scalarString:_scalarEncoding];
        case OX_CONTAINER:
            return [NSString stringWithFormat:@"%@<%@>", NSStringFromClass(_type), _containerChildType];
        case OX_ATOMIC:
        case OX_COMPLEX:
        case OX_POLYMORPHIC:
        default:
            return [NSString stringWithFormat:@"%@ *", NSStringFromClass(_type)];
    }
}

#pragma mark - properties

@dynamic properties;
- (NSDictionary *)properties
{
    if (!_propertiesLoaded) {
        NSMutableDictionary *__properties = [NSMutableDictionary dictionary];
        [OXUtil propertyInspectionForClass:self.type withBlock:^(NSString *propertyName, Class propertyClass, const char *attributes) {
            const char *encodedType = attributes ? strchr(attributes, 'T') : "T@";
            BOOL isScalar = (encodedType[1] != '@');
            OXType *type = nil;
            if (isScalar) {
                type = [OXType scalarType:nil scalarEncoding:attributes];
                //type.scalarEncoding = attributes;
                //type.typeEnum = OX_SCALAR;
            } else if ([OXUtil knownCollectionType:propertyClass]) {
                //TODO support use of NSClassDescription and toManyRelationshipKeys in OSX?
                type = [OXType typeContainer:propertyClass containing:nil];
                //type.containerChildType = [[OXType alloc] initWithType:[NSObject class] typeEnum:OX_POLYMORPHIC];;
                //type.typeEnum = OX_CONTAINER;
            } else if ( ! [OXUtil knownSimpleType:propertyClass] ) {
                type = [OXType type:propertyClass typeEnum:OX_COMPLEX];
            } else {
                type = [OXType type:propertyClass typeEnum:OX_ATOMIC];
            }
            //type.type = propertyClass;
            OXProperty *prop = [OXProperty property:propertyName type:type];
            [__properties setValue:prop forKey:prop.name];
            //NSLog(@"%@ %@ (%s)->%d", propertyClass, propertyName, attributes, type.typeEnum);
        }];
        _properties = [__properties copy];
        _propertiesLoaded = YES;
    }
    return _properties;
}

- (void)setProperties:(NSDictionary *)properties
{
    _properties = properties;
    _propertiesLoaded = YES;
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
