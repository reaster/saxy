//
//  OXmlContext.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/15/13.
//

#import "OXmlContext.h"
#import "NSMutableArray+OXStack.h"


@implementation OXmlContext
{
    NSMutableArray *_mappingTypeStack;
    NSMutableString *_currentStringValue;
    
    NSString *_cachedImmutableText;
}

static NSArray *_mappingTypeWrappers;

+ (void)initialize
{
    //create constants for OXSAXActionEnum
    _mappingTypeWrappers = @[                                                   //avoid allocating NSNumbers over and over again
                             [NSNumber numberWithInt:OX_SAX_UNDEFINED_ACTION],
                             [NSNumber numberWithInt:OX_SAX_VALUE_ACTION],
                             [NSNumber numberWithInt:OX_SAX_OBJECT_ACTION],
                             [NSNumber numberWithInt:OX_SAX_SKIP_ACTION]
                             ];
    for (int typeEnum=0; typeEnum < [_mappingTypeWrappers count]; typeEnum++) { //need a sanity check
        NSAssert1(typeEnum == [[_mappingTypeWrappers objectAtIndex:typeEnum] intValue], @"_mappingTypeWrappers out-of-sync with OXSAXActionEnum[%d]", typeEnum);
    }
}


- (id)init
{
    if ((self = [super init])) {
        _mappingTypeStack = [[NSMutableArray alloc] init];
        _currentStringValue = [[NSMutableString alloc] initWithCapacity:250];
        //_namespaces = [[NSMutableDictionary alloc] init];
        _attributeFilterBlock = ^(NSString *attrName, NSString *attrValue) {
            NSString *value = [attrValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            return (value && [value length] > 0 && ![attrName hasPrefix:@"xmlns"]) ? value : nil; //ignore nil, empty and xml-namespace attributes
        };
        _elementFilterBlock = ^(NSString *elementName, NSString *elementValue) {
            NSString *value = [elementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            return (value && [value length] > 0) ? value : nil; //ignore nil and empty elements
        };

    }
    return self;
}

- (void)reset
{
    [super reset];
    [_mappingTypeStack clear];
    [self clearText];
}

#pragma mark - OXSAXActionEnum stack

- (void)pushMappingType:(OXSAXActionEnum)mappingType
{
    //[_mappingTypeStack addObject:[NSNumber numberWithInt:mappingType]]; generates a lot of heap waste
    [_mappingTypeStack addObject:_mappingTypeWrappers[mappingType]];
}
- (OXSAXActionEnum)popMappingType
{
    OXSAXActionEnum t = [self peekMappingType]; [_mappingTypeStack removeLastObject]; return t;
}
- (OXSAXActionEnum)peekMappingType
{
    return (OXSAXActionEnum)[[_mappingTypeStack lastObject] intValue];
}
- (OXSAXActionEnum)peekMappingTypeAtIndex:(NSInteger)index
{
    NSInteger reverseIndex = [_mappingTypeStack count] - (index + 1);
    return reverseIndex < 0 ? OX_SAX_SKIP_ACTION: [[_mappingTypeStack objectAtIndex:reverseIndex] integerValue];
}

#pragma mark - element body text
- (NSString *)text
{
    //optimzied to avoid allocating extra string copies
    if (_cachedImmutableText) {
        return _cachedImmutableText;
    } else {
         return [_currentStringValue length] == 0 ? nil : [_currentStringValue copy];   
    }
}

- (void)clearText
{
    [_currentStringValue setString:@""];
    _cachedImmutableText = nil;
}

- (void)appendText:(NSString *)text
{
    //optimzied to avoid allocating extra string copies 
    if (_cachedImmutableText) { //2nd hit - can't avoid using NSMutableString (_currentStringValue)
        [_currentStringValue appendString:_cachedImmutableText];
        _cachedImmutableText = nil;
        [_currentStringValue appendString:text];
    } else {
        if ([_currentStringValue length] == 0) {
            _cachedImmutableText = text;            //most comman/efficient case
        } else {
            [_currentStringValue appendString:text];
        }
    }
}

#pragma mark - debug
- (NSString *)tagPath
{
    if ([self.pathStack count] == 1) {
        return OX_ROOT_PATH;
    } else {
        NSMutableString *_tagPath = [NSMutableString string];
        for(NSString *tag in self.pathStack) {
            if ( ! [tag isEqualToString:OX_ROOT_PATH] ) { //skip root node
                [_tagPath appendFormat:@"/%@", tag];
            }
        }
        return _tagPath;
    }
}

+ (id)contextWithPathStack:(NSArray *)tagStack
{
    OXmlContext *ctx = [[OXmlContext alloc] init];
    for(NSString *tag in tagStack) {
        [ctx.pathStack push:tag];
    }
    return ctx;
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
