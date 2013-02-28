//
//  OXUtil.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 2/10/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXUtil.h"
#if (TARGET_OS_IPHONE)
#import <objc/runtime.h>
#import <objc/message.h>
#endif

@implementation OXUtil

#pragma mark - string

+ (NSString *)trim:(NSString *)text
{
    static NSMutableCharacterSet *_whitespaceChars;
    if (_whitespaceChars == nil)
        _whitespaceChars  = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *result = text ? [text stringByTrimmingCharactersInSet:_whitespaceChars] : nil;
    return ([result length] > 0) ? result : nil;
}



+ (int)firstIndexOfChar:(unichar)ch inString:(NSString *)string
{
    if (!string)
        return -1;
    const int len = [string length];
    for(int i=0;i<len;i++) {
        if (ch == [string characterAtIndex:i])
            return i;
    }
    return -1;
}

+ (int)lastIndexOfChar:(unichar)ch inString:(NSString *)string
{
    int result = -1;
    if (string) {
        const int len = [string length];
        for(int i=0;i<len;i++) {
            if (ch == [string characterAtIndex:i])
                result = i;
        }
    }
    return result;
}

+ (NSString *)firstSegmentFromPath:(NSString *)path separator:(unichar)separator
{
    const int index = [[self class] firstIndexOfChar:separator inString:path];     //assume KVC dot-separators
    return index < 0 ? path : [path substringToIndex:index];
}

+ (NSString *)lastSegmentFromPath:(NSString *)path separator:(unichar)separator
{
    const int index = [[self class] lastIndexOfChar:separator inString:path];     //assume KVC dot-separators
    return index < 0 ? path : [path substringFromIndex:index+1];
}


+ (BOOL)isXPathString:(NSString *)string
{
    const static NSCharacterSet *XPATH_CHAR_SET = nil;
    if (XPATH_CHAR_SET == nil)
        XPATH_CHAR_SET = [NSCharacterSet characterSetWithCharactersInString:@"/*"];
    const int len = [string length];
    for(int i=0;i<len;i++) {
        unichar ch = [string characterAtIndex:i];
        if ([XPATH_CHAR_SET characterIsMember:ch]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)xmlSafeString:(NSString *)text
{
    //NSString *result = [[NSXMLNode textWithStringValue:@"test<me>"] XMLString];
    //TODO: not as comprehensive as gtm_stringBySanitizingAndEscapingForXML
    const static NSCharacterSet *XML_ESCAPE_CHAR_SET = nil;
    if (XML_ESCAPE_CHAR_SET == nil)
        XML_ESCAPE_CHAR_SET = [NSCharacterSet characterSetWithCharactersInString:@"&<>\"'"];
    NSMutableString *result = nil;
    const int len = [text length];
    for(int i=0;i<len;i++) {
        unichar ch = [text characterAtIndex:i];
        if ([XML_ESCAPE_CHAR_SET characterIsMember:ch]) {
            if (!result) {   //only create if escaping needed
                result = [NSMutableString stringWithCapacity:len+16];
                if (i>0)
                    [result appendString:[text substringWithRange:NSMakeRange(0,i)]];
            }
            switch (ch) {
                case '&': [result appendString:@"&amp;"]; break;
                case '<': [result appendString:@"&lt;"]; break;
                case '>': [result appendString:@"&gt;"]; break;
                case '"': [result appendString:@"&quot;"]; break;
                case '\'': [result appendString:@"&#39;"]; break;
                default: NSAssert(NO, @"bad character in XNLStringFromString %c", ch); break;
            }
        } else if (result) {
            [result appendString:[text substringWithRange:NSMakeRange(i, 1)]];
        }
    }
    return result ? result : text;
}

#pragma mark - naming

+ (NSString *)guessSingularNoun:(NSString *)pluralNoun
{   //see: http://en.wikipedia.org/wiki/English_plural
    if ([pluralNoun hasSuffix:@"ies"]) {        //kitties -> kitty, babies -> baby, etc. Excpetions: series	-> series, species -> species
        return [NSString stringWithFormat:@"%@y", [pluralNoun substringWithRange:NSMakeRange(0,[pluralNoun length]-3)]];
    } else if ([pluralNoun hasSuffix:@"oes"]) {   // heroes -> hero, potatoes -> potato,	etc.
        return [pluralNoun substringWithRange:NSMakeRange(0,[pluralNoun length]-2)];
    } else if ([pluralNoun hasSuffix:@"sses"]) {   //addresses -> address, kisses -> kiss, etc.
        return [pluralNoun substringWithRange:NSMakeRange(0,[pluralNoun length]-2)];
    } else if ([pluralNoun hasSuffix:@"um"]) {   //datum -> data, addendum -> addenda, etc.
        return [NSString stringWithFormat:@"%@a", [pluralNoun substringWithRange:NSMakeRange(0,[pluralNoun length]-2)]];
    } else if ([pluralNoun hasSuffix:@"ces"]) {   //vertices -> vertex, indices -> index, etc. Excpetions: matrices -> matrix
        return [NSString stringWithFormat:@"%@ex", [pluralNoun substringWithRange:NSMakeRange(0,[pluralNoun length]-3)]];
    } else if ([pluralNoun hasSuffix:@"es"]) {   //axis	-> axes, testis -> testes, etc.
        return [NSString stringWithFormat:@"%@is", [pluralNoun substringWithRange:NSMakeRange(0,[pluralNoun length]-2)]];
    } else if ([pluralNoun hasSuffix:@"s"]) {   //stores -> store, etc.
        return [pluralNoun substringWithRange:NSMakeRange(0,[pluralNoun length]-1)];
    } else {
        return pluralNoun;                      //sheep -> sheep, etc.
    }
}




#pragma mark - reflection

+ (Class)kvcClassForScalar:(const char *)encodedAttributes
{
    if (encodedAttributes) {
        //handle both property attributes (prefixed with 'T') and @encode(type) types:
        const char *encodedType = strchr(encodedAttributes, 'T');
        if (encodedType) {
            encodedType += 1;
        } else {
            encodedType = encodedAttributes;
        }
        // https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
        switch (encodedType[0]) {
            case '@': {
                char *openingQuoteLoc = strchr(encodedType, '"');
                if (openingQuoteLoc) {
                    char *closingQuoteLoc = strchr(openingQuoteLoc+1, '"');
                    if (closingQuoteLoc) {
                        size_t classNameStrLen = closingQuoteLoc-openingQuoteLoc;
                        char className[classNameStrLen];
                        memcpy(className, openingQuoteLoc+1, classNameStrLen-1);
                        className[classNameStrLen-1] = '\0';        // Null-terminate string
                        //printf("%s, ", className);
                        return objc_getClass(className);
                    }
                }
                // If there is no quoted class type (id), it can be used as-is.
                return Nil;
            }
            case 'c': // char
            case 'C': // unsigned char
            case 's': // short
            case 'S': // unsigned short
            case 'i': // int
            case 'I': // unsigned int
            case 'l': // long
            case 'L': // unsigned long
            case 'q': // long long
            case 'Q': // unsigned long long
            case 'f': // float
            case 'd': // double
                return [NSNumber class];
                
            case 'B': // C++ bool or C99 _Bool
                return objc_getClass("NSCFBoolean")
                ?: objc_getClass("__NSCFBoolean")
                ?: [NSNumber class];
                
            case '^': // pointer
                if (strlen(encodedType)>1 && encodedType[1]=='c') //BOOL encoding for properties
                    return [NSNumber class];
            case '{': // struct
            case 'b': // bitfield
            case '(': // union
                return [NSValue class];
                
            case '[': // c array
            case 'v': // void
            case '*': // char *
            case '#': // Class
            case ':': // selector
            case '?': // unknown type (function pointer, etc)
            default:
                break;
        }
    }
    return nil;
}


// https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
+ (NSString *)scalarString:(const char *)encodedType
{
    if (encodedType) {
        int typeIndex = encodedType[0] == 'T' ? 1 : 0;             //works with both @encode() and property encoded types
        char typeChar = encodedType[typeIndex];
        switch (typeChar) {
            case '@': {
                char *openingQuoteLoc = strchr(encodedType, '"');
                if (openingQuoteLoc) {
                    char *closingQuoteLoc = strchr(openingQuoteLoc+1, '"');
                    if (closingQuoteLoc) {
                        size_t classNameStrLen = closingQuoteLoc-openingQuoteLoc;
                        char className[classNameStrLen];
                        memcpy(className, openingQuoteLoc+1, classNameStrLen-1);
                        // Null-terminate the array to stringify
                        className[classNameStrLen-1] = '\0';
                        //printf("%s, ", className);
                        return [NSString stringWithFormat:@"%s *", className];
                    }
                }
                // If there is no quoted class type (id), it can be used as-is.
                return @"id";
            }
            case 'c': return @"char";
            case 'C': return @"unsigned char";
            case 's': return @"short";
            case 'S': return @"unsigned short";
            case 'i': return @"int";
            case 'I': return @"unsigned int";
            case 'l': return @"long";
            case 'L': return @"unsigned long";
            case 'q': return @"long long";
            case 'Q': return @"unsigned long long";
            case 'f': return @"float";
            case 'd': return @"double";
            case 'B': // C++ bool or C99 _Bool
                return @"NSCFBoolean";
            case '^': // pointer
                if (strlen(encodedType)>typeIndex+1 && encodedType[typeIndex+1]=='c') {//BOOL encoding for properties
                    return @"BOOL";
                } else {
                    return @"*";
                }
            case '{': return @"struct";
            case 'b': return @"bitfield";
            case '(': return @"union";
            case '[': return @"c array";
            case 'v': return @"void";
            case '*': return @"char *";
            case '#': return @"Class";
            case ':': return @"selector";
            case '?': return @"void *"; //unknown type (function pointer, etc)
            default:
                return @"?";
        }
    }
    return @"?";
}

+ (BOOL)knownSimpleType:(Class)type
{
    return ([type isSubclassOfClass:[NSString class]]      ||
            [type isSubclassOfClass:[NSNumber class]]      ||
            [type isSubclassOfClass:[NSDate class]]        ||
            [type isSubclassOfClass:[NSURL class]]         ||
            [type isSubclassOfClass:[NSLocale class]]      ||
            [type isSubclassOfClass:[NSTimeZone class]]    ||
            [type isSubclassOfClass:[NSUUID class]]
            );
    
}


+ (BOOL)knownCollectionType:(Class)objectClass
{
    return ([objectClass isSubclassOfClass:[NSDictionary class]]    ||
            [objectClass isSubclassOfClass:[NSSet class]]           ||
            [objectClass isSubclassOfClass:[NSArray class]]         ||
            [objectClass isSubclassOfClass:[NSOrderedSet class]]
            //NSIndexSet ?
            );
}

+ (void)propertyInspectionForClass:(Class)objectClass withBlock:(OCPropertyMetadataBlock)block
{
    //include superclass properties, excluding NSObject
    Class currentClass = objectClass;
    while (currentClass != nil && ![[NSObject class] isSubclassOfClass:currentClass]) {
        // Get the raw list of properties
        unsigned int outCount = 0;
        objc_property_t *propList = class_copyPropertyList(currentClass, &outCount);
        // Collect the property names
        for (typeof(outCount) i = 0; i < outCount; i++) {
            objc_property_t *prop = propList + i;
            const char *propName = property_getName(*prop);
            if (strcmp(propName, "_mapkit_hasPanoramaID") != 0) {
                const char *attr = property_getAttributes(*prop);
                if (attr) {
                    Class propertyClass = [[self class] kvcClassForScalar:attr];
                    if (propertyClass) {
                        NSString *propNameString = [[NSString alloc] initWithCString:propName encoding:NSUTF8StringEncoding];
                        //NSString *attributes = attr ? [[NSString alloc] initWithCString:attr encoding:NSUTF8StringEncoding] : nil;
                        //NSArray *propAttributes = attributes ? [attributes componentsSeparatedByString:@","] : [NSArray array];
                        if (propNameString) {
                            block(propNameString, propertyClass, attr);
                        }
                    }
                }
            }
        }
        free(propList);
        currentClass = [currentClass superclass];
    }//while loop
}


@end
