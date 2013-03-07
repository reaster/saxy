//
//  OXUtil.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 2/10/13.
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

+ (BOOL)allDigits:(NSString *)text
{
    static NSCharacterSet *_digitChars;   
    if ( _digitChars == nil ) {
        _digitChars = [NSCharacterSet characterSetWithCharactersInString:@".-+0123456789"];
    }
    if (!text)
        return NO;
    int len = [text length];
    for(int i=0;i<len;i++) {
        if (![_digitChars characterIsMember:[text characterAtIndex:i]])
            return NO;
    }
    return YES;
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

#pragma mark - file

+ (NSData *)readResourceFile:(NSString *)fileName
{
    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSString *filePath = [resourcePath stringByAppendingPathComponent:fileName];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    return data;
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
            return @"*";
            case '{': return @"struct";
            case 'b': return @"bitfield";
            case '(': return @"union";
            case '[': return @"c array";
            case 'v': return @"void";
            case '*': return @"char *";
            case '#': return @"Class";
            case ':': return @"selector";
            case '?':   // BOOL encoding: '?B'
                if (strlen(encodedType)>typeIndex+1 && encodedType[typeIndex+1]=='B') {//BOOL encoding for properties
                    return @"BOOL";
                } else {
                    return @"void *"; //unknown type (function pointer, etc)
                }
            default:
                return @"?";
        }
    }
    return @"?";
}

+ (BOOL)knownSimpleType:(Class)type
{
    return ([type isSubclassOfClass:[NSString class]]      ||
            [type isSubclassOfClass:[NSValue class]]       ||
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
            const char *attr = property_getAttributes(*prop);
            if (attr) {
                Class propertyClass = [[self class] kvcClassForScalar:attr];
                if (propertyClass) {
                    NSString *propNameString = [[NSString alloc] initWithCString:propName encoding:NSUTF8StringEncoding];
                    if (propNameString) {
                        block(propNameString, propertyClass, attr);
                    }
                }
            }
        }
        free(propList);
        currentClass = [currentClass superclass];
    }//while loop
}



#pragma mark - base64

//the following base64 code is taken from the google-toolbox-for-mac: https://code.google.com/p/google-toolbox-for-mac/
//Copyright 2006-2008 Google Inc.

static const char *kBase64EncodeChars        = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
//static const char *kWebSafeBase64EncodeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
static const char kBase64PaddingChar = '=';
static const char kBase64InvalidChar = 99;

static const char kBase64DecodeChars[] = {
    // This array was generated by the following code:
    // #include <sys/time.h>
    // #include <stdlib.h>
    // #include <string.h>
    // main()
    // {
    //   static const char Base64[] =
    //     "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    //   char *pos;
    //   int idx, i, j;
    //   printf("    ");
    //   for (i = 0; i < 255; i += 8) {
    //     for (j = i; j < i + 8; j++) {
    //       pos = strchr(Base64, j);
    //       if ((pos == NULL) || (j == 0))
    //         idx = 99;
    //       else
    //         idx = pos - Base64;
    //       if (idx == 99)
    //         printf(" %2d,     ", idx);
    //       else
    //         printf(" %2d/*%c*/,", idx, j);
    //     }
    //     printf("\n    ");
    //   }
    // }
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      62/*+*/, 99,      99,      99,      63/*/ */,
    52/*0*/, 53/*1*/, 54/*2*/, 55/*3*/, 56/*4*/, 57/*5*/, 58/*6*/, 59/*7*/,
    60/*8*/, 61/*9*/, 99,      99,      99,      99,      99,      99,
    99,       0/*A*/,  1/*B*/,  2/*C*/,  3/*D*/,  4/*E*/,  5/*F*/,  6/*G*/,
    7/*H*/,  8/*I*/,  9/*J*/, 10/*K*/, 11/*L*/, 12/*M*/, 13/*N*/, 14/*O*/,
    15/*P*/, 16/*Q*/, 17/*R*/, 18/*S*/, 19/*T*/, 20/*U*/, 21/*V*/, 22/*W*/,
    23/*X*/, 24/*Y*/, 25/*Z*/, 99,      99,      99,      99,      99,
    99,      26/*a*/, 27/*b*/, 28/*c*/, 29/*d*/, 30/*e*/, 31/*f*/, 32/*g*/,
    33/*h*/, 34/*i*/, 35/*j*/, 36/*k*/, 37/*l*/, 38/*m*/, 39/*n*/, 40/*o*/,
    41/*p*/, 42/*q*/, 43/*r*/, 44/*s*/, 45/*t*/, 46/*u*/, 47/*v*/, 48/*w*/,
    49/*x*/, 50/*y*/, 51/*z*/, 99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99,
    99,      99,      99,      99,      99,      99,      99,      99
};

// Tests a character to see if it's a whitespace character.
//
// Returns:
//   YES if the character is a whitespace character.
//   NO if the character is not a whitespace character.
//
static BOOL IsSpace(unsigned char c) {
    // we use our own mapping here because we don't want anything w/ locale
    // support.
    static BOOL kSpaces[256] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1,  // 0-9
        1, 1, 1, 1, 0, 0, 0, 0, 0, 0,  // 10-19
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 20-29
        0, 0, 1, 0, 0, 0, 0, 0, 0, 0,  // 30-39
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 40-49
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 50-59
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 60-69
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 70-79
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 80-89
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 90-99
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 100-109
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 110-119
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 120-129
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 130-139
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 140-149
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 150-159
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 160-169
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 170-179
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 180-189
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 190-199
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 200-209
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 210-219
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 220-229
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 230-239
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 240-249
        0, 0, 0, 0, 0, 1,              // 250-255
    };
    return kSpaces[c];
}

// Calculate how long the data will be once it's base64 encoded.
//
// Returns:
//   The guessed encoded length for a source length
//
static NSUInteger CalcEncodedLength(NSUInteger srcLen, BOOL padded) {
    NSUInteger intermediate_result = 8 * srcLen + 5;
    NSUInteger len = intermediate_result / 6;
    if (padded) {
        len = ((len + 3) / 4) * 4;
    }
    return len;
}

// Tries to calculate how long the data will be once it's base64 decoded.
// Unlike the above, this is always an upperbound, since the source data
// could have spaces and might end with the padding characters on them.
//
// Returns:
//   The guessed decoded length for a source length
//
static NSUInteger GuessDecodedLength(NSUInteger srcLen) {
    return (srcLen + 3) / 4 * 3;
}



+(NSString *)base64StringByEncodingData:(NSData *)data {
    NSString *result = nil;
    NSData *converted = [self baseEncode:[data bytes]
                                  length:[data length]
                                 charset:kBase64EncodeChars
                                  padded:YES];
    if (converted) {
        result = [[NSString alloc] initWithData:converted encoding:NSASCIIStringEncoding];
    }
    return result;
}

+(NSData *)decodeBase64String:(NSString *)string {
    NSData *result = nil;
    NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
    if (data) {
        result = [self baseDecode:[data bytes]
                           length:[data length]
                          charset:kBase64DecodeChars
                   requirePadding:YES];
    }
    return result;
}

//
// baseEncode:length:charset:padded:
//
// Does the common lifting of creating the dest NSData.  it creates & sizes the
// data for the results.  |charset| is the characters to use for the encoding
// of the data.  |padding| controls if the encoded data should be padded to a
// multiple of 4.
//
// Returns:
//   an autorelease NSData with the encoded data, nil if any error.
//
+(NSData *)baseEncode:(const void *)bytes
               length:(NSUInteger)length
              charset:(const char *)charset
               padded:(BOOL)padded {
    // how big could it be?
    NSUInteger maxLength = CalcEncodedLength(length, padded);
    // make space
    NSMutableData *result = [NSMutableData data];
    [result setLength:maxLength];
    // do it
    NSUInteger finalLength = [self baseEncode:bytes
                                       srcLen:length
                                    destBytes:[result mutableBytes]
                                      destLen:[result length]
                                      charset:charset
                                       padded:padded];
    if (finalLength) {
        NSAssert(finalLength == maxLength, @"how did we calc the length wrong?");
    } else {
        // shouldn't happen, this means we ran out of space
        result = nil;
    }
    return result;
}

//
// baseDecode:length:charset:requirePadding:
//
// Does the common lifting of creating the dest NSData.  it creates & sizes the
// data for the results.  |charset| is the characters to use for the decoding
// of the data.
//
// Returns:
//   an autorelease NSData with the decoded data, nil if any error.
//
//
+(NSData *)baseDecode:(const void *)bytes
               length:(NSUInteger)length
              charset:(const char *)charset
       requirePadding:(BOOL)requirePadding {
    // could try to calculate what it will end up as
    NSUInteger maxLength = GuessDecodedLength(length);
    // make space
    NSMutableData *result = [NSMutableData data];
    [result setLength:maxLength];
    // do it
    NSUInteger finalLength = [self baseDecode:bytes
                                       srcLen:length
                                    destBytes:[result mutableBytes]
                                      destLen:[result length]
                                      charset:charset
                               requirePadding:requirePadding];
    if (finalLength) {
        if (finalLength != maxLength) {
            // resize down to how big it was
            [result setLength:finalLength];
        }
    } else {
        // either an error in the args, or we ran out of space
        result = nil;
    }
    return result;
}

//
// baseEncode:srcLen:destBytes:destLen:charset:padded:
//
// Encodes the buffer into the larger.  returns the length of the encoded
// data, or zero for an error.
// |charset| is the characters to use for the encoding
// |padded| tells if the result should be padded to a multiple of 4.
//
// Returns:
//   the length of the encoded data.  zero if any error.
//
+(NSUInteger)baseEncode:(const char *)srcBytes
                 srcLen:(NSUInteger)srcLen
              destBytes:(char *)destBytes
                destLen:(NSUInteger)destLen
                charset:(const char *)charset
                 padded:(BOOL)padded {
    if (!srcLen || !destLen || !srcBytes || !destBytes) {
        return 0;
    }
    
    char *curDest = destBytes;
    const unsigned char *curSrc = (const unsigned char *)(srcBytes);
    
    // Three bytes of data encodes to four characters of cyphertext.
    // So we can pump through three-byte chunks atomically.
    while (srcLen > 2) {
        // space?
        NSAssert(destLen >= 4, @"our calc for encoded length was wrong");
        curDest[0] = charset[curSrc[0] >> 2];
        curDest[1] = charset[((curSrc[0] & 0x03) << 4) + (curSrc[1] >> 4)];
        curDest[2] = charset[((curSrc[1] & 0x0f) << 2) + (curSrc[2] >> 6)];
        curDest[3] = charset[curSrc[2] & 0x3f];
        
        curDest += 4;
        curSrc += 3;
        srcLen -= 3;
        destLen -= 4;
    }
    
    // now deal with the tail (<=2 bytes)
    switch (srcLen) {
        case 0:
            // Nothing left; nothing more to do.
            break;
        case 1:
            // One byte left: this encodes to two characters, and (optionally)
            // two pad characters to round out the four-character cypherblock.
            NSAssert(destLen >= 2, @"our calc for encoded length was wrong");
            curDest[0] = charset[curSrc[0] >> 2];
            curDest[1] = charset[(curSrc[0] & 0x03) << 4];
            curDest += 2;
            if (padded) {
                NSAssert(destLen >= 4, @"our calc for encoded length was wrong");
                curDest[0] = kBase64PaddingChar;
                curDest[1] = kBase64PaddingChar;
                curDest += 2;
            }
            break;
        case 2:
            // Two bytes left: this encodes to three characters, and (optionally)
            // one pad character to round out the four-character cypherblock.
            NSAssert(destLen >= 3, @"our calc for encoded length was wrong");
            curDest[0] = charset[curSrc[0] >> 2];
            curDest[1] = charset[((curSrc[0] & 0x03) << 4) + (curSrc[1] >> 4)];
            curDest[2] = charset[(curSrc[1] & 0x0f) << 2];
            curDest += 3;
            if (padded) {
                NSAssert(destLen >= 4, @"our calc for encoded length was wrong");
                curDest[0] = kBase64PaddingChar;
                curDest += 1;
            }
            break;
    }
    // return the length
    return (curDest - destBytes);
}

//
// baseDecode:srcLen:destBytes:destLen:charset:requirePadding:
//
// Decodes the buffer into the larger.  returns the length of the decoded
// data, or zero for an error.
// |charset| is the character decoding buffer to use
//
// Returns:
//   the length of the encoded data.  zero if any error.
//
+(NSUInteger)baseDecode:(const char *)srcBytes
                 srcLen:(NSUInteger)srcLen
              destBytes:(char *)destBytes
                destLen:(NSUInteger)destLen
                charset:(const char *)charset
         requirePadding:(BOOL)requirePadding {
    if (!srcLen || !destLen || !srcBytes || !destBytes) {
        return 0;
    }
    
    int decode;
    NSUInteger destIndex = 0;
    int state = 0;
    char ch = 0;
    while (srcLen-- && (ch = *srcBytes++) != 0)  {
        if (IsSpace(ch))  // Skip whitespace
            continue;
        
        if (ch == kBase64PaddingChar)
            break;
        
        decode = charset[(unsigned int)ch];
        if (decode == kBase64InvalidChar)
            return 0;
        
        // Four cyphertext characters decode to three bytes.
        // Therefore we can be in one of four states.
        switch (state) {
            case 0:
                // We're at the beginning of a four-character cyphertext block.
                // This sets the high six bits of the first byte of the
                // plaintext block.
                NSAssert(destIndex < destLen, @"our calc for decoded length was wrong");
                destBytes[destIndex] = decode << 2;
                state = 1;
                break;
            case 1:
                // We're one character into a four-character cyphertext block.
                // This sets the low two bits of the first plaintext byte,
                // and the high four bits of the second plaintext byte.
                NSAssert((destIndex+1) < destLen, @"our calc for decoded length was wrong");
                destBytes[destIndex] |= decode >> 4;
                destBytes[destIndex+1] = (decode & 0x0f) << 4;
                destIndex++;
                state = 2;
                break;
            case 2:
                // We're two characters into a four-character cyphertext block.
                // This sets the low four bits of the second plaintext
                // byte, and the high two bits of the third plaintext byte.
                // However, if this is the end of data, and those two
                // bits are zero, it could be that those two bits are
                // leftovers from the encoding of data that had a length
                // of two mod three.
                NSAssert((destIndex+1) < destLen, @"our calc for decoded length was wrong");
                destBytes[destIndex] |= decode >> 2;
                destBytes[destIndex+1] = (decode & 0x03) << 6;
                destIndex++;
                state = 3;
                break;
            case 3:
                // We're at the last character of a four-character cyphertext block.
                // This sets the low six bits of the third plaintext byte.
                NSAssert(destIndex < destLen, @"our calc for decoded length was wrong");
                destBytes[destIndex] |= decode;
                destIndex++;
                state = 0;
                break;
        }
    }
    
    // We are done decoding Base-64 chars.  Let's see if we ended
    //      on a byte boundary, and/or with erroneous trailing characters.
    if (ch == kBase64PaddingChar) {               // We got a pad char
        if ((state == 0) || (state == 1)) {
            return 0;  // Invalid '=' in first or second position
        }
        if (srcLen == 0) {
            if (state == 2) { // We run out of input but we still need another '='
                return 0;
            }
            // Otherwise, we are in state 3 and only need this '='
        } else {
            if (state == 2) {  // need another '='
                while ((ch = *srcBytes++) && (srcLen-- > 0)) {
                    if (!IsSpace(ch))
                        break;
                }
                if (ch != kBase64PaddingChar) {
                    return 0;
                }
            }
            // state = 1 or 2, check if all remain padding is space
            while ((ch = *srcBytes++) && (srcLen-- > 0)) {
                if (!IsSpace(ch)) {
                    return 0;
                }
            }
        }
    } else {
        // We ended by seeing the end of the string.
        
        if (requirePadding) {
            // If we require padding, then anything but state 0 is an error.
            if (state != 0) {
                return 0;
            }
        } else {
            // Make sure we have no partial bytes lying around.  Note that we do not
            // require trailing '=', so states 2 and 3 are okay too.
            if (state == 1) {
                return 0;
            }
        }
    }
    
    // If then next piece of output was valid and got written to it means we got a
    // very carefully crafted input that appeared valid but contains some trailing
    // bits past the real length, so just toss the thing.
    if ((destIndex < destLen) &&
        (destBytes[destIndex] != 0)) {
        return 0;
    }
    
    return destIndex;
}

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
