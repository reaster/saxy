/**

  OXTransform.h
  SAXy OX - Object-to-XML mapping library

  The OXTransform class is a factory class for type-specific block functions and formatters.  It comes
  pre-populated with default block functions for most common class and scalar types.

  The block factory stores default type converters of the form:

     typedef id (^OXTransformBlock)(id source)

  Transformers are registerd under the source (from) and target (to) class types and are retrieved using
  this method:

    - (OXTransformBlock)transformerFrom:(Class)fromType to:(Class)toType;

  A typical transformer looks like this:

     ^(id value) { return [value boolValue] ? @"true" : @"false"; };  //boolean-to-string

  Currently, the supported type converters are common object-to-string and scalar-to-string tranformer block functions.
  Supported scalar types are:

    BOOL, char, unsigned char, short, unsigned short, int, unsigned int, long, unsigned long, long long,
    unsigned long long, float, double,

  Supported (non-scalar) object types are:

    NSString, NSMutableString, NSURL, NSDate, NSData, NSLocale

  NSValueTransformer is not directly supported, however it's integration is trivial. For example:

    ^(id value) { return [[NSValueTransformer valueTransformerForName:@"MY_TRNASFORMER"] transformedValue:value]; };


  The block factory also stores functions for working with various collection types, specificly enumeration blocks:

    typedef id<NSFastEnumeration> (^OXEnumerationBlock)(id container, OXContext *ctx);

  and appender blocks which use the setter block signature:

    typedef void (^OXSetterBlock)(NSString *path, id value, id target, OXContext *ctx);

  Supported collections (and their mutable subclasses) are:

    NSDictionary, NSArray, NSSet, NSOrderedSet


  TODO
    * Not supported (yet): NSDecimal, NSRange, NSAttributedString, NSPoint, NSRange, NSSize and NSRect(OSX)
    * should we split this class into a OXBlockFactory and OXFormatterRegistry?
    * scalar transformers should be stored in a seperate NSDictionary, a 'L' class would cause a namespace collision with an unsigned long scalar
    * add support for NDData-to-base64 conversion


  see: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/DataFormatting/DataFormatting.html
  see: http://www.cocoawithlove.com/2009/05/simple-methods-for-date-formatting-and.html
  see: http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/KeyValueCoding/Articles/KeyValueCoding.html
  see: http://feed2.w3.org/docs/rss2.html

  Created by Richard Easterling on 1/25/13.

 */
#import "OXBlockDef.h"

//built-in named formatters:
#define OX_DEFAULT_DATE_FORMATTER @"OX_DEFAULT_DATE_FORMATTER"          //used on all dates by default
#define OX_RFC3339_DATE_FORMATTER @"OX_RFC3339_DATE_FORMATTER"          //XML standard, date formatter: yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'
#define OX_SHORT_STYLE_DATE_FORMATTER @"OX_SHORT_STYLE_DATE_FORMATTER"  //date and time: NSDateFormatterShortStyle
//#define OX_LONG_STYLE_DATE_FORMATTER @"OX_LONG_DATE_FORMATTER"          //date formatter: MMMM d',' yyyy
#define OX_CURRENCY_FORMATTER @"OX_CURRENCY_FORMATTER"                  //NSNumberFormatterCurrencyStyle
#define OX_PERCENTAGE_FORMATTER @"OX_PERCENTAGE_FORMATTER"              //NSNumberFormatterPercentStyle
#define OX_DECIMAL_FORMATTER @"OX_DECIMAL_FORMATTER"                    //NSNumberFormatterDecimalStyle

@interface OXTransform : NSObject

@property(nonatomic)BOOL treatScalarZerosAsNil; //true by default

#pragma mark - type-to-type
- (OXTransformBlock)transformerFrom:(Class)fromType to:(Class)toType;
- (OXTransformBlock)transformerFrom:(Class)fromType toScalar:(const char *)encodedType;
- (OXTransformBlock)transformerScalar:(const char *)encodedType to:(Class)toType;

- (void)registerFrom:(Class)fromType to:(Class)toType transformer:(OXTransformBlock)transformer;
- (void)registerFrom:(Class)fromType toScalar:(const char *)encodedType transformer:(OXTransformBlock)transformer;
- (void)registerFromScalar:(const char *)encodedType to:(Class)toType transformer:(OXTransformBlock)transformer;

#pragma mark - formatters
- (NSFormatter *)formatterWithName:(const NSString *)name;
- (NSDateFormatter *)defaultDateFormatter;

- (void)registerFormatter:(NSFormatter *)formatter withName:(const NSString *)name;
- (void)registerDefaultDateFormatter:(NSDateFormatter *)dateFormatter;      //registered under OX_DEFAULT_DATE_FORMATTER name

#pragma mark - collection
- (OXEnumerationBlock)enumerationForContainer:(Class)containerClass;
- (OXSetterBlock)appenderForContainer:(Class)containerClass;

- (void)registerContainerClass:(Class)containerClass enumeration:(OXEnumerationBlock)enumeration;
- (void)registerContainerClass:(Class)containerClass appender:(OXSetterBlock)appender;

#pragma mark - utility
+ (NSString *)keyForEncodedType:(const char *)encodedType;  //pulls type data from encoded property types or @encode() results

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
