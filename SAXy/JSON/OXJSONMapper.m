//
//  OXJSONMapper.m
//  SAXy
//
//  Created by Richard Easterling on 3/4/13.
//

#import "OXJSONMapper.h"
#import "OXJSONObjectMapper.h"
#import "OXUtil.h"


@implementation OXJSONMapper
{
    NSMutableDictionary *_mappersIndexedByClass;
    NSMutableDictionary *_mappersIndexedByToPath;
    OXContext *_context;
}

#pragma mark - constructor

+ (id)mapper
{
    return [[OXJSONMapper alloc] init];
}


- (void)addObjectMapper:(OXJSONObjectMapper *)mapper
{
    [mapper setValue:self forKey:@"parentMapper"];  //end-run around readonly property: mapper.parentMapper = self;
    //sanity checks:
    NSString *keyTag = mapper.fromPathLeaf;
    if (keyTag == nil)
        NSAssert(NO, @"%@ -> %@ has no fromPath", NSStringFromClass(mapper.fromType.type), NSStringFromClass(mapper.toType.type));
    if (_mappersIndexedByToPath == nil) {
        _mappersIndexedByToPath = [NSMutableDictionary dictionary];
    }
    OXJSONObjectMapper *existingMapper = [_mappersIndexedByToPath objectForKey:keyTag];
    if (existingMapper)
        mapper.next = existingMapper;   //link mappers pointing to the same tag
    [_mappersIndexedByToPath setObject:mapper forKey:keyTag];
    if ([ OX_ROOT_PATH isEqualToString:mapper.fromPathRoot]) {
        _rootMapper = mapper;
    }
    if (_mappersIndexedByClass == nil) {
        _mappersIndexedByClass = [NSMutableDictionary dictionary];
    }
    [_mappersIndexedByClass setObject:mapper forKey:NSStringFromClass(mapper.toType.type)]; //reverse mappings
}

- (OXJSONMapper *)objects:(NSArray *)objects
{
    _mappersIndexedByClass = [NSMutableDictionary dictionaryWithCapacity:[objects count]];
    for(OXJSONObjectMapper *mapper in objects) {
        [self addObjectMapper:mapper];
    }
    return self;
}


#pragma mark - lookup

- (OXJSONObjectMapper *)matchObject:(OXContext *)context
{
    return nil; //[self mapperFromPathStack:context.pathStack];
}

- (OXJSONObjectMapper *)objectMapperForPath:(NSString *)path
{
    NSString *keyTag = [OXUtil lastSegmentFromPath:path separator:'.']; 
    OXJSONObjectMapper *existingMapper = [_mappersIndexedByToPath objectForKey:keyTag];
    //TODO loop through next properties - finding best match
    return existingMapper;
}

- (OXJSONObjectMapper *)objectMapperForClass:(Class)type
{
    NSString *className = NSStringFromClass(type);
    OXJSONObjectMapper *mapper = [_mappersIndexedByClass objectForKey:className];
    if (mapper == nil) {
        //build a mapper on-the-fly
        mapper = [OXJSONObjectMapper objectClass:type];
        if (mapper != nil) {
            [self addObjectMapper:mapper];
        }
    }
    if ( ! mapper.isConfigured && _context) {
        [mapper configure:_context];
    }
    return mapper;
}


#pragma mark - configure

- (NSArray *)configure:(OXContext *)context
{
    NSArray *errors = nil;
    if ( ! _isConfigured) {
        _context = context;
        for(OXPathMapper *mapper in [_mappersIndexedByClass allValues]) {
            NSArray *subErrors = [mapper configure:context];
            errors = subErrors == nil ? errors : (errors ? [subErrors arrayByAddingObjectsFromArray:errors] : subErrors);
        }
        _isConfigured = YES;
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

