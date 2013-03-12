//
//  OXPathLite.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/25/13.
//

#import "OXPathLite.h"
#import "NSMutableArray+OXStack.h"
#import "OXUtil.h"
#import "OXPathMapper.h"    //just need OX_ROOT_PATH


@interface OXPathLite ()
- (NSArray *)parsePath:(NSString *)xpath separator:(NSString *)separator;
- (void)parseTokens:(NSArray *)tokens separator:(NSString *)separator;
@end


@implementation OXPathLite

@synthesize tagStack = _tagStack;
@synthesize tagTypeStack = _tagTypeStack;


#pragma mark - properties

@dynamic pathRoot;
- (NSString *)pathRoot
{
    return [_tagStack objectAtIndex:0];
}

@dynamic pathLeaf;
- (NSString *)pathLeaf
{
    return [_tagStack lastObject];
}

#pragma mark - constructors

- (id)initXPath:(NSString *)xpath pathSeparator:(NSString *)separator
{
    if (self = [super init]) {
        _tagStack = [[NSMutableArray alloc] init];
        _tagTypeStack = [[NSMutableArray alloc] init];
        NSArray *tokens = [self parsePath:xpath separator:separator];
        [self parseTokens:tokens separator:separator];
    }
    return self;
}

+ (id)xpath:(NSString *)xpath pathSeparator:(NSString *)separator
{
    return [[OXPathLite alloc] initXPath:xpath pathSeparator:separator];
}

+ (id)xpath:(NSString *)xpath
{
    return [[OXPathLite alloc] initXPath:xpath pathSeparator:OX_ROOT_PATH];
}



#pragma mark - utility

- (BOOL)rootInMatch
{
    return [[_tagTypeStack objectAtIndex:0] integerValue] == OXRootPathType;
}

- (NSArray *)parsePath:(NSString *)xpath separator:(NSString *)separator
{
    NSScanner *scanner = [NSScanner scannerWithString:xpath];
    NSString *token = nil;
    NSString *sep = nil;
    NSMutableArray *tempStack = [NSMutableArray array];
    while ([scanner isAtEnd] == NO) {
        [scanner scanUpToString:separator intoString:&token];
        token = [OXUtil trim:token];
        [scanner scanString:separator intoString:&sep];
        //NSLog(@"token:%@ %@, location:%d", token ? token : @"", sep ? sep : @"", [scanner scanLocation]);
        if (token)
            [tempStack push:token];
        if (sep)
            [tempStack push:sep];
        token = nil;
        sep = nil;
    }
    return tempStack;
}

- (void)parseTokens:(NSArray *)tokens separator:(NSString *)separator
{
    NSMutableArray *__tagStack = [NSMutableArray array];
    NSMutableArray *__tagTypeStack = [NSMutableArray array];
    NSEnumerator *tokenEnumerator = [tokens objectEnumerator];
    NSString *tok1 = [tokenEnumerator nextObject];
    NSString *tok2 = [tokenEnumerator nextObject];
    BOOL isRoot = YES;
    while (tok1) {
        BOOL isSep1 = [separator isEqualToString:tok1];
        BOOL isSep2 = [separator isEqualToString:tok2];
        if (isSep1 && isSep2) {                             //xpath double wildcard
            [__tagStack push:@"**"];
            [__tagTypeStack push:[NSNumber numberWithInteger:OXAnyAnyPathType]];
            tok1 = [tokenEnumerator nextObject];            //consume both tokens
            tok2 = [tokenEnumerator nextObject];
        } else if (isSep1) {                                
            if (isRoot) {                                   //root node
                [__tagStack push:OX_ROOT_PATH];
                [__tagTypeStack push:[NSNumber numberWithInteger:OXRootPathType]];
                tok1 = tok2;
                tok2 = [tokenEnumerator nextObject];
            } else {                                        //non-root separators - ignore
                tok1 = tok2;
                tok2 = [tokenEnumerator nextObject];
            }
        } else {                                            //none-separator token
            if ([tok1 isEqualToString:@"*"]) {              //wildcard
                [__tagStack push:@"*"];
                [__tagTypeStack push:[NSNumber numberWithInteger:OXAnyPathType]];
            } else if ([tok1 isEqualToString:@"**"]) {  //text node
                [__tagStack push:@"**"];
                [__tagTypeStack push:[NSNumber numberWithInteger:OXAnyAnyPathType]];
            } else if ([tok1 hasPrefix:@"@"]) {              //attribute
                NSString *attr = [tok1 substringWithRange:NSMakeRange(1,[tok1 length]-1)];
                [__tagStack push:attr];
                [__tagTypeStack push:[NSNumber numberWithInteger:OXAttributePathType]];
            } else if ([tok1 isEqualToString:@"text()"]) {  //text node
                [__tagStack push:@"."];
                [__tagTypeStack push:[NSNumber numberWithInteger:OXTextPathType]];
            } else {                                        //element token
                [__tagStack push:tok1];          
                [__tagTypeStack push:[NSNumber numberWithInteger:OXElementPathType]];
            }
            tok1 = tok2;
            tok2 = [tokenEnumerator nextObject];
        }
        isRoot = NO;
    }
    _tagStack = [__tagStack copy];
    _tagTypeStack = [__tagTypeStack copy];
}


#pragma mark - public

- (BOOL)hasRootTag
{
    NSNumber *tagTypeWrapper = [_tagTypeStack objectAtIndex:0];
    OXPathType pathType = tagTypeWrapper ? [tagTypeWrapper integerValue] : OXUnknownType;
    return pathType == OXRootPathType;
}

- (BOOL)hasLeafWildcard
{
    const NSNumber *n = [_tagTypeStack lastObject];
    if (n) {
        const int tagType = [n intValue];
        return tagType == OXAnyPathType || tagType == OXAnyAnyPathType;
    }
    return NO;
}

- (BOOL)matches:(NSArray *)docTagStack
{
    NSInteger docIdx = [docTagStack count] - 1;
    NSInteger pathIdx = [_tagStack count] - 1;;
    BOOL seekMatch = NO;
    const BOOL isDocRoot = [OX_ROOT_PATH isEqualToString:[docTagStack objectAtIndex:0]];
    NSInteger seekLimit = 0;
    while(docIdx >= 0 && pathIdx >= 0) {
        const NSString *docTag = [docTagStack objectAtIndex:docIdx];
        NSString *pathTag = [_tagStack objectAtIndex:pathIdx];
        switch ([[_tagTypeStack objectAtIndex:pathIdx] integerValue]) {
            case OXRootPathType:    //
                if (seekMatch) {
                    return YES;
                } else {
                    return (docIdx == 0);
                }
            case OXElementPathType:
                if (seekMatch) {
                    if ( [docTag isEqualToString:pathTag] ) {
                        seekMatch = NO;
                        seekLimit = 0;
                        pathIdx--;
                    }
                    docIdx--;
                } else {
                    if ( ! [docTag isEqualToString:pathTag] ) {
                        return NO;
                    } else {
                        docIdx--;
                        pathIdx--;
                    }
                }
                break;
            case OXAnyPathType: //skip one element
                if (seekMatch) {
                    NSAssert1(NO, @"ERROR: wildcard can't be adjacent to double wildcard: %@", [self description]);
                } else {
                    docIdx--;
                    pathIdx--;
                }
                break;
            case OXAnyAnyPathType:  //seek subsequent match or fail
                if (seekMatch) {
                    NSAssert1(NO, @"ERROR: adjacent double wildcards don't make sense: %@", [self description]);
                } else {
                    // **/e: e -> T, a/b/e -> T, e/f -> F
                    // a/b/**: a/b -> T, a -> F, a/c -> F
                    seekMatch = YES;    //switch to seekMatch mode
                    pathIdx--;
                    BOOL isPathRoot = [self rootInMatch];
                    seekLimit = pathIdx - (isPathRoot && !isDocRoot ? 1 : 0);
                }
                break;
            case OXAttributePathType:   
            case OXTextPathType:
                if (seekMatch) {
                    NSAssert1(NO, @"ERROR: attributes or text can't preceed double wildcardse: %@", [self description]);
                } else {        //not matching attributes or text() here - so just skip it
                    pathIdx--;
                }
                break;
        }
        if (seekMatch && docIdx < seekLimit)
            return NO;
    }
    return YES;
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
