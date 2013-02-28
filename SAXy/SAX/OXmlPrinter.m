//
//  OXmlPrinter.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/20/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXmlPrinter.h"
#import "OXUtil.h"


@implementation OXmlPrinter


@synthesize output = _output;


- (id)init
{
    if (self = [super init]) {
        _indent = 0;
        _output = [NSMutableString stringWithCapacity:1024*5];
        _nsPrefix = nil;
        _indentString = OC_DEFAULT_INDENT_STRING;
        _crString = OC_DEFAULT_NEWLINE_STRING;
        _quoteChar = @"\"";
        _embedInCData = ^(NSString *text) {
            BOOL useCData = text != nil && ([text length] > 500 || [text rangeOfString:@"<"].location != NSNotFound);
            return useCData;
        };
    }
    return self;
}

#pragma mark - properties

- (void)setNsPrefix:(NSString *)nsPrefix
{
    _nsPrefix = [nsPrefix isEqualToString:@"_xmlns_"] ? nil : nsPrefix;  //default namespace - special handling
}

#pragma mark - public

- (void)reset
{
    [_output setString:@""];
}

- (NSError *)writeToFile:(NSString *)path
{
    NSError *error_ = nil;
    [self.output writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&error_];
    if (error_) {
        NSLog(@"ERROR: %@",error_);
    } else {
        NSLog(@"output=%@", path);
    }
    return error_;
}

- (void)indent:(int)diff
{
    if (_indentString) {
        _indent += diff;
        for(int i=0;i<_indent;i++)
            [_output appendString:_indentString];
    }
}

- (void)attribute:(NSString *)name numberValue:(NSNumber *)value
{
    if (name && value)
        [_output appendFormat:@" %@=%@%@%@", name, _quoteChar, value, _quoteChar];
}

- (void)attribute:(NSString *)name value:(NSString *)value
{
    if (name && value)
        [_output appendFormat:@" %@=%@%@%@", name, _quoteChar, [OXUtil xmlSafeString:value], _quoteChar];
}


- (void)element:(NSString *)tag value:(NSString *)text;
{
    if (text) {
        [self startTag:tag close:YES];
        if (_embedInCData && _embedInCData(text)) {
            [self appendTextInCData:text];
        } else {
            [self appendEncodedText:text];
        }
        [self endTag:tag indent:NO];
    }
}

- (void)startTag:(NSString *)tag attributes:(NSArray *)keyValuePairs close:(BOOL)close;
{
    [self indent:0];
    [_output appendString:@"<"];
    if (_nsPrefix) {
        [_output appendString:_nsPrefix];
        [_output appendString:@":"];
    }
    [_output appendString:tag];
    const NSInteger attributesCount = keyValuePairs ? [keyValuePairs count] : 0;
    for(int i=0;i<attributesCount;i+=2) { //expecting string-string pairs:
        [self attribute:[keyValuePairs objectAtIndex:i] value:[keyValuePairs objectAtIndex:i+1]];
    }
    if (close)
        [_output appendString:@">"];
}

- (void)startTag:(NSString *)tag close:(BOOL)close;
{
    [self startTag:tag attributes:nil close:close];
}

- (void)closeEmptyTag
{
    [_output appendString:@" />"];
}

- (void)emptyTag:(NSString *)tag attributes:(NSArray *)keyValuePairs
{
    [self startTag:tag attributes:keyValuePairs close:NO];
    [_output appendString:@" />"];
}

- (void)emptyTag:(NSString *)tag
{
    [self startTag:tag close:NO];
    [_output appendString:@" />"];
}

- (void)endTag:(NSString *)tag indent:(BOOL)indent
{
    if (indent) {
        [self indent:0];
    }
    [_output appendString:@"</"];
    if (_nsPrefix) {
        [_output appendString:_nsPrefix];
        [_output appendString:@":"];
    }
    [_output appendString:tag];
    [_output appendString:@">"];
    [self newLine];
}

- (void)closeTag
{
    [_output appendString:@">"];
}

- (void)newLine
{
    if (_crString) {
        [_output appendString:_crString];
    }
}

- (void)elementBody:(NSString *)tag bodyText:(NSString *)bodyText
{
    if (bodyText) {
        [_output appendString:@">"];
        if (_embedInCData && _embedInCData(bodyText)) {
            [self appendTextInCData:bodyText];
        } else {
            [self appendEncodedText:bodyText];
        }
        [self endTag:tag indent:NO];
    } else {
        [_output appendString:@" />"];
        [self newLine];
    }
}

- (void)appendEncodedText:(NSString *)text
{
    if (text) {
        [_output appendString:[OXUtil xmlSafeString:text]];
    }
}

- (void)appendUnencodedText:(NSString *)text
{
    if (text) {
        [_output appendString:text];
    }
}

- (void)appendTextInCData:(NSString *)text
{
    if (text) {
        [_output appendString:@"<![CDATA["];
        [_output appendString:text];
        [_output appendString:@"]]>"];
    }
}

@end
