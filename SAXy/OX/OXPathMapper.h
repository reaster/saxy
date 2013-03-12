/**

  OXPathMapper.h
  SAXy OX - Object-to-XML mapping library

  The heart of the OX system is the PathMapper class which encapsulates how to map one type to another, specificly how
  to map a source type (fromType) to a target type (toType).

  Each type can have a path associated with it (toPath and fromPath respecively). The path is usually just the property name 
  (for example: 'city'), but it can also be a KVC description ('contact.address.city') or in the XML reahlm,
  an element, attribute or xpath description ('/contact/address/@city'). Complex paths have a list of
  component parts starting with a 'root' node and ending with a 'leaf' node.

  The action part of the OX mapping system happens in block functions.  Blocks are defined for object instantiation (factory),
  type conversion (toTransform, fromTransform), property access (getter, setter) and container child access (enumerator,
  appender).  Generaly, blocks are assigned automaticly by the OX system and just work. When special handling is required, the
  user can override specific blocks allowing a high degree of customization.  Default blocks found in the OXTransfer class can
  be customized or used as templates.  Blocks are passed an instance of the context at run-time, allowing access to other features
  in the system, as well as, providing a means to pass values accross calls.

  Users only needs to supply the information that can not be obtained automatiy via self reflection on the taget classes. This typically
  includes scalar encoding details, container child types and paths, when the target and source names are not identical.

  The 'configure' method triggers self-reflection, conflict checking and default block assignment. It is normally called automaticly by
  the system on first lookup call.
  
   
  Created by Richard Easterling on 1/28/13.

 */
#import <Foundation/Foundation.h>
#import "OXType.h"
#import "OXBlockDef.h"
@protocol OXContext;
@class OXComplexMapper;

typedef enum {
    OX_PATH_MAPPER,
    OX_COMPLEX_MAPPER
} OXMapperEnum;

#define OX_ROOT_PATH @"/"

@interface OXPathMapper : NSObject

#pragma mark - type source (from) and target (to)
@property(strong,nonatomic,readwrite)OXType *toType;                    //target OXType for this mapping
@property(strong,nonatomic,readwrite)OXType *fromType;                  //source OXType for this mapping

#pragma mark - to property path
@property(strong,nonatomic,readwrite)NSString *toPath;                  //single property name or KVC key path
@property(strong,nonatomic,readonly)NSString *toPathRoot;               //root segment of toPath, KVC example: a.b.c -> a
@property(strong,nonatomic,readonly)NSString *toPathLeaf;               //leaf segment of toPath, KVC example: a.b.c -> c

#pragma mark - from property path
@property(strong,nonatomic,readwrite)NSString *fromPath;                //single property name or KVC key path
@property(strong,nonatomic,readonly)NSString *fromPathRoot;             //root segment of fromPath, KVC example: a.b.c -> a
@property(strong,nonatomic,readonly)NSString *fromPathLeaf;             //leaf segment of fromPath, KVC example: a.b.c -> c

#pragma mark - constructor block
@property(copy,nonatomic,readwrite)OXFactoryBlock factory;              //returns (a usualy new) instance of toClass

#pragma mark - type conversion blocks
@property(copy,nonatomic,readwrite)OXTransformBlock toTransform;        //optional: convert 'from' instance to 'to' instance
@property(copy,nonatomic,readwrite)OXTransformBlock fromTransform;      //optional: convert 'to' instance to 'from' instance
@property(strong,nonatomic,readonly)NSString *formatterName;            //applies formatter to number or date. See OXTransform registerFormatter:withName: method

#pragma mark - KVC property blocks
@property(copy,nonatomic,readwrite)OXGetterBlock getter;                //retunrs property value (usualy from parent), optionaly transformed to fromType
@property(copy,nonatomic,readwrite)OXSetterBlock setter;                //sets property value (usualy on parent instance), optionaly transformed from fromType

#pragma mark - collection blocks
@property(copy,nonatomic,readwrite)OXEnumerationBlock enumerator;       //for collection properties, enumerates over contained instances
@property(copy,nonatomic,readwrite)OXSetterBlock appender;              //for collection properties, appends/adds child instance to container
@property(strong,nonatomic,readwrite)NSString *dictionaryKeyName;       //for dictionary properties, identifies property to use as key

#pragma mark - house keeping
@property(assign,nonatomic,readonly)OXMapperEnum mapperEnum;            //indicates specific mapping type
@property(assign,nonatomic,readwrite)BOOL isConfigured;                 //set to YES after configure method is called
@property(assign,nonatomic,readwrite)BOOL virtualProperty;              //no actual property under this name
@property(weak,nonatomic,readwrite)OXComplexMapper *parent;             //OXComplexMapper parent/owning instance of this path mapper

#pragma mark - constructors
- (id)initMapperWithEnum:(OXMapperEnum)mapperEnum;
- (id)initMapperToClass:(Class)toType toPath:(NSString *)toPath fromScalar:(const char *)encodedType fromPath:(NSString *)fromPath;
- (id)initMapperToScalar:(const char *)encodedType toPath:(NSString *)toPath fromClass:(Class)fromType fromPath:(NSString *)fromPath;
- (id)initMapperToClass:(Class)toType toPath:(NSString *)toPath fromClass:(Class)fromType fromPath:(NSString *)fromPath;
- (id)initMapperToType:(OXType *)toType toPath:(NSString *)toPath fromType:(OXType *)fromType fromPath:(NSString *)fromPath;

#pragma mark - configure
- (NSArray *)configure:(OXContext *)context;                            //must be called before mappers are used, isConfigured is set after completion
- (void)assignDefaultBlocks:(OXContext *)context;                       //if not assigned already, set default getter,setter,toTransform,fromTransform & factory blocks
- (NSArray *)verifyToTypeUsingSelfReflection:(OXContext *)context errors:(NSArray *)errors; //TODO remove me

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



