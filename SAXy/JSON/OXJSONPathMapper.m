//
//  OXJSONPathMapper.m
//  SAXy
//
//  Created by Richard Easterling on 3/4/13.
//

#import "OXJSONPathMapper.h"

@implementation OXJSONPathMapper

#pragma mark - constructors

- (id)initPath:(NSString *)path type:(Class)fromType property:(NSString *)property propertyType:(Class)propertyType
{
    if (self = [super initMapperToClass:propertyType toPath:property fromClass:fromType fromPath:path]) {
        if (property == nil) {
            self.toPath = path;
        }
        if (fromType == nil) {
            self.fromType = [OXType cachedType:[NSString class]];    //TODO make this configurable?
        }
    }
    return self;
}

- (id)initPath:(NSString *)path scalar:(const char *)toEncodedType property:(NSString *)property fromType:(Class)fromType
{
    if (self = [super initMapperToScalar:toEncodedType toPath:property fromClass:fromType fromPath:path]) {
        if (property == nil) {
            self.toPath = path;
        }
        if (fromType == nil) {
            self.fromType = [OXType cachedType:[NSString class]];   //TODO make this configurable?
        }
    }
    return self;
}

+ (id)path:(NSString *)path
{
    return [[OXJSONPathMapper alloc] initPath:path type:nil property:nil propertyType:nil];
}

+ (id)path:(NSString *)path type:(Class)type
{
    return [[OXJSONPathMapper alloc] initPath:path type:type property:nil propertyType:nil];
}

+ (id)path:(NSString *)path property:(NSString *)property
{
    return [[OXJSONPathMapper alloc] initPath:path type:nil property:property propertyType:nil];
}

+ (id)path:(NSString *)path type:(Class)type property:(NSString *)property propertyType:(Class)propertyType
{
    return [[OXJSONPathMapper alloc] initPath:path type:type property:property propertyType:propertyType];
}

+ (id)path:(NSString *)path scalar:(const char *)encodedType property:(NSString *)property fromType:(Class)fromType
{
    return [[OXJSONPathMapper alloc] initPath:path scalar:encodedType property:property fromType:fromType];
}

#pragma mark - builder

- (OXJSONPathMapper *)factory:(OXFactoryBlock)factory
{
    self.factory = factory;
    return self;
}

- (OXJSONPathMapper *)setter:(OXSetterBlock)setter
{
    self.setter = setter;
    return self;
}

- (OXJSONPathMapper *)getter:(OXGetterBlock)getter
{
    self.getter = getter;
    return self;
}

- (OXJSONPathMapper *)toTransform:(OXTransformBlock)toTransform
{
    self.toTransform = toTransform;
    return self;
}

- (OXJSONPathMapper *)fromTransform:(OXTransformBlock)fromTransform
{
    self.fromTransform = fromTransform;
    return self;
}

- (OXJSONPathMapper *)enumerator:(OXEnumerationBlock)enumerator
{
    self.enumerator = enumerator;
    return self;
}

- (OXJSONPathMapper *)appender:(OXSetterBlock)appender
{
    self.appender = appender;
    return self;
}

- (OXJSONPathMapper *)isVirtualProperty
{
    self.virtualProperty = YES;
    return self;
}

- (OXJSONPathMapper *)formatter:(NSString *)formatterName
{
    [self setValue:formatterName forKey:@"formatterName"];  //readonly end-run
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
