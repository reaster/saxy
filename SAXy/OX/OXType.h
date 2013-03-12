/**

  OXMeta.h
  SAXy OX - Object-to-XML mapping library

  Type metadata needed for mapping system. Types supported include:

    atomic        - single-value types
    scalar        - atomic scalar values, often in a wrapper class like NSValue or NSNumber
    containers    - with a child type
    complex       - multi-property classes
    polymorphic   - placeholder types, usually NSObject

  Relevent properties are determined by the typeEnum setting. 
  Because scalars are burried in an amorphic class (usually NSNumber)
  additional information (scalarEncoding) is required to properly map their values. Likewise,
  container (NSArray, NSDictionary, etc.) mapping requires child type information. Finally, complex
  multi-value types are defined by their properties which this class will automaticly obtain using
  self reflection.

  TODO probably should be renamed OXMetaType.


  Created by Richard Easterling on 1/26/13.

*/
#import <Foundation/Foundation.h>
@protocol OXContext;
@class OXProperty;


typedef enum {
    OX_ATOMIC,      //MVC attributes that are not scalars
    OX_SCALAR,      //MVC scalar attributes
    OX_CONTAINER,   //collection classes like NSArray and NSSet
    OX_COMPLEX,     //classes with multiple properties
    OX_POLYMORPHIC  //base class of polymorphic mapping defaulting to NSObject
} OXTypeEnum;

#define OX_ENCODED_BOOL "?B"                                       //BOOL property encoding. Can't use @encode(BOOL) because it equals @encode(char)

@interface OXType : NSObject

#pragma mark - required properties
@property(assign,nonatomic,readonly)OXTypeEnum typeEnum;           //required, determines what category of class is being modeled
@property(strong,nonatomic,readonly)Class type;                    //required, thee Objective-C class being described

#pragma mark - OX_SCALAR
@property(assign,nonatomic,readonly)const char *scalarEncoding;    //scalars only: can be @encode(<scalar>) or property encoding value

#pragma mark - OX_CONTAINER:
@property(strong,nonatomic,readonly)OXType *containerChildType;    //containers only: child type held by container, can be polymorphic (i.e. NSObject)

#pragma mark - OX_COMPLEX:
@property(strong,nonatomic,readonly)NSDictionary *properties;      //complex only: map of OXProperty keyed by their property names. Obtained by self reflection.
@property(assign,nonatomic,readonly)BOOL propertiesLoaded;          //complex only: flag to allow lazy-loading of properties via self reflection

#pragma mark - constructors
+ (id)typeContainer:(Class)type containing:(Class)childType;
+ (id)type:(Class)type typeEnum:(OXTypeEnum)typeEnum;

#pragma mark - caches
+ (OXType *)cachedType:(Class)type;
+ (OXType *)cachedScalarType:(const char *)encodedType;
+ (id)scalarType:(Class)typeWrapper scalarEncoding:(const char *)scalarEncoding;

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
