//
//  DSCommentParser.m
//  DocSet Maker
//
//  Created by numata on 09/09/13.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "DSCommentParser.h"
#import "DSInfoRepository.h"


@implementation DSCommentParser

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        mPath = [path retain];
        
        NSError *error = nil;
        mSource = [[NSString alloc] initWithContentsOfFile:mPath encoding:NSUTF8StringEncoding error:&error];
        if (!mSource) {
            NSLog(@"Error: %@", error);
            [self release];
            return nil;
        }
        
        mPos = 0;
        mLength = [mSource length];
        mInfos = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc
{
    [mSource release];
    [mPath release];
    [mInfos release];
    [super dealloc];
}

- (BOOL)hasMoreCharacters
{
    return (mPos < mLength);
}

- (unichar)lookAtNextCharacter
{
    if (![self hasMoreCharacters]) {
        [NSException raise:@"Comment Parse Error" format:@"Illegal End of File", nil];
    }
    return [mSource characterAtIndex:mPos];
}

- (unichar)lookAtNextNextCharacter
{
    if (mPos+1 >= mLength) {
        [NSException raise:@"Comment Parse Error" format:@"Illegal End of File", nil];
    }
    return [mSource characterAtIndex:mPos+1];
}

- (unichar)getNextCharacter
{
    if (![self hasMoreCharacters]) {
        [NSException raise:@"Comment Parse Error" format:@"Illegal End of File", nil];
    }
    return [mSource characterAtIndex:mPos++];
}

- (void)skipNextCharacter
{
    if (![self hasMoreCharacters]) {
        [NSException raise:@"Comment Parse Error" format:@"Illegal End of File", nil];
    }
    mPos++;
}

- (void)skipWhiteSpaces
{
    while ([self hasMoreCharacters]) {
        unichar c = [self lookAtNextCharacter];
        if (isspace((int)c)) {
            mPos++;
        } else {
            break;
        }
    }
}

- (void)skipString
{
    unichar startC = [self getNextCharacter];
    while ([self hasMoreCharacters]) {
        unichar endC = [self getNextCharacter];
        if (endC == startC) {
            break;
        }
    }
}

- (void)skipWhiteSpacesAndString
{
    while ([self hasMoreCharacters]) {
        unichar c = [self lookAtNextCharacter];
        if (isspace((int)c)) {
            [self skipWhiteSpaces];
        } else if (c == '\'' || c == '"') {
            [self skipString];
        } else {
            break;
        }
    }
}

- (NSString *)getStringUntilWhiteSpace
{
    unsigned startPos = mPos;
    while ([self hasMoreCharacters]) {
        unichar c = [self lookAtNextCharacter];
        if (isspace((int)c)) {
            break;
        }
        [self skipNextCharacter];
    }
    unsigned length = mPos - startPos;
    return [mSource substringWithRange:NSMakeRange(startPos, length)];
}

- (NSString *)getStringUntilLineEnd
{
    unsigned startPos = mPos;
    while ([self hasMoreCharacters]) {
        unichar c = [self lookAtNextCharacter];
        if (c == '\r' || c == '\n') {
            break;
        }
        [self skipNextCharacter];
    }
    unsigned length = mPos - startPos;
    return [mSource substringWithRange:NSMakeRange(startPos, length)];
}

- (BOOL)parseNormalComment
{
    DSInformation *currentInfo = nil;
    DSInformation *prevInfo = nil;

    unichar startC = [self lookAtNextCharacter];   // Should be '!' if HeaderDoc comment
    if (startC == '!') {
        [self skipNextCharacter];
    }
    
    while ([self hasMoreCharacters]) {
        [self skipWhiteSpaces];
        
        unichar c1 = [self lookAtNextCharacter];
        unichar c2 = [self lookAtNextNextCharacter];

        if (c1 == '*' && c2 == '/') {
            mPos += 2;
            break;
        }
        
        if (c1 == '@') {
            NSString *tagName = [self getStringUntilWhiteSpace];
            [self skipWhiteSpaces];            
            NSString *line = [self getStringUntilLineEnd];
            
            if (!currentInfo) {
                currentInfo = [[DSInformation alloc] initWithTag:tagName];
                [currentInfo setValue:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                
                if ([tagName isEqualToString:@"@class"] || [tagName isEqualToString:@"@struct"]) {
                    mCurrentClassLevelInfo = currentInfo;
                    [mInfos addObject:currentInfo];
                } else if ([tagName isEqualToString:@"@function"]) {
                    mCurrentClassLevelInfo = nil;
                } else if ([tagName isEqualToString:@"@enum"]) {
                    mCurrentClassLevelInfo = nil;
                }

                DSInformation *declaredInInfo = [[DSInformation alloc] initWithTag:@"*declared-in"];
                [declaredInInfo setValue:mPath];
                [currentInfo addChildInformation:declaredInInfo];
            } else {
                prevInfo = [[DSInformation alloc] initWithTag:tagName];
                [prevInfo setValue:line];
                [currentInfo addChildInformation:prevInfo];
            }
        } else {
            BOOL isAtCommentEnd = NO;
            NSMutableString *line = [[NSMutableString alloc] init];
            while ([self hasMoreCharacters]) {
                unichar c = [self getNextCharacter];
                if (c == '\r' || c == '\n') {
                    break;
                }
                if (c == '*') {
                    unichar c2 = [self lookAtNextCharacter];
                    if (c2 == '/') {
                        [self skipNextCharacter];
                        isAtCommentEnd = YES;
                        break;
                    }
                }
                [line appendFormat:@"%C", c];
            }
            if (!prevInfo) {
                prevInfo = [[DSInformation alloc] initWithTag:@"@discussion"];
                if (currentInfo) {
                    [currentInfo addChildInformation:prevInfo];
                }
            }
            if (![prevInfo appendValue:line]) {
                prevInfo = [[DSInformation alloc] initWithTag:@"@discussion"];
                [prevInfo appendValue:line];
                if (currentInfo) {
                    [currentInfo addChildInformation:prevInfo];
                }
            }
            if (isAtCommentEnd) {
                break;
            }
        }
    }
    
    if (startC == '!' && currentInfo) {
        if (mCurrentClassLevelInfo) {
            if (currentInfo != mCurrentClassLevelInfo) {
                [mCurrentClassLevelInfo addChildInformation:currentInfo];
            }
        } else {
            [mInfos addObject:currentInfo];
        }
    }
    
    mLastInfo = currentInfo;
    return (currentInfo? YES: NO);
}

- (void)parseLineComment
{
    //NSMutableString *comment = [NSMutableString stringWithString:@"//"];
    while ([self hasMoreCharacters]) {
        unichar c = [self getNextCharacter];
        if (c == '\r' || c == '\n') {
            // Currently we just skip line comments
            break;
        }
        //[comment appendFormat:@"%C", c];
    }
}

- (BOOL)parse
{
    @try {
        int braceLevel = 0;
        int classLevelBraceLevel = 0;
        
        while ([self hasMoreCharacters]) {
            [self skipWhiteSpacesAndString];
            
            if (![self hasMoreCharacters]) {
                break;
            }

            unichar c1 = [self getNextCharacter];
            if (c1 == '/') {
                unichar c2 = [self getNextCharacter];
                if (c2 == '*') {
                    if ([self parseNormalComment]) {
                        [self skipWhiteSpaces];
                        
                        if (![[mLastInfo tagName] isEqualToString:@"@task"]) {
                            int declBraceLevel =  braceLevel;
                            unichar c1 = [self lookAtNextCharacter];
                            
                            NSMutableString *declStr = [NSMutableString string];
                            while ([self hasMoreCharacters]) {
                                unichar c = [self getNextCharacter];
                                if (c == '{' || c == ';' || c == '\r' || c== '\n') {
                                    if (c == '{') {
                                        braceLevel++;
                                    }
                                    break;
                                }
                                [declStr appendFormat:@"%C", c];
                                
                                // Support for Macros
                                if (c1 == '#' && c == ')') {
                                    break;
                                }
                            }
                            
                            DSInformation *declInfo = [[[DSInformation alloc] initWithTag:@"@declare"] autorelease];
                            [declInfo setValue:[declStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                            [mLastInfo addChildInformation:declInfo];
                            
                            if ([[mLastInfo tagName] isEqualToString:@"@class"] || [[mLastInfo tagName] isEqualToString:@"@struct"]) {
                                classLevelBraceLevel = declBraceLevel;
                            }
                        }                        
                    }
                } else if (c2 == '/') {
                    [self parseLineComment];
                } else if (c2 == '{') {
                    braceLevel++;
                } else if (c2 == '}') {
                    braceLevel--;
                    if (classLevelBraceLevel == braceLevel) {
                        mCurrentClassLevelInfo = nil;
                    }
                }
            } else if (c1 == '{') {
                braceLevel++;
            } else if (c1 == '}') {
                braceLevel--;
                if (classLevelBraceLevel == braceLevel) {
                    mCurrentClassLevelInfo = nil;
                }
            }
        }
    } @catch (NSException *e) {
    } @finally {
        [[DSInfoRepository sharedRepository] addInfos:mInfos];
    }

    return YES;
}

@end



