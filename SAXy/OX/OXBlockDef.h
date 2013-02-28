//
//  OXBlockDef.h
//  SAXy OX - Object-to-XML mapping library
//
//  Common OX block funciton typedefs.
//
//  Created by Richard Easterling on 1/28/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OXContext;
@class OXPathMapper;


typedef id (^OXFactoryBlock)(NSString *path, OXContext *ctx);

typedef void (^OXSetterBlock)(NSString *path, id value, id target, OXContext *ctx);
typedef id (^OXGetterBlock)(NSString *path, id source, OXContext *ctx);

typedef id<NSFastEnumeration> (^OXEnumerationBlock)(id container, OXContext *ctx);

typedef id (^OXTransformBlock)(id source, OXContext *ctx);

typedef id (^OXForEachPathMapperBlock)(OXPathMapper *mapper);

typedef void (^OCPropertyMetadataBlock)(NSString *propertyName, Class propertyClass, const char *attributes);


