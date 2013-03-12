//
//  OXJSONObjectMapper.m
//  SAXy
//
//  Created by Richard Easterling on 3/4/13.
//

#import "OXJSONObjectMapper.h"

#import "OXJSONPathMapper.h"
#import "OXProperty.h"
#import "OXContext.h"
#import "OXUtil.h"

@interface OXJSONObjectMapper ()
- (void)resetIndexedMappers;
@end

@implementation OXJSONObjectMapper
{
    NSMutableDictionary *_mappersByToPathLeaf;
    NSMutableDictionary *_mappersByFromPathLeaf;
    NSArray *_orderedPropertyKeys;
}

#pragma mark - constructors


- (id)initObjectMapper:(NSString *)path toClass:(Class)type
{
    return [super initMapperToClass:type toPath:nil fromClass:nil fromPath:path];
}

+ (id)objectClass:(Class)toType
{
    return [[OXJSONObjectMapper alloc] initObjectMapper:OX_ANONYMOUS_XPATH toClass:toType];
}

+ (id)root
{
    return [[OXJSONObjectMapper alloc] initObjectMapper:OX_ROOT_PATH toClass:[OXContext class] ];
}

+ (id)rootPath:(NSString *)path
{
    OXJSONObjectMapper *rootMapper = [[OXJSONObjectMapper alloc] initObjectMapper:path toClass:[OXContext class]];
    NSAssert1([path hasPrefix:OX_ROOT_PATH], @"root element path must start with root node (/): %@", path);
    return rootMapper;
}

+ (id)rootClass:(Class)toType
{
    return [[OXJSONObjectMapper rootPath:OX_ROOT_PATH]
            path:OX_ROOT_PATH type:nil property:@"result" propertyType:toType];
}

+ (id)rootToManyClass:(Class)toType
{
    return [[OXJSONObjectMapper rootPath:OX_ROOT_PATH]
            path:OX_ROOT_PATH toMany:toType property:@"result"];
}

+ (id)rootPath:(NSString *)path type:(Class)toType
{
    NSString *leafPath = [OXUtil lastSegmentFromPath:path separator:'.']; 
    NSString *rootPath = [path substringToIndex:[path length] - [leafPath length]];
    return [[OXJSONObjectMapper rootPath:rootPath]
            path:leafPath type:nil property:@"result" propertyType:toType];
}

+ (id)rootPath:(NSString *)path toMany:(Class)toType
{
    NSString *leafPath = [OXUtil lastSegmentFromPath:path separator:'.'];
    NSString *rootPath = [path substringToIndex:[path length] - [leafPath length]];
    return [[OXJSONObjectMapper rootPath:rootPath]
            path:leafPath toMany:toType property:@"result"];
}


#pragma mark - utilities

- (BOOL)isRootElement
{
    return [self.toType.type isSubclassOfClass:[OXContext class]];
}

#pragma mark - properties

- (NSArray *)orderedPropertyKeys
{
    if (_orderedPropertyKeys == nil) {
        [self indexMappers];
    }
    return _orderedPropertyKeys;
}

#pragma mark - configure

- (void)configureRootMapper:(OXContext *)context    //TODO move to OXComplexMapper?
{
    self.factory = ^(NSString *path, OXContext *ctx){ return context; }; //just return existing context instance
    self.lock = YES;                                                        //don't map other context properties
    NSArray *propertyKeys = self.orderedPropertyKeys;
    NSInteger keyCount = propertyKeys ? [propertyKeys count] : 0;
    if (keyCount != 1)
        NSAssert2(NO, @"ERROR: root mapper (%@) must have a single path mapper child, not %d mappers", self.fromPath, keyCount);
    OXJSONPathMapper *rootProperty = [self objectMapperByProperty:[propertyKeys objectAtIndex:0]];
    NSAssert1(rootProperty != nil, @"rootProperty can't be nil in %@", self);
    rootProperty.toPath = @"result";                                        //fixed property in OXContext
    OXType *rootType = rootProperty.toType;                                 //verify or assign target type
    if (rootType.type == nil) {
        switch (rootType.typeEnum) {
            case OX_ATOMIC:
            case OX_SCALAR:
            case OX_COMPLEX:
                NSAssert1(NO, @"ERROR: root element type must be specified in %@ mapper", rootProperty);
                break;
            case OX_CONTAINER: {
                Class childType = rootProperty.toType.containerChildType.type;
                if (rootProperty.dictionaryKeyName) {
                    rootProperty.toType = [OXType typeContainer:[NSMutableDictionary class] containing:childType];
                } else {
                    rootProperty.toType = [OXType typeContainer:[NSMutableArray class] containing:childType];
                }
                break;
            }
            case OX_POLYMORPHIC:
            default:
                NSAssert1(NO, @"ERROR: polymorphic root element type not supported (yet) in %@ mapper", rootProperty);
                break;
        }
    }
    [rootProperty configure:context];
}

//override, replacing OXPathMapper with OXJSONPathMapper instances
- (void)addMissingProperties:(OXContext *)context
{
    if ([self isRootElement]) {
        [self configureRootMapper:context];
    } else if (!self.lock) {
        NSSet *ignoreSet = [NSSet setWithArray:[self collectForEachPathMapper:^(OXPathMapper *mapper) { return mapper.toPathRoot; }]];
        ignoreSet = [ignoreSet setByAddingObjectsFromSet:self.ignoreProperties];
        NSMutableArray *sortedKeys = [NSMutableArray arrayWithArray:[self.toType.properties allKeys]];
        [sortedKeys sortUsingSelector:@selector(compare:)];
        for(NSString *name in sortedKeys) {
            OXProperty *property = [self.toType.properties objectForKey:name];
            if ( ! [ignoreSet containsObject:name] ) {
                OXJSONPathMapper *simpleMapper = nil;
                switch (property.type.typeEnum) {
                    case OX_CONTAINER: {
                        //unknown source type, polymprphic child type (aka NSObject) and guess that path is singular form of property name:
                        NSString *singularTag = [OXUtil guessSingularNoun:name];
                        simpleMapper = [[OXJSONPathMapper alloc] initMapperToType:property.type toPath:name fromType:nil fromPath:singularTag];
                        break;
                    }
                    case OX_SCALAR: {
                        //assume NSString fromType, OX_XML_ELEMENT typeEnum and path == KVC key
                        simpleMapper = [OXJSONPathMapper path:name scalar:property.type.scalarEncoding property:name fromType:nil];
                    }
                    case OX_ATOMIC: {
                        //assume NSString fromType, OX_XML_ELEMENT typeEnum and path == KVC key
                        simpleMapper = [OXJSONPathMapper path:name type:nil property:name propertyType:property.type.type];
                        break;
                    }
                    case OX_COMPLEX: {
                        //unknown source type and source path:
                        simpleMapper = [[OXJSONPathMapper alloc] initMapperToType:property.type toPath:name fromType:nil fromPath:name];
                        break;
                    }
                    default:
                        break;
                }
                if (simpleMapper) {
                    [self addSimpleMapping:simpleMapper];
                }
            }
        }
    }
}


#pragma mark - builder pattern

- (OXJSONObjectMapper *)addSimpleMapping:(OXJSONPathMapper *)propertyMapping
{
    [super addPathMapper:propertyMapping];
    [self resetIndexedMappers];
    return self;
}

- (OXJSONObjectMapper *)pathMapper:(OXJSONPathMapper *)pathMapper
{
    return [self addSimpleMapping:pathMapper];
}

- (OXJSONObjectMapper *)path:(NSString *)path
{
    return [self addSimpleMapping: [OXJSONPathMapper path:path type:nil property:nil propertyType:nil]];
}

- (OXJSONObjectMapper *)paths:(NSArray *)paths
{
    for(NSString *path in paths) {
        [self path:path];
    }
    return self;
}

- (OXJSONObjectMapper *)pathMap:(NSDictionary *)pathToPropertyMap
{
    for(NSString *path in [pathToPropertyMap keyEnumerator]) {
        NSString *property = [pathToPropertyMap objectForKey:path];
        [self path:path property:property];
    }
    return self;
}

- (OXJSONObjectMapper *)path:(NSString *)path scalarType:(char const *)encodedType
{
    return [self addSimpleMapping: [OXJSONPathMapper path:path scalar:encodedType property:nil fromType:nil]];
}

- (OXJSONObjectMapper *)path:(NSString *)path type:(Class)fromType
{
    return [self addSimpleMapping: [OXJSONPathMapper path:path type:fromType property:nil propertyType:nil]];
}

- (OXJSONObjectMapper *)path:(NSString *)path property:(NSString*)property
{
    return [self addSimpleMapping: [OXJSONPathMapper path:path type:nil property:property propertyType:nil]];
}

- (OXJSONObjectMapper *)path:(NSString *)path type:(Class)fromType property:(NSString*)property
{
    return [self addSimpleMapping: [OXJSONPathMapper path:path type:fromType property:property propertyType:nil]];
}

- (OXJSONObjectMapper *)path:(NSString *)path type:(Class)fromType property:(NSString*)property propertyType:(Class)toType
{
    return [self addSimpleMapping: [OXJSONPathMapper path:path type:fromType property:property propertyType:toType]];
}

- (OXJSONObjectMapper *)path:(NSString *)path property:(NSString*)property scalarType:(char const *)encodedType
{
    return [self addSimpleMapping: [OXJSONPathMapper path:path scalar:encodedType property:property fromType:nil]];
}

- (OXJSONObjectMapper *)path:(NSString *)path type:(Class)fromType property:(NSString*)property scalarType:(char const *)encodedType
{
    return [self addSimpleMapping: [OXJSONPathMapper path:path scalar:encodedType property:property fromType:fromType]];
}

- (OXJSONObjectMapper *)path:(NSString *)path toMany:(Class)childType property:(NSString*)property containerType:(Class)containerType
{
    OXType *childOXType = [OXType typeContainer:containerType containing:childType];   //containerType ? containerType : [NSMutableArray class]
    OXJSONPathMapper *mapper = [OXJSONPathMapper path:path type:containerType property:property propertyType:nil];
    mapper.toType = childOXType;
    return [self addSimpleMapping:mapper];
}

- (OXJSONObjectMapper *)path:(NSString *)path toMany:(Class)childType property:(NSString*)property
{
    return [self path:path toMany:childType property:property containerType:nil];
}

- (OXJSONObjectMapper *)path:(NSString *)path toMany:(Class)childType
{
    OXJSONObjectMapper *mapper = [self path:path toMany:childType property:nil containerType:nil];
    mapper.toPath = mapper.fromPathLeaf;    //guess property name from path leaf: a/b/c -> c
    return mapper;
}

- (OXJSONObjectMapper *)path:(NSString *)path toMany:(Class)childType property:(NSString*)property dictionaryKey:(NSString *)keyProperty
{
    OXType *containerType = [OXType typeContainer:nil containing:childType];
    OXJSONPathMapper *mapper = [OXJSONPathMapper path:path type:nil property:property propertyType:nil];
    mapper.toType = containerType;
    mapper.dictionaryKeyName = keyProperty;
    return [self addSimpleMapping:mapper];
}

- (OXJSONObjectMapper *)objectFactory:(OXFactoryBlock)factory
{
    self.factory = factory;
    return self;
}

- (OXJSONObjectMapper *)lockMapping
{
    self.lock = YES;
    return self;
}

- (OXJSONObjectMapper *)ignoreProperties:(NSArray *)ignoreProperties
{
    self.ignoreProperties = self.ignoreProperties
    ? [self.ignoreProperties setByAddingObjectsFromArray:ignoreProperties]
    : [NSSet setWithArray:ignoreProperties];
    return self;
}

- (OXJSONObjectMapper *)ignorePaths:(NSArray *)paths    //redudent, no??
{
    self.ignoreProperties = [NSSet setWithArray:paths];
    return self;
}



#pragma mark - lookup

- (void)indexMappers
{
    _mappersByToPathLeaf = [NSMutableDictionary dictionaryWithCapacity:[self.pathMappers count]];
    _mappersByFromPathLeaf = [NSMutableDictionary dictionaryWithCapacity:[self.pathMappers count]];
    NSMutableArray *orderedKeys = [NSMutableArray arrayWithCapacity:[self.pathMappers count]];
    for (OXJSONPathMapper *mapper in self.pathMappers) {
        NSString *key = mapper.toPathLeaf;
        if (key) {
            [orderedKeys addObject:mapper.toPath];
            OXJSONPathMapper *existingMapper = [_mappersByToPathLeaf objectForKey:key];
            if (existingMapper)
                mapper.next = existingMapper;
            [_mappersByToPathLeaf setObject:mapper forKey:key];
        }
        key = mapper.fromPathLeaf;
        if (key) {
            OXJSONPathMapper *existingMapper = [_mappersByFromPathLeaf objectForKey:key];
            if (existingMapper)
                mapper.next = existingMapper;
            [_mappersByFromPathLeaf setObject:mapper forKey:key];
        }
    }
    _orderedPropertyKeys = [orderedKeys copy];
}

- (void)resetIndexedMappers
{
    _mappersByToPathLeaf = nil;
    _mappersByFromPathLeaf = nil;
    _orderedPropertyKeys = nil;
}

- (OXJSONPathMapper *)matchPathStack:(NSArray *)tagStack
{
    OXJSONPathMapper *mapper = nil; //[self elementMapperByTag:leaf nsURI:nsURI];
//    while (mapper) {
//        const OXPathLite *path = mapper.path;     //may be nil, path only created for complex paths
//        if ( path ? [path matches:tagStack] : [leaf isEqualToString:mapper.fromPath] ) {
//            break;
//        }
//        mapper = mapper.next;                       //iterate through other mappers with same leaf or wildcard
//    }
    return mapper;
}

- (OXJSONPathMapper *)objectMapperByProperty:(NSString *)propertyPath
{
    if (_mappersByToPathLeaf == nil) {
        [self indexMappers];
    }
    if ([propertyPath rangeOfString:@"."].location == NSNotFound) {
        return [_mappersByToPathLeaf objectForKey:propertyPath];        
    } else {
        NSString *leaf = [OXUtil lastSegmentFromPath:propertyPath separator:'.'];
        OXJSONPathMapper *mapper = [_mappersByToPathLeaf objectForKey:leaf];
        while (mapper) {
            if ([mapper.toPath isEqualToString:propertyPath])
                return mapper;
            mapper = mapper.next; 
        }
    }
    return nil;
}

- (OXJSONPathMapper *)objectMapperByPath:(NSString *)path;
{
    if (_mappersByFromPathLeaf == nil) {
        [self indexMappers];
    }
    return [_mappersByFromPathLeaf objectForKey:path];
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
