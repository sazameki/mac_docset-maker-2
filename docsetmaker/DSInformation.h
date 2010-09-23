//
//  DSInformation.h
//  DocSet Maker
//
//  Created by numata on 09/09/13.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DSInformation : NSObject {
    NSString        *mTagName;
    NSString        *mValue;
    NSMutableArray  *mChildInfos;
    DSInformation   *mParentInfo;
    BOOL            mIsDeprecated;
}

- (id)initWithTag:(NSString *)tag;


#pragma mark -

- (NSString *)tagName;
- (NSString *)value;
- (void)setValue:(NSString *)value;
- (DSInformation *)parentInfo;
- (void)setParentInfo:(DSInformation *)anInfo;


#pragma mark -

- (BOOL)appendValue:(NSString *)value;

- (void)addChildInformation:(DSInformation *)anInfo;

- (NSArray *)childInfosWithTag:(NSString *)tag;
- (NSArray *)childInfosWithTags:(NSArray *)tags;
- (NSArray *)allChildInfos;

- (NSString *)languageType;

- (BOOL)hasChildWithTag:(NSString *)tag;

- (NSString *)declaration;
- (NSString *)abstractStr;
- (NSString *)discussion;
- (NSString *)docIdentifier;

- (BOOL)isGroup;

- (BOOL)isInstantVariable;
- (BOOL)isInstantMethod;
- (BOOL)isClassMethod;

- (BOOL)isDeprecated;
- (void)setDeprecated:(BOOL)flag;

- (NSString *)rubyScriptForParent:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName;

@end


int DSCompareInfo(id anInfo1, id anInfo2, void *context);


