//
//  NSString+Tokenizer.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/03.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "NSString+Tokenizer.h"


@interface _NMStringTokenizerEnumerator : NSEnumerator {
    NSString        *mStr;
    NSCharacterSet  *mDelimiterSet;
    unsigned        mPos;
}

- (id)initWithString:(NSString *)str charSet:(NSCharacterSet *)delimSet;

- (NSArray *)allObjects;
- (id)nextObject;

@end


@implementation _NMStringTokenizerEnumerator

- (id)initWithString:(NSString *)str charSet:(NSCharacterSet *)delimSet
{
    self = [super init];
    if (self) {
        mStr = str;
        mDelimiterSet = delimSet;
        mPos = 0;
    }
    return self;
}

- (NSArray *)allObjects
{
    NSMutableArray *ret = [NSMutableArray array];
    
    NSObject *anObject = nil;
    while (anObject = [self nextObject]) {
        [ret addObject:anObject];
    }
    
    return ret;
}

- (id)nextObject
{
    unsigned length = [mStr length];
    if (mPos >= length) {
        return nil;
    }
    unsigned startPos = mPos;
    while (startPos < length) {
        unichar c = [mStr characterAtIndex:startPos];
        if (![mDelimiterSet characterIsMember:c]) {
            break;
        }
        startPos++;
    }
    mPos = startPos + 1;
    while (mPos < length) {
        unichar c = [mStr characterAtIndex:mPos];
        if ([mDelimiterSet characterIsMember:c]) {
            break;
        }
        mPos++;
    }
    unsigned subStrLength = mPos - startPos;
    if (subStrLength == 0 || startPos + subStrLength > length) {
        return nil;
    }
    mPos++;
    return [mStr substringWithRange:NSMakeRange(startPos, subStrLength)];
}

@end


@implementation NSString (Tokenizer)

- (NSEnumerator *)tokenize
{
    return [self tokenize:@" \t\r\n"];
}

- (NSEnumerator *)tokenize:(NSString *)delimiters
{
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:delimiters];
    return [[[_NMStringTokenizerEnumerator alloc] initWithString:self charSet:charSet] autorelease];
}

@end


