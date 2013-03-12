//
//  OXJSONWriter.m
//  SAXy
//
//  Created by Richard Easterling on 3/8/13.
//

#import "OXJSONWriter.h"
#import "OXJSONMapper.h"
#import "OXJSONObjectMapper.h"
#import "OXJSONPathMapper.h"


@implementation OXJSONWriter
{
    NSJSONWritingOptions _writingOptions;
    BOOL _logMapping;
}

#pragma mark - constructors

- (id)initWriterWithMapper:(OXJSONMapper *)mapper context:(OXContext *)context
{
    if (self = [super init]) {
        _mapper = mapper;
        _context = context ? context : [[OXContext alloc] init];
        _writingOptions = 0;
    }
    return self;
}

+ (id)writerWithMapper:(OXJSONMapper *)mapper context:(OXContext *)context
{
    return [[OXJSONWriter alloc] initWriterWithMapper:mapper context:context];
}

+ (id)writerWithMapper:(OXJSONMapper *)mapper
{
    return [[OXJSONWriter alloc] initWriterWithMapper:mapper context:nil];
}

#pragma mark - builder
- (OXJSONWriter *)writingOptions:(NSJSONWritingOptions)writingOptions
{
    _writingOptions = writingOptions;
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

#pragma mark - writer

- (NSDictionary *)write:(id)object objectMapper:(OXJSONObjectMapper *)objMapper
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[objMapper.pathMappers count]];
    for(OXJSONPathMapper *pathMapper in objMapper.pathMappers) {
        _context.currentMapper = pathMapper;
        switch (pathMapper.toType.typeEnum) {
            case OX_ATOMIC: 
            case OX_SCALAR: {
//                if ( [pathMapper.fromPath hasSuffix:@"website"] )
//                    NSLog(@"website");
                id target = pathMapper.getter(pathMapper.toPath, object, _context);
                if (target) {   
                    if ([pathMapper.fromPath rangeOfString:@"."].location == NSNotFound) {      //single KVC path?
                        [dict setObject:target forKey:pathMapper.fromPath];         
                    } else {                                                                    //multi-segment KVC path
                        NSArray *paths = [pathMapper.fromPath componentsSeparatedByString:@"."];
                        NSString *leafPath = pathMapper.fromPathLeaf;
                        NSMutableDictionary *parentDict = dict;
                        for (NSString *childPath in paths) {
                            if ([childPath isEqualToString:leafPath]) {
                                [parentDict setObject:target forKey:childPath];
                            } else {
                                NSMutableDictionary *childDict = [parentDict objectForKey:childPath];
                                if (childDict == nil) {
                                    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
                                    [parentDict setObject:childDict forKey:childPath];
                                }
                                parentDict = childDict;
                            }
                        }
                    }
                }
                break;
            }
            case OX_COMPLEX: {
                id source = pathMapper.getter(pathMapper.toPath, object, _context);
                if (source) {
                    OXJSONObjectMapper *childObjectMapper = [_mapper objectMapperForClass:pathMapper.toType.type];
                    NSDictionary *target = [self write:source objectMapper:childObjectMapper];
                    if (target && [target count] > 0) {
                        [dict setObject:target forKey:pathMapper.fromPath];
                    }
                }
                break;
            }
            case OX_CONTAINER: {
                id sourceContainer = pathMapper.getter(pathMapper.toPath, object, _context);
                if (sourceContainer) {
                    NSMutableArray *targetArray = [NSMutableArray arrayWithCapacity:[sourceContainer count]];
                    id target = nil;
                    for (id source in pathMapper.enumerator(sourceContainer, _context)) {
                        switch (pathMapper.toType.containerChildType.typeEnum) {
                            case OX_COMPLEX: {
                                OXJSONObjectMapper *childMapper = [_mapper objectMapperForClass:pathMapper.toType.containerChildType.type];
                                if (childMapper == nil) {
                                    [self addErrorMessage:[NSString stringWithFormat:@"no objectMapper for %@ class in %@", NSStringFromClass(pathMapper.toType.containerChildType.type), pathMapper]];
                                    return nil;
                                }
                                target = [self write:source objectMapper:childMapper];
                                _context.currentMapper = pathMapper;
                                break;
                            }
                            case OX_SCALAR:
                            case OX_ATOMIC: {
                                if (pathMapper.fromTransform) {
                                    target = pathMapper.fromTransform(source, _context);
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
                        if (target) {
                            [targetArray addObject:target];
                        }
                    } //for 
                    if ([targetArray count] > 0) {
                        [dict setObject:targetArray forKey:pathMapper.fromPath];
                    }
                }//sourceContainer
                break;
            }
            case OX_POLYMORPHIC: {
                ;
                NSAssert2(NO, @"OXJSONWriter does not yet support typeEnum:%d in mapper: %@", pathMapper.toType.typeEnum, pathMapper);
                break;
            }
            default:
                break;
        }
    }
    return dict;
}

- (NSData *)writeAsData:(id)object
{
    _logMapping = _context.logReaderStack;
    _errors = [ _mapper configure:_context];
    if (_errors == nil) {
        [_context setValue:object forKey:@"result"];
        NSDictionary *jsonResultWrapper = [self write:_context objectMapper:_mapper.rootMapper];
        id json = jsonResultWrapper ? [jsonResultWrapper objectForKey:OX_ROOT_PATH] : nil;
        if (json) {
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:_writingOptions error:&error];
            if (error) {
                [self addError:error];
            } else {
                return jsonData;
            }
        }
    }
    if (_logMapping) {
        for(NSError *error in _errors) {
            NSLog(@"ERROR: %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
        }
    }
    return nil;
}

- (NSString *)writeAsText:(id)object
{
    NSData *jsonData = [self writeAsData:object];
    return jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
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
