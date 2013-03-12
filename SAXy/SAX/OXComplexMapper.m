//
//  OXComplexMapper.m
//  SAXy OX - Object-to-XML mapping library
//
//  TODO inheritting from OXPathMapper seams to be overkill because we only use the factory block and fromType properties in practice.
//
//  Created by Richard Easterling on 2/10/13.
//

#import "OXComplexMapper.h"
#import "OXContext.h"
#import "OXProperty.h"


#pragma mark - OXComplexMapper


@implementation OXComplexMapper
{
    NSMutableArray *_pathMappers;
}

- (id)init
{
    if (self = [self initMapperWithEnum:OX_COMPLEX_MAPPER]) {
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@:%@ %@ <- %@", NSStringFromClass(self.parent.toType.type),  NSStringFromClass(self.toType.type), self.toPath, self.fromPath];
}

#pragma mark - batch

- (void)forEachPathMapper:(OXForEachPathMapperBlock)block
{
    if (_pathMappers)
        for(OXPathMapper *mapper in _pathMappers) {
            block(mapper);
        }
}

- (NSArray *)collectForEachPathMapper:(OXForEachPathMapperBlock)block
{
    if (!_pathMappers)
        return [NSArray array];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:[_pathMappers count]];
    for(OXPathMapper *mapper in _pathMappers) {
        id result = block(mapper);
        if (result)
            [results addObject:result];
    }
    return results;
}

- (id)findFirstMatch:(OXForEachPathMapperBlock)block
{
    if (_pathMappers)
        for(OXPathMapper *mapper in _pathMappers) {
            const id match = block(mapper);
            if (match)
                return match;
        }
    return nil;
}

#pragma mark - configure

- (void)assignDefaultBlocks:(OXContext *)context
{
    if (!self.factory) {
        self.factory = ^(NSString *path, OXContext *ctx) {
            OXPathMapper *mapper = ctx.currentMapper;
            return [[mapper.toType.type alloc] init];
        };
    }
    switch (self.toType.typeEnum) {
        case OX_COMPLEX: {
            //setter method
            if ( ! self.setter) {
                if (self.toTransform) {   // is there a source->target converter?
                    self.setter = ^(NSString *key, id value, id target, OXContext *ctx) {
                        OXPathMapper *mapper = ctx.currentMapper;
                        id obj = mapper.toTransform(value, ctx); //convert from->to instance
                        [target setValue:obj forKey: key];  //set using KVC
                    };
                } else {
                    self.setter = ^(NSString *key, id value, id target, OXContext *ctx) {
                        [target setValue:value forKey: key];  //set using KVC
                    };
                }
            }
            //getter method
            if ( ! self.getter) {
                if (self.fromTransform) {   // is there a target->source converter?
                    self.getter = ^(NSString *key, id target, OXContext *ctx) {
                        id value = [target valueForKey:key];
                        OXPathMapper *mapper = ctx.currentMapper;
                        return value==nil ? nil : mapper.fromTransform(value, ctx);
                    };
                } else {
                    self.getter = ^(NSString *key, id target, OXContext *ctx) {
                        return [target valueForKey:key];   //call KVC getter
                    };
                }
            }
            break;
        }
        default:
            break;
    }
}

- (void)addMissingProperties:(OXContext *)context
{
    if (!self.lock) {
        NSSet *ignoreSet = [NSSet setWithArray:[self collectForEachPathMapper:^(OXPathMapper *mapper) { return mapper.toPathRoot; }]];
        ignoreSet = [ignoreSet setByAddingObjectsFromSet:_ignoreProperties];
        for(OXProperty *property in self.toType.properties) {
            if ( ! [ignoreSet containsObject:property.name] ) {
                switch (property.type.typeEnum) {
                    case OX_CONTAINER: {
                        //unknown source type, child type and source path:
                        [self addPathMapper:[[OXPathMapper alloc] initMapperToType:property.type toPath:property.name fromType:nil fromPath:nil]];
                        break;
                    }
                    case OX_SCALAR: {
                        //assume string source type and identical paths:
                        [self addPathMapper:[[OXPathMapper alloc] initMapperToScalar:property.type.scalarEncoding toPath:property.name fromClass:[NSString class] fromPath:property.name]];
                    }
                    case OX_ATOMIC: {
                        //assume string source type and identical paths:
                        OXType *stringType = [OXType cachedType:[NSString class]];
                        [self addPathMapper:[[OXPathMapper alloc] initMapperToType:property.type toPath:property.name fromType:stringType fromPath:property.name]];
                        break;
                    }
                    case OX_COMPLEX: {
                        //unknown source type and source path:
                        [self addPathMapper:[[OXPathMapper alloc] initMapperToType:property.type toPath:property.name fromType:nil fromPath:nil]];
                        break;
                    }
                    default:
                        break;
                }
            }
        }
    }
}

- (NSArray *)configure:(OXContext *)context
{
    if (context == nil)
        NSAssert1(NO, @"ERROR: invalid nil context parameter in 'configure:(OXContext *)' method call on mapper: %@", self);
    NSArray *errors = nil;
    if (!self.isConfigured) {
//        if ([NSStringFromClass(self.toType.type) isEqualToString:@"CommercialItem"])
//             NSLog(@"CommercialItem");
        [self assignDefaultBlocks:context];
        [self addMissingProperties:context];
        for(OXPathMapper *mapper in _pathMappers) {
//            if ([@"contactAttempsW" isEqualToString:mapper.toPath])
//                NSLog(@"contactAttempsW");
            NSArray *subErrors = [mapper configure:context];
//            if (mapper.factory == nil && mapper.toType.typeEnum != OX_ATOMIC && mapper.toType.typeEnum != OX_SCALAR)
//                NSAssert1(NO, @"factory block should never be nil, assignDefaultBlocks:context not being called for mapper: %@", mapper);
            errors = subErrors == nil ? errors : (errors ? [subErrors arrayByAddingObjectsFromArray:errors] : subErrors);
        }
        self.isConfigured = YES;
    }
    return errors;
}

#pragma mark - properties

@dynamic pathMappers;
- (NSArray *)pathMappers
{
    return _pathMappers;
}

- (OXComplexMapper *)addPathMapper:(OXPathMapper *)pathMapper
{
    if (_pathMappers == nil) {
        _pathMappers = [NSMutableArray array];
    }
    [_pathMappers addObject:pathMapper];
    pathMapper.parent = self;
    return self;
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
