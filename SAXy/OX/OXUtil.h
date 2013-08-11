/**

  OXUtil.h
  SAXy OX - Object-to-XML mapping library

  Miscellaneous static support methods, mostly concerned with string handling or self reflection.

  Created by Richard Easterling on 2/10/13.

 */
#import <Foundation/Foundation.h>
#import "OXBlockDef.h"


@interface OXUtil : NSObject

#pragma mark - string
+ (NSString *)trim:(NSString *)text;                                                            //trim leading and trailing whitespace
+ (int)firstIndexOfChar:(unichar)ch inString:(NSString *)string;
+ (int)lastIndexOfChar:(unichar)ch inString:(NSString *)string;
+ (NSString *)firstSegmentFromPath:(NSString *)path separator:(unichar)separator;               // example using '/': a/b/c -> a
+ (NSString *)lastSegmentFromPath:(NSString *)path separator:(unichar)separator;                // example using '/': a/b/c -> c
+ (NSString *)xmlSafeString:(NSString *)text;                                                   //escape chars: &<>'"
+ (BOOL)isXPathString:(NSString *)string;                                                       //detects multi-element and/or wildcard paths
+ (BOOL)allDigits:(NSString *)text;                                                             //true if text only contains chars: .-+0123456789

#pragma mark - file
+ (NSData *)readResourceFile:(NSString *)fileName;                                              //read file's data from resource bundle

#pragma mark - naming
+ (NSString *)guessSingularNoun:(NSString *)pluralNoun;                                         //guesses singular noun, given an english plural

#pragma mark - reflection
+ (void)propertyInspectionForClass:(Class)objectClass withBlock:(OCPropertyMetadataBlock)block; //iterate Class properties with block callback
+ (BOOL)knownCollectionType:(Class)objectClass;                                                 //true if class is a common NS container
+ (BOOL)knownSimpleType:(Class)type;                                                            //true if class is a common NS simple type (i.e. string representation)  
+ (NSString *)scalarString:(const char *)encodedType;                                           //return string representation of encoded (usually scalar) type

#pragma mark - base64
+(NSString *)base64StringByEncodingData:(NSData *)data;                                         //encode data as base64 string
+(NSData *)decodeBase64String:(NSString *)string;                                               //decode base64 string into data

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
