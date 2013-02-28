//
//  OXTypeTranslator.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/15/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXTransform.h"
#import "OXContext.h"
#import "OXType.h"
#import "OXPathMapper.h"

@interface OXTransform ()
- (void)registerDefaultTransformers;
- (void)registerDefaultFormatters;
- (void)registerDefaultContainerBlocks;
- (void)registerDefaultScalarToStringTransformers:(BOOL)ignoreZeros;
@end

@implementation OXTransform
{
    NSMutableDictionary *_transformers;
    NSMutableDictionary *_namedFormatters;
    NSMutableDictionary *_containerAppenders;
    NSMutableDictionary *_containerEnumerators;
    BOOL _treatScalarZerosAsNil;
}

- (id)init
{
    if (self = [super init]) {
        _treatScalarZerosAsNil = YES;
        _transformers = [NSMutableDictionary dictionaryWithCapacity:103];
        _namedFormatters = [NSMutableDictionary dictionaryWithCapacity:43];
        _containerAppenders = [NSMutableDictionary dictionaryWithCapacity:13];
        _containerEnumerators = [NSMutableDictionary dictionaryWithCapacity:13];
        [self registerDefaultTransformers];
        [self registerDefaultFormatters];
        [self registerDefaultContainerBlocks];
    }
    return self;
}

#pragma mark - properties

@dynamic treatScalarZerosAsNil;
-(BOOL)treatScalarZerosAsNil
{
    return _treatScalarZerosAsNil;
}
-(void)setTreatScalarZerosAsNil:(BOOL)treatScalarZerosAsNil
{
    if (treatScalarZerosAsNil != _treatScalarZerosAsNil) {
        [self registerDefaultScalarToStringTransformers:treatScalarZerosAsNil]; //reset default transformers
        _treatScalarZerosAsNil = treatScalarZerosAsNil;
    }
}

#pragma mark - utility

+ (NSString *)keyForEncodedType:(const char *)encodedType
{
    const char *encodedProperty = strchr(encodedType, 'T'); //is this a property encoding?
    if (encodedProperty) {                                  //example: "T^c,N,V_isHtmlBody", just want "^c"
        encodedProperty++;                                  //iterate past 'T' char
        int endIndex = 0;                                   //now find the end of the type section
        int len = strlen(encodedProperty);
        while (encodedProperty[++endIndex] != ',' && endIndex < len);
        char encodedTypeSubstring[endIndex+1];              //copy type encoding to new string
        strncpy(encodedTypeSubstring, encodedProperty, endIndex);
        encodedTypeSubstring[endIndex] = '\0';              //null-terminate C string
        return [NSString stringWithUTF8String:encodedTypeSubstring];
    } else {                                                //assume it's just an @encode() result
        return [NSString stringWithUTF8String:encodedType];
    }
}

#pragma mark - collection

- (OXSetterBlock)appenderForContainer:(Class)containerClass
{
    NSString *key = NSStringFromClass(containerClass);
    return [_containerAppenders objectForKey:key];
}

- (OXEnumerationBlock)enumerationForContainer:(Class)containerClass
{
    NSString *key = NSStringFromClass(containerClass);
    return [_containerEnumerators objectForKey:key];
}

- (void)registerContainerClass:(Class)containerClass enumeration:(OXEnumerationBlock)enumeration
{
    NSString *key = NSStringFromClass(containerClass);
    [_containerEnumerators setObject:enumeration forKey:key];
}

- (void)registerContainerClass:(Class)containerClass appender:(OXSetterBlock)appender
{
    NSString *key = NSStringFromClass(containerClass);
    [_containerAppenders setObject:appender forKey:key];
}

- (void)registerDefaultContainerBlocks
{
    //TODO add support for NSPointerArray, NSMapTable, and NSHashTable, someday...

    OXEnumerationBlock enumerationBlock = ^(id collection, OXContext *ctx) {
        if (![collection respondsToSelector:@selector(objectEnumerator)]) {
            NSAssert1(NO, @"container %@ should respond to objectEnumerator method", collection);
        }
        id<NSFastEnumeration> result = [collection performSelector:@selector(objectEnumerator)];
        return result;
    };

    [self registerContainerClass:[NSMutableArray class] enumeration:enumerationBlock];
    [self registerContainerClass:[NSMutableArray class] appender: ^(NSString *key, id value, id target, OXContext *ctx) {
        if (value) {
            OXPathMapper *mapper = ctx.currentMapper;
            NSString *kvcKey = mapper.toPath ? mapper.toPath : key;
            NSMutableArray *container = mapper.getter(kvcKey, target, ctx);
            if (container == nil) {
                container = [NSMutableArray array];
                mapper.setter(kvcKey, container, target, ctx);
            }
            [container addObject:value];
        }
    }];

    [self registerContainerClass:[NSArray class] enumeration:enumerationBlock];
    [self registerContainerClass:[NSArray class] appender: ^(NSString *key, id value, id target, OXContext *ctx) {
        OXPathMapper *mapper = ctx.currentMapper;
        if (value) {
            NSString *kvcKey = mapper.toPath ? mapper.toPath : key;
            NSArray *container = mapper.getter(kvcKey, target, ctx);
            if (container) {
                mapper.setter(kvcKey, [container arrayByAddingObject:value], target, ctx); //not effecient, but maintains non-mutable array
            } else {
                mapper.setter(kvcKey, [NSArray arrayWithObject:value], target, ctx); //not effecient, but maintains non-mutable array
            }
        }
    }];

    [self registerContainerClass:[NSMutableDictionary class] enumeration:enumerationBlock];
    [self registerContainerClass:[NSMutableDictionary class] appender: ^(NSString *key, id value, id target, OXContext *ctx) {
        OXPathMapper *mapper = ctx.currentMapper;
        id dictKey = [value valueForKey:mapper.dictionaryKeyName];
        if (value && dictKey) {
            NSString *kvcKey = mapper.toPath ? mapper.toPath : key;
            NSMutableDictionary *container = mapper.getter(kvcKey, target, ctx);
            if (container == nil) {
                container = [NSMutableDictionary dictionary];
                mapper.setter(kvcKey, container, target, ctx);
            }
            [container setObject:value forKey:dictKey];
        }
    }];
    
    [self registerContainerClass:[NSDictionary class] enumeration:enumerationBlock];
    [self registerContainerClass:[NSDictionary class] appender: ^(NSString *key, id value, id target, OXContext *ctx) {
        OXPathMapper *mapper = ctx.currentMapper;
        id dictKey = [value valueForKey:mapper.dictionaryKeyName];
        if (value && dictKey) {
            NSString *kvcKey = mapper.toPath ? mapper.toPath : key;
            NSDictionary *container = mapper.getter(kvcKey, target, ctx);
            if (container) {
                NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:container];
                [newDict setObject:value forKey:dictKey];
                mapper.setter(kvcKey, [newDict copy], target, ctx);    //not effecient, but maintains non-mutable dict
            } else {
                container = [NSDictionary dictionaryWithObject:value forKey:dictKey];
                mapper.setter(kvcKey, container, target, ctx);
            }
        }
    }];
    
    [self registerContainerClass:[NSMutableSet class] enumeration:enumerationBlock];
    [self registerContainerClass:[NSMutableSet class] appender: ^(NSString *key, id value, id target, OXContext *ctx) {
        if (value) {
            OXPathMapper *mapper = ctx.currentMapper;
            NSString *kvcKey = mapper.toPath ? mapper.toPath : key;
            NSMutableSet *container = mapper.getter(kvcKey, target, ctx);
            if (container == nil) {
                container = [NSMutableSet set];
                mapper.setter(kvcKey, container, target, ctx);
            }
            [container addObject:value];
        }
    }];
    
    [self registerContainerClass:[NSSet class] enumeration:enumerationBlock];
    [self registerContainerClass:[NSSet class] appender: ^(NSString *key, id value, id target, OXContext *ctx) {
        if (value) {
            OXPathMapper *mapper = ctx.currentMapper;
            NSString *kvcKey = mapper.toPath ? mapper.toPath : key;
            NSSet *container = mapper.getter(kvcKey, target, ctx);
            if (container) {
                NSMutableSet *newSet = [NSMutableSet setWithSet:container];
                [newSet addObject:value];
                mapper.setter(kvcKey, [newSet copy], target, ctx);
            } else {
                container = [NSSet setWithObject:value];
                mapper.setter(kvcKey, container, target, ctx);
            }
        }
    }];
    
    [self registerContainerClass:[NSMutableOrderedSet class] enumeration:enumerationBlock];
    [self registerContainerClass:[NSMutableOrderedSet class] appender: ^(NSString *key, id value, id target, OXContext *ctx) {
        if (value) {
            OXPathMapper *mapper = ctx.currentMapper;
            NSString *kvcKey = mapper.toPath ? mapper.toPath : key;
            NSMutableOrderedSet *container = mapper.getter(kvcKey, target, ctx);
            if (container == nil) {
                container = [NSMutableOrderedSet orderedSet];
                mapper.setter(kvcKey, container, target, ctx);
            }
            [container addObject:value];
        }
    }];
    
    [self registerContainerClass:[NSOrderedSet class] enumeration:enumerationBlock];
    [self registerContainerClass:[NSOrderedSet class] appender: ^(NSString *key, id value, id target, OXContext *ctx) {
        if (value) {
            OXPathMapper *mapper = ctx.currentMapper;
            NSString *kvcKey = mapper.toPath ? mapper.toPath : key;
            NSOrderedSet *container = mapper.getter(kvcKey, target, ctx);
            if (container) {
                NSMutableOrderedSet *newArray = [NSMutableOrderedSet orderedSetWithOrderedSet:container];
                [newArray addObject:value];
                mapper.setter(kvcKey, [newArray copy], target, ctx);    //not effecient, but maintains non-mutable orderSet
            } else {
                container = [NSOrderedSet orderedSetWithObject:value];
                mapper.setter(kvcKey, container, target, ctx);
            }
        }
    }];
}

#pragma mark - type-to-type

- (OXTransformBlock)transformerFrom:(Class)fromType to:(Class)toType
{
    if ([fromType isEqual:toType]) {
        return nil;                     //trasform not needed for identical types: ^(id value, OXContext *ctx) { return value; };
    } else {
        NSString *fromKey = NSStringFromClass(fromType);
        NSMutableDictionary *fromMap = [_transformers objectForKey:fromKey];
        if (fromMap == nil)
            return nil;
        NSString *toKey = NSStringFromClass(toType);
        return [fromMap objectForKey:toKey];
    }
}

- (void)registerFrom:(Class)fromType to:(Class)toType transformer:(OXTransformBlock)transformer
{
    NSString *fromKey = NSStringFromClass(fromType);
    NSMutableDictionary *fromMap = [_transformers objectForKey:fromKey];
    if (fromMap == nil) {
        fromMap = [NSMutableDictionary dictionaryWithCapacity:13];
        [_transformers setObject:fromMap forKey:fromKey];
    }
    NSString *toKey = NSStringFromClass(toType);
    [fromMap setObject:transformer forKey:toKey];
}

- (void)registerDefaultStringTransformers
{
    //__weak OXTransform *weakSelf = self;                //see http://amattn.com/2011/12/07/arc_best_practices.html
    
    [self registerFrom:[NSString class] to:[NSMutableString class] transformer:^(id string, OXContext *ctx) {
        return [string mutableCopy];
    }];
    [self registerFrom:[NSMutableString class] to:[NSString class] transformer:^(id value, OXContext *ctx) {
        return [value copy];
    }];
    
    [self registerFrom:[NSString class] to:[NSURL class] transformer:^(id string, OXContext *ctx) {
        return [NSURL URLWithString:string];
    }];
    [self registerFrom:[NSURL class] to:[NSString class] transformer:^(id value, OXContext *ctx) {
        return [value absoluteString];
    }];
    
    [self registerFrom:[NSString class] to:[NSMutableData class] transformer:^(id string, OXContext *ctx) {
        return [NSMutableData dataWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    [self registerFrom:[NSMutableData class] to:[NSString class] transformer:^(id value, OXContext *ctx) {
        return [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    }];
    
    [self registerFrom:[NSString class] to:[NSData class] transformer:^(id string, OXContext *ctx) {
        return [string dataUsingEncoding:NSUTF8StringEncoding];
    }];
    [self registerFrom:[NSData class] to:[NSString class] transformer:^(id value, OXContext *ctx) {
        return [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    }];
    
    [self registerFrom:[NSString class] to:[NSDate class] transformer:^(id string, OXContext *ctx) {
        NSDate *date = nil;
        if (string) {
            NSString *formatterName = ctx.currentMapper.formatterName;
            NSDateFormatter *formatter = (NSDateFormatter *)[ctx.transform formatterWithName:formatterName ? formatterName : OX_DEFAULT_DATE_FORMATTER];
            //see http://stackoverflow.com/questions/4330137/parsing-rfc3339-dates-with-nsdateformatter-in-ios-4-x-and-macos-x-10-6-impossib
            NSError *error;
            [formatter getObjectValue:&date forString:string range:nil error:&error]; //date = [formatter dateFromString:string];
        }
        return date;
    }];
    [self registerFrom:[NSDate class] to:[NSString class] transformer:^(id value, OXContext *ctx) {
        NSString *date = nil;
        if (value) {
            NSString *formatterName = ctx.currentMapper.formatterName;
            NSDateFormatter *formatter = (NSDateFormatter *)[ctx.transform formatterWithName:formatterName ? formatterName : OX_DEFAULT_DATE_FORMATTER];
            date = [formatter stringFromDate:value];
        }
        return date;
    }];
    
    [self registerFrom:[NSString class] to:[NSLocale class] transformer:^(id string, OXContext *ctx) {
        return [[NSLocale alloc] initWithLocaleIdentifier:string];
    }];
    [self registerFrom:[NSLocale class] to:[NSString class] transformer:^(id value, OXContext *ctx) {
        return [value localeIdentifier];
    }];
}

#pragma mark - object-to-scalar transformers

- (OXTransformBlock)transformerFrom:(Class)fromType toScalar:(const char *)encodedType
{
    NSString *fromKey = NSStringFromClass(fromType);
    NSMutableDictionary *fromMap = [_transformers objectForKey:fromKey];
    if (fromMap == nil)
        return nil;
    NSString *toKey = [[self class] keyForEncodedType:encodedType];
    return [fromMap objectForKey:toKey];
}

- (void)registerFrom:(Class)fromType toScalar:(const char *)encodedType transformer:(OXTransformBlock)transformer
{
    NSString *fromKey = NSStringFromClass(fromType);
    NSMutableDictionary *fromMap = [_transformers objectForKey:fromKey];
    if (fromMap == nil) {
        fromMap = [NSMutableDictionary dictionaryWithCapacity:13];
        [_transformers setObject:fromMap forKey:fromKey];
    }
    NSString *toKey = [[self class] keyForEncodedType:encodedType];
    [fromMap setObject:transformer forKey:toKey];
}

#pragma mark - scalar-to-object transformers

- (OXTransformBlock)transformerScalar:(const char *)encodedType to:(Class)toType
{
    NSString *fromKey = [[self class] keyForEncodedType:encodedType];
    NSMutableDictionary *fromMap = [_transformers objectForKey:fromKey];
    if (fromMap == nil)
        return nil;
    NSString *toKey = NSStringFromClass(toType);
    return [fromMap objectForKey:toKey];
}

- (void)registerFromScalar:(const char *)encodedType to:(Class)toType transformer:(OXTransformBlock)transformer
{
    NSString *fromKey = [[self class] keyForEncodedType:encodedType];
    NSMutableDictionary *fromMap = [_transformers objectForKey:fromKey];
    if (fromMap == nil) {
        fromMap = [NSMutableDictionary dictionaryWithCapacity:13];
        [_transformers setObject:fromMap forKey:fromKey];
    }
    NSString *toKey = NSStringFromClass(toType);
    [fromMap setObject:transformer forKey:toKey];
}


#pragma mark - scalar default transformers

- (void)registerDefaultScalarToStringTransformers:(BOOL)zerosAsNils
{
    [self registerFromScalar:OX_ENCODED_BOOL to:[NSString class] transformer:^(id value, OXContext *ctx) {    // Bool
        return value ? ([value boolValue] ? @"true" : @"false") : nil;
    }];
    if (zerosAsNils) {
        [self registerFromScalar:@encode(char) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value charValue] != 0 ? [value stringValue] : nil;
        }];
        [self registerFromScalar:@encode(unsigned char) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value unsignedCharValue] != 0 ? [value stringValue] : nil;
        }];
        [self registerFromScalar:@encode(short) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value shortValue] != 0 ? [value stringValue] : nil;
        }];
        [self registerFromScalar:@encode(unsigned short) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value unsignedShortValue] != 0 ? [value stringValue] : nil; 
        }];
        [self registerFromScalar:@encode(int) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value intValue] != 0 ? [value stringValue] : nil;
        }];
        [self registerFromScalar:@encode(unsigned int) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value unsignedIntValue] != 0 ? [value stringValue] : nil;
        }];
        [self registerFromScalar:@encode(long) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value longValue] != 0 ? [value stringValue] : nil;
        }];
        [self registerFromScalar:@encode(unsigned long) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value unsignedLongValue] != 0 ? [value stringValue] : nil;
        }];
        [self registerFromScalar:@encode(long long) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value longLongValue] != 0l ? [value stringValue] : nil; 
        }];
        [self registerFromScalar:@encode(unsigned long long) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return value && [value unsignedLongLongValue] != 0l ? [value stringValue] : nil;
        }];
        [self registerFromScalar:@encode(float) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            NSString *result = nil;
            if (value && [value floatValue] != 0.0f) {
                NSString *formatterName = ctx.currentMapper.formatterName;
                if (formatterName) {
                    NSNumberFormatter *formatter = (NSNumberFormatter *)[ctx.transform formatterWithName:formatterName];
                    result = [formatter stringFromNumber:value];
                } else {
                    result = [value stringValue];
                }
            }
            return result;
        }];
        [self registerFromScalar:@encode(double) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            NSString *result = nil;
            if (value && [value doubleValue] != 0.0) {
                NSString *formatterName = ctx.currentMapper.formatterName;
                if (formatterName) {
                    NSNumberFormatter *formatter = (NSNumberFormatter *)[ctx.transform formatterWithName:formatterName];
                    result = [formatter stringFromNumber:value];
                } else {
                    result = [value stringValue];
                }
            }
            return result;
        }];
    } else {
        [self registerFromScalar:@encode(char) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(unsigned char) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(short) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(unsigned short) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(int) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(unsigned int) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(long) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(unsigned long) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(long long) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(unsigned long long) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            return [value stringValue];
        }];
        [self registerFromScalar:@encode(float) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            NSString *result = nil;
            if (value) {
                NSString *formatterName = ctx.currentMapper.formatterName;
                if (formatterName) {
                    NSNumberFormatter *formatter = (NSNumberFormatter *)[ctx.transform formatterWithName:formatterName];
                    result = [formatter stringFromNumber:value];
                } else {
                    result = [value stringValue];
                }
            }
            return result;
        }];
        [self registerFromScalar:@encode(double) to:[NSString class] transformer:^(id value, OXContext *ctx) {
            NSString *result = nil;
            if (value) {
                NSString *formatterName = ctx.currentMapper.formatterName;
                if (formatterName) {
                    NSNumberFormatter *formatter = (NSNumberFormatter *)[ctx.transform formatterWithName:formatterName];
                    result = [formatter stringFromNumber:value];
                } else {
                    result = [value stringValue];
                }
            }
            return result;
        }];
    }
}

- (void)registerDefaultStringToScalarTransformers
{
    [self registerFrom:[NSString class] toScalar:OX_ENCODED_BOOL transformer:^(id string, OXContext *ctx) {    // Bool
        return [NSNumber numberWithBool:[string boolValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(boolean_t) transformer:^(id string, OXContext *ctx) {      // C++ bool or C99 _Bool
        return [NSNumber numberWithBool:[string boolValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(char) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithChar:[string characterAtIndex:0]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(unsigned char) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithUnsignedChar:[string characterAtIndex:0]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(short) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithShort:[string intValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(unsigned short) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithUnsignedShort:[string intValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(int) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithInt:[string intValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(unsigned int) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithUnsignedInt:[string intValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(long) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithLong:[string integerValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(unsigned long) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithUnsignedLong:[string longLongValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(long long) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithLongLong:[string longLongValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(unsigned long long) transformer:^(id string, OXContext *ctx) {
        return [NSNumber numberWithUnsignedLongLong:[string boolValue]];
    }];
    [self registerFrom:[NSString class] toScalar:@encode(float) transformer:^(id string, OXContext *ctx) {
        NSNumber *result = nil;
        if (string) {
            NSString *formatterName = ctx.currentMapper.formatterName;
            if (formatterName) {
                NSNumberFormatter *formatter = (NSNumberFormatter *)[ctx.transform formatterWithName:formatterName];
                result = [formatter numberFromString:string];
            } else {
                result = [NSNumber numberWithFloat:[string floatValue]];
            }
        }
        return result;
    }];
    [self registerFrom:[NSString class] toScalar:@encode(double) transformer:^(id string, OXContext *ctx) {
        NSNumber *result = nil;
        if (string) {
            NSString *formatterName = ctx.currentMapper.formatterName;
            if (formatterName) {
                NSNumberFormatter *formatter = (NSNumberFormatter *)[ctx.transform formatterWithName:formatterName];
                result = [formatter numberFromString:string];
            } else {
                result = [NSNumber numberWithDouble:[string doubleValue]];
            }
        }
        return result;
    }];
}

- (void)registerDefaultTransformers
{
    [self registerDefaultStringTransformers];                   //to-string and from-string default non-scalar transformers
    [self registerDefaultStringToScalarTransformers];                   //string-to-scalar transformers
    [self registerDefaultScalarToStringTransformers:self.treatScalarZerosAsNil]; //scalar-to-string transformers
}


#pragma mark - formatters


- (NSFormatter *)formatterWithName:(const id )name
{
    return [_namedFormatters objectForKey:name];
}

- (NSDateFormatter *)defaultDateFormatter
{
    return (NSDateFormatter *)[self formatterWithName:OX_DEFAULT_DATE_FORMATTER];
}

- (void)registerFormatter:(NSFormatter *)formatter withName:(const NSString *)name
{
    [_namedFormatters setObject:formatter forKey:name];
}

- (void)registerDefaultDateFormatter:(NSDateFormatter *)dateFormatter
{
    [self registerFormatter:dateFormatter withName:OX_DEFAULT_DATE_FORMATTER];
}

- (void)registerDefaultFormatters
{
    //RFC 3339 date time string, does not handle all possible RFC 3339 date time strings, just one of the most common styles.
    NSDateFormatter *_rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [_rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [_rfc3339DateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    [_rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [self registerFormatter:_rfc3339DateFormatter withName:OX_RFC3339_DATE_FORMATTER];
    
    [self registerDefaultDateFormatter:_rfc3339DateFormatter];  //stored under OX_DEFAULT_DATE_FORMATTER name

    NSDateFormatter *_shortStyleDateFormatter = [[NSDateFormatter alloc] init];
    [_shortStyleDateFormatter setDateStyle:NSDateFormatterShortStyle];
    [_shortStyleDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [self registerFormatter:_shortStyleDateFormatter withName:OX_SHORT_STYLE_DATE_FORMATTER];
    
    NSNumberFormatter *_currencyFormatter = [[NSNumberFormatter alloc] init];
    [_currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [self registerFormatter:_currencyFormatter withName:OX_CURRENCY_FORMATTER];
    
    NSNumberFormatter *_percentageFormatter = [[NSNumberFormatter alloc] init];
    [_percentageFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    [self registerFormatter:_percentageFormatter withName:OX_PERCENTAGE_FORMATTER];
    
    NSNumberFormatter *_decimalFormatter = [[NSNumberFormatter alloc] init];
    [_decimalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [self registerFormatter:_decimalFormatter withName:OX_DECIMAL_FORMATTER];
}


@end
