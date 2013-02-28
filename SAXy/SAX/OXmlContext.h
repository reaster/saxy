//
//  OXmlContext.h
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/15/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OXTransform.h"
#import "OXContext.h"
@class OXmlContext;


typedef enum {
    OX_SAX_UNDEFINED_ACTION,    //undefined, helps catch uninitilized values
    OX_SAX_VALUE_ACTION,        //leaf node - simple element with text body
    OX_SAX_OBJECT_ACTION,       //complex node - complex element with child elements
    OX_SAX_SKIP_ACTION          //skip this element and it's attributes, process it's children
} OXSAXActionEnum;

typedef NSString* (^OXmlAttributeFilterBlock)(NSString *attrName, NSString *attrValue);
typedef NSString* (^OXmlElementFilterBlock)(NSString *elementName, NSString *elementValue);

@interface OXmlContext : OXContext

@property(strong,readwrite,nonatomic) NSMutableDictionary *namespaces;     //indexed by prefix
@property(copy,readwrite,nonatomic) OXmlAttributeFilterBlock attributeFilterBlock;
@property(copy,readwrite,nonatomic) OXmlElementFilterBlock elementFilterBlock;
@property(assign,readwrite,nonatomic) BOOL logReaderStack;
@property(assign,readwrite,nonatomic) BOOL logReaderInput;

#pragma mark - OXSAXActionEnum stack
- (void)pushMappingType:(OXSAXActionEnum)mappingType;
- (OXSAXActionEnum)popMappingType;
- (OXSAXActionEnum)peekMappingType;
- (OXSAXActionEnum)peekMappingTypeAtIndex:(NSInteger)index;

#pragma mark - element body text 
- (NSString *)text;
- (void)clearText;
- (void)appendText:(NSString *)text;

#pragma mark - debug
- (NSString *)tagPath;
+ (id)contextWithPathStack:(NSArray *)tagStack;

@end
