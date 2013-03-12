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

#pragma mark - OXSAXActionEnum stack

- (void)pushMappingType:(OXSAXActionEnum)mappingType
{
    [_mappingTypeStack addObject:[NSNumber numberWithInt:mappingType]];
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
    return [_currentStringValue copy];
}
- (void)clearText
{
    [_currentStringValue setString:@""];
}
- (void)appendText:(NSString *)text
{
    [_currentStringValue appendString:text];
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
