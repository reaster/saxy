//
//  OXmlPrinter.h
//  SAXy OX - Object-to-XML mapping library
//
//  XML printer utility class for writing XML tags and text to a stream.
//
//  Created by Richard Easterling on 1/20/13.
//

#import <Foundation/Foundation.h>

#define OC_DEFAULT_NEWLINE_STRING @"\n"
#define OC_DEFAULT_INDENT_STRING @"    "

typedef BOOL(^OXEmbedInCDataBlock)(NSString *text);


@interface OXmlPrinter : NSObject

@property(assign,readwrite,nonatomic) int indent;                       //ident level
@property(strong,readwrite,nonatomic) NSString *nsPrefix;               //current namespace prefix
@property(strong,readwrite,nonatomic) NSString *crString;               //carriage return chars or nil if not in prettyPrint mode
@property(strong,readwrite,nonatomic) NSString *quoteChar;              //quote character, default is: "
@property(strong,readwrite,nonatomic) NSString *indentString;           //can be set to space character sequence, tab or nil
@property(copy,readwrite,nonatomic) OXEmbedInCDataBlock embedInCData;   //default triggers if '<' chars found or len > 500
@property(strong,readonly,nonatomic) NSMutableString *output;           //holds output xml. TODO refactor to use streams


- (void)reset;                                                          // zeros output string
- (void)indent:(int)diff;                                               //added to indent to inc or dec for prettyPrint mode
- (void)attribute:(NSString *)name value:(NSString *)value;
- (void)attribute:(NSString *)name numberValue:(NSNumber *)value;
- (void)startTag:(NSString *)tag close:(BOOL)close;
- (void)startTag:(NSString *)tag attributes:(NSArray *)keyValuePairs close:(BOOL)close;
- (void)emptyTag:(NSString *)tag;
- (void)emptyTag:(NSString *)tag attributes:(NSArray *)keyValuePairs;
- (void)closeEmptyTag;
- (void)endTag:(NSString *)tag indent:(BOOL)indent;
- (void)element:(NSString *)tag value:(NSString *)value;
- (void)elementBody:(NSString *)tag bodyText:(NSString *)bodyText;
- (void)closeTag;
- (void)newLine;
- (void)appendEncodedText:(NSString *)text;
- (void)appendUnencodedText:(NSString *)text;
- (void)appendTextInCData:(NSString *)text;
- (NSError *)writeToFile:(NSString *)path;


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
