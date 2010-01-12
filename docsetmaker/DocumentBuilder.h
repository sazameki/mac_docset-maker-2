//
//  DSManager.h
//  docsetmaker
//
//  Created by numata on 09/09/19.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DocumentBuilder : NSObject {
    NSString    *mSourceDirPath;
    NSString    *mDestDirPath;
    NSString    *mTemplateDirPath;
    BOOL        mUsesDocsetPackage;
    BOOL        mSearchesRecursively;
    BOOL        mIsVerbose;
    BOOL        mUpdatesOuterDocsOnly;
    NSArray     *mPriorGroupNames;
}

- (NSArray *)priorGroupNames;

- (void)setSourceDirPath:(NSString *)path;
- (void)setDestDirPath:(NSString *)path;
- (void)setTemplateDirPath:(NSString *)path;
- (void)setUsesDocsetPackage:(BOOL)flag;
- (void)setSearchesRecursively:(BOOL)flag;
- (void)setIsVerbose:(BOOL)flag;
- (void)setUpdatesOuterDocsOnly:(BOOL)flag;

- (void)build;

@end


extern DocumentBuilder *gDocumentBuilderInst;

