//
//  OXTransform.h
//  SAXy OX - Object-to-XML mapping library
//
//  The OXTransform class encapsulates default block functions, type conversion and formatting.
//
//  It is a
//  registry of common object-to-string and scalar-to-string tranformer block functions of the form:
//
//     typedef id (^OXTransformBlock)(id source)
//
//  A typical transformer looks like this:
//
//     ^(id value) { return [value boolValue] ? @"true" : @"false"; };  //boolean-to-string
//
//  Supported scalar types are:
//
//    BOOL, char, unsigned char, short, unsigned short, int, unsigned int, long, unsigned long, long long, unsigned long long, float, double,
//    NSInteger, NSUInteger, NSTimeInterval
//
//  Supported object types are:
//
//    NSString, NSMutableString, NSURL, NSDate, NSData, NSLocale
//
//  Supported collections (and their mutable subclasses) are:
//
//    NSDictionary, NSArray, NSSet, NSOrderedSet
//
//
//  NSValueTransformer is not directly supported, however it's integration is trivial. For example:
//
//    ^(id value) { return [[NSValueTransformer valueTransformerForName:@"MY_TRNASFORMER"] transformedValue:value]; };
//
//  TODO
//    * Not supported (yet): NSDecimal, NSRange, NSAttributedString, NSPoint, NSRange, NSSize and NSRect(OSX)
//
//  see: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/DataFormatting/DataFormatting.html
//  see: http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/KeyValueCoding/Articles/KeyValueCoding.html
//  see: http://feed2.w3.org/docs/rss2.html
//
//  Created by Richard Easterling on 1/25/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXBlockDef.h"

//built-in named formatters:
#define OX_DEFAULT_DATE_FORMATTER @"OX_DEFAULT_DATE_FORMATTER"          //used on all dates by default
#define OX_RFC3339_DATE_FORMATTER @"OX_RFC3339_DATE_FORMATTER"          //XML standard - default date formatter
#define OX_SHORT_STYLE_DATE_FORMATTER @"OX_SHORT_STYLE_DATE_FORMATTER"  //date and time: NSDateFormatterShortStyle
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
