//
//  OXProperty.h
//  SAXy OX - Object-to-XML mapping library
//
//  Metadata to describe a property to the mapping sytem, which is simply a type and a name.
//
//  Created by Richard Easterling on 2/10/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OXType.h"


@interface OXProperty : NSObject

@property(strong,nonatomic,readwrite)NSString *name;
@property(strong,nonatomic,readwrite)OXType *type;

#pragma mark - constructor
+ (id)property:(NSString *)name type:(OXType *)type;

@end
