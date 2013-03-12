//
//  OXJSONReader.m
//  SAXy
//
//  Created by Richard Easterling on 3/4/13.
//

#import "OXJSONReader.h"
#import "OXContext.h"
#import "OXJSONObjectMapper.h"
#import "OXJSONPathMapper.h"
#import "OXUtil.h"


@implementation OXJSONReader
{
    BOOL _logMapping;
    NSJSONReadingOptions _readingOptions;
}

#pragma mark - constructor

- (id)initWithMapper:(OXJSONMapper *)mapper context:(OXContext *)context
{
    if ((self = [super init])) {
        _mapper = mapper;
        _context = context ? context : [[OXContext alloc] init];
        _readingOptions = 0;
    }
    return self;
}

+ (id)readerWithMapper:(OXJSONMapper *)mapper context:(OXContext *)context
{
    return [[OXJSONReader alloc] initWithMapper:mapper context:context];
}

+ (id)readerWithMapper:(OXJSONMapper *)mapper
{
    return [[OXJSONReader alloc] initWithMapper:mapper context:nil];
}

#pragma mark - builder
- (OXJSONReader *)readingOptions:(NSJSONReadingOptions)readingOptions
{
    _readingOptions = readingOptions;
    return self;
}


#pragma mark - utility

- (NSArray *)addError:(NSError *)error
{
    _errors = (_errors == nil) ? [NSArray arrayWithObject:error] : [_errors arrayByAddingObject:error];
    return _errors;
}

- (NSArray *)addErrorMessage:(NSString *)errorMessage
{
    NSError *error = [NSError errorWithDomain:@"com.outsourcecafe.ox" code:99 userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    return [self addError:error];
}

#pragma mark - reader


- (id)read:(NSDictionary *)json objectMapper:(OXJSONObjectMapper *)objMapper
{
    if (json == nil)
        return nil;
    if ( ! [json isKindOfClass:[NSDictionary class]] ) {
        [self addErrorMessage:[NSString stringWithFormat:@"Expecting NSDictionary parameter type, not %@ for %@ read mapping", NSStringFromClass([json class]), objMapper]];
        return nil;
    }
    id parent = nil;
    if (objMapper) {
        [_context.mapperStack push:objMapper];
        _context.currentMapper = objMapper;
        if (objMapper.factory == nil)
            NSAssert1(objMapper.factory, @"ERROR: factory is not set for OXJSONObjectMapper: %@", objMapper);
        parent = objMapper.factory(objMapper.toPath, _context);
        if (_logMapping) NSLog(@"create %@ - %@", objMapper.fromPath, NSStringFromClass([parent class]));
        [_context.instanceStack push:parent];
        for(NSString *propertyKey in objMapper.orderedPropertyKeys) {
            if ([propertyKey hasSuffix:@"website"])
                NSLog(@"website");
            OXJSONPathMapper *pathMapper = [objMapper objectMapperByProperty:propertyKey];
            _context.currentMapper = pathMapper;
            switch (pathMapper.toType.typeEnum) {
                case OX_CONTAINER: {  // handle list of child elements:
                    id sourceContainer = [json valueForKeyPath:pathMapper.fromPath];
                    if (!sourceContainer) {
                        if (_logMapping) NSLog(@"no source data %@ - %@.%@ = nil", pathMapper.fromPath, NSStringFromClass([parent class]), pathMapper.toPath);
                    } else if ( ! [sourceContainer isKindOfClass:[NSArray class]] ) {
                        if (_logMapping) NSLog(@"ERROR %@ - expected NSArray, not %@", pathMapper.fromPath, NSStringFromClass([sourceContainer class]));
                    } else {
                        for (id source in (NSArray *)sourceContainer) {
                            if ([source isMemberOfClass:[NSNull class]])
                                continue;
                            id target = nil;
                            switch (pathMapper.toType.containerChildType.typeEnum) {
                                case OX_COMPLEX: {
                                    OXJSONObjectMapper *childMapper = [_mapper objectMapperForClass:pathMapper.toType.containerChildType.type];
                                    if (childMapper == nil)
                                        NSAssert2(childMapper, @"ERROR, no objectMapper for %@ class in %@", NSStringFromClass(pathMapper.toType.containerChildType.type), pathMapper);
                                    target = [self read:source objectMapper:childMapper];
                                    _context.currentMapper = pathMapper;    //restore after recursive call
                                    break;
                                }
                                case OX_SCALAR:
                                case OX_ATOMIC: {
                                    if (pathMapper.toTransform) {
                                        target = pathMapper.toTransform(source, _context);
                                    } else {
                                        target = source;
                                    }
                                    break;
                                }
                                case OX_POLYMORPHIC:
                                default: {
                                    NSAssert2(NO, @"OXmlWriter does not yet support child typeEnum:%d in container mapper: %@", pathMapper.toType.containerChildType.typeEnum, pathMapper);
                                    break;
                                }
                            }
                            if (target && ![target isMemberOfClass:[NSNull class]]) {   //TODO add switch to control NSNull behavior?
                                if (_logMapping) NSLog(@"append %@ - %@.%@ += %@", pathMapper.fromPath, NSStringFromClass([parent class]), pathMapper.toPath, target);
                                pathMapper.appender(pathMapper.toPath, target, parent, _context);
                            } else {
                                if (_logMapping) NSLog(@"ignore %@ - %@.%@ += nil", pathMapper.fromPath, NSStringFromClass([parent class]), pathMapper.toPath);
                            }
                        }
                    }
                    break;
                }
                case OX_COMPLEX: {  // handle single child element:
                    OXJSONObjectMapper *childMapper = [_mapper objectMapperForClass:pathMapper.toType.type];
                    if (childMapper == nil)
                        NSAssert2(childMapper, @"ERROR, no objectMapper for %@ class in %@", NSStringFromClass(pathMapper.toType.type), pathMapper);
                    id source = [json valueForKeyPath:pathMapper.fromPath];
                    if (source && ![source isMemberOfClass:[NSNull class]]) {
                        id target = [self read:source objectMapper:childMapper];
                        if (target) {
                            _context.currentMapper = pathMapper;    //restore after recursive call
                            pathMapper.setter(pathMapper.toPath, target, parent, _context);
                            if (_logMapping) NSLog(@"assign %@ - %@.%@ = %@", pathMapper.fromPath, NSStringFromClass([parent class]), pathMapper.toPath, target);
                        } else {
                            if (_logMapping) NSLog(@"ignore %@ - %@.%@ = nil", pathMapper.fromPath, NSStringFromClass([parent class]), pathMapper.toPath);
                        }
                    } else {
                        if (_logMapping) NSLog(@"no source data %@ - %@.%@ = nil", pathMapper.fromPath, NSStringFromClass([parent class]), pathMapper.toPath);
                    }
                    break;
                }
                case OX_SCALAR:     // handle single-value (automic) element:
                case OX_ATOMIC: {
                    id source = [json valueForKeyPath:pathMapper.fromPath];
                    if (source && ![source isMemberOfClass:[NSNull class]]) {
                        if (_logMapping) NSLog(@"%@ - %@.%@=%@", pathMapper.fromPath, NSStringFromClass([parent class]), pathMapper.toPath, source);
                        pathMapper.setter(pathMapper.toPath, source, parent, _context);
                    } else {
                        if (_logMapping) NSLog(@"no source data %@ - %@.%@ = nil", pathMapper.fromPath, NSStringFromClass([parent class]), pathMapper.toPath);
                    }
                    break;
                }
                case OX_POLYMORPHIC:
                default: {
                    NSAssert2(NO, @"OXmlWriter does not yet support typeEnum:%d in mapper: %@", pathMapper.toType.typeEnum, pathMapper);
                    break;
                }
            }
            
        }
    }
    if (objMapper) {
        [_context.instanceStack pop];
        [_context.mapperStack pop];
    }
    return parent;
}

- (id)read:(id)jsonObject
{
    _logMapping = _context.logReaderStack;
    _errors = [self.mapper configure:_context]; //use reflections to create type-specific function blocks
    if (_errors) {
        if (_logMapping) {
            for(NSError *error in _errors) {
                NSLog(@"ERROR: %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
            }
        }
        return nil;
    } else {
        NSAssert(_mapper.rootMapper != nil, @"_mapper.rootMapper can't be nil in OXJSONReader");
        //SAXy rootMapper maps the result of the JSON read to the 'OXContext.result' property using the OX_ROOT_PATH key:
        [self read: @{ OX_ROOT_PATH : jsonObject } objectMapper:_mapper.rootMapper];  //wrap json in 'root' object and read
        return _errors ? nil : _context.result;
    }
}

- (id)readData:(NSData *)jsonData
{
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:jsonData options:_readingOptions error:&error];
    if (error) {
        //NSLog(@"error[%d]: %@", 2581, [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] substringFromIndex:2581]);
        return nil;
    } else {
        return [self read:json];
    }
}

- (id)readText:(NSString *)jsonText
{
    NSData *data = [jsonText dataUsingEncoding:NSUTF8StringEncoding];
    return [self readData:data];
}

- (id)readResourceFile:(NSString *)fileName
{
    NSData *data = [OXUtil readResourceFile:fileName];
    return [self readData:data];
}

@end




//- (id)readJSON:(NSDictionary *)json objectMapper:(OXJSONObjectMapper *)objMapper
//{
//    //id parentObject = [_context.instanceStack peek];
//    [_context.mapperStack push:objMapper];
//    _context.currentMapper = objMapper;
//    if (objMapper.factory == nil)
//        NSAssert1(objMapper.factory, @"ERROR: factory is not set for OXJSONObjectMapper: %@", objMapper);
//    NSObject *parent = objMapper.factory(objMapper.toPath, _context);
//    [_context.instanceStack push:parent];
//    for(NSString *propertyKey in objMapper.orderedPropertyKeys) {
//        OXJSONPathMapper *pathMapper = [objMapper objectMapperByProperty:propertyKey];
//        switch (pathMapper.toType.typeEnum) {
//            case OX_CONTAINER: {  // handle list of child elements:
////                id<NSFastEnumeration> enumeration = pathMapper.enumerator(childData, _context);
////                for(id itemData in enumeration) {
////                    switch (pathMapper.toType.containerChildType.typeEnum) {
////                        case OX_COMPLEX: {
////                            [self readJSON:itemData objectMapper:nil];
////                            break;
////                        }
////                        case OX_SCALAR:
////                        case OX_ATOMIC: {
////                            pathMapper.setter(pathMapper.fromPath, childData, parent, _context);
////                            break;
////                        }
////                        case OX_POLYMORPHIC:
////                        default: {
////                            NSAssert2(NO, @"OXmlWriter does not yet support child typeEnum:%d in container mapper: %@", pathMapper.toType.containerChildType.typeEnum, pathMapper);
////                            break;
////                        }
////                    }
////                }
//                break;
//            }
//            case OX_COMPLEX: {  // handle single child element:
//                OXJSONObjectMapper *childMapper = [_mapper objectMapperForClass:pathMapper.toType.type];
//                if (childMapper == nil)
//                    NSAssert2(childMapper, @"ERROR, no objectMapper for %@ class in %@", NSStringFromClass(pathMapper.toType.type), pathMapper);
//                id child = nil;//[self readJSON:childData objectMapper:childMapper];
//                if (child) {
//                    pathMapper.setter(pathMapper.toPath, child, parent, _context);
//                }
//                break;
//            }
//            case OX_SCALAR:     // handle single-value (automic) element:
//            case OX_ATOMIC: {
//                id child = [json valueForKeyPath:pathMapper.fromPath];
//                pathMapper.setter(pathMapper.toPath, child, parent, _context);
//                break;
//            }
//            case OX_POLYMORPHIC:
//            default: {
//                NSAssert2(NO, @"OXmlWriter does not yet support typeEnum:%d in mapper: %@", pathMapper.toType.typeEnum, pathMapper);
//                break;
//            }
//        }
//    } //for
//    [_context.instanceStack pop];
//    [_context.mapperStack pop];
//    return parent;
//}



//    } else { //no objMapper - run through json data looking for a matching objMapper
//        if ([json isKindOfClass:[NSDictionary class]]) {
//            NSDictionary *object = json;
//            NSLog(@"{");
//            for (id key in [object allKeys]) {
//                id value = [object objectForKey:key];
//                if ([value isKindOfClass:[NSNull class]]) {
//                    NSLog(@"%@ : nil", key);
//                } else if ([value isKindOfClass:[NSString class]]) {
//                    NSLog(@"%@ : \"%@\"", key, value);
//                } else if ([value isKindOfClass:[NSNumber class]]) {
//                    NSLog(@"%@ : %@", key, value);
//                } else {
//                    NSLog(@"%@ : ", key);
//                    OXJSONObjectMapper *childMapper = [_mapper objectMapperForClass:nil];
//                    [self read:value objectMapper:childMapper];
//                }
//            }
//            NSLog(@"}");
//        } else if ([json isKindOfClass:[NSArray class]]) {
//            NSArray *array = json;
//            NSLog(@"[");
//            NSInteger index = 0;
//            for(id value in array) {
//                if ([value isKindOfClass:[NSNull class]]) {
//                    NSLog(@"[%d] = nil", index);
//                } else if ([value isKindOfClass:[NSString class]]) {
//                    NSLog(@"[%d] = \"%@\"", index, value);
//                } else if ([value isKindOfClass:[NSNumber class]]) {
//                    NSLog(@"[%d] = %@", index, value);
//                } else {
//                    NSLog(@"[%d] = ", index);
//                    OXJSONObjectMapper *childMapper = [_mapper objectMapperForClass:nil];
//                    [self read:value objectMapper:childMapper];
//                }
//                index++;
//            }
//            NSLog(@"]");
//        }
//    }

//- (void)print:(id)json tab:(NSString *)tab out:(NSMutableString *)out
//{
//    NSString *tab2 = [NSString stringWithFormat:@"  %@", tab];
//    if ([json isKindOfClass:[NSDictionary class]]) {
//        NSDictionary *object = json;
//        [out appendString:@"{\n"];
//        for (id key in [object allKeys]) {
//            id value = [object objectForKey:key];
//            if ([value isKindOfClass:[NSNull class]]) {
//                [out appendFormat:@"%@\"%@\" : nil,\n", tab2, key];
//            } else if ([value isKindOfClass:[NSString class]]) {
//                [out appendFormat:@"%@\"%@\" : \"%@\",\n", tab2, key, value];
//            } else if ([value isKindOfClass:[NSNumber class]]) {
//                [out appendFormat:@"%@\"%@\" : %@,\n", tab2, key, value];
//            } else {
//                [out appendFormat:@"%@\"%@\" : ", tab2, key];
//                [self print:value tab:tab2 out:out];
//            }
//        }
//        [out appendFormat:@"%@}\n", tab];
//    } else if ([json isKindOfClass:[NSArray class]]) {
//        NSArray *array = json;
//        [out appendString:@"[\n"];
//        for(id value in array) {
//            if ([value isKindOfClass:[NSNull class]]) {
//                [out appendFormat:@"%@nil,\n", tab2];
//            } else if ([value isKindOfClass:[NSString class]]) {
//                [out appendFormat:@"%@\"%@\",\n", tab2, value];
//            } else if ([value isKindOfClass:[NSNumber class]]) {
//                [out appendFormat:@"%@%@,\n", tab2, value];
//            } else {
//                [out appendFormat:@"%@", tab2];
//                [self print:value tab:tab2 out:out];
//            }
//        }
//        [out appendFormat:@"%@]\n", tab];
//    }
//}

//- (id)readXml:(NSXMLParser *)parser
//{
//    [parser setDelegate:self];
//    [parser setShouldResolveExternalEntities:NO];
//    _errors = [self.mapper configure:_context]; //use reflections to create type-specific function blocks
//    if (_errors) {
//        if (_logStack) {
//            for(NSError *error in _errors) {
//                NSLog(@"ERROR: %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
//            }
//        }
//        return nil;
//    } else {
//        _namespaceAware = self.mapper.namespaceAware;
//        return [parser parse] ? _context.result : nil;  //if not successful, delegate is informed of error
//    }
//}


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

