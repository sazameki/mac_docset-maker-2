//
//  DSManager.m
//  docsetmaker
//
//  Created by numata on 09/09/19.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "DocumentBuilder.h"
#import "DSInfoRepository.h"
#import "DSCommentParser.h"
#import "DSTemplateManager.h"


@implementation DocumentBuilder

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [mSourceDirPath release];
    [mDestDirPath release];
    [mTemplateDirPath release];

    [super dealloc];
}

#pragma mark -

- (void)setSourceDirPath:(NSString *)path
{
    [mSourceDirPath release];
    mSourceDirPath = [path retain];
}

- (void)setDestDirPath:(NSString *)path
{
    [mDestDirPath release];
    mDestDirPath = [path retain];
}

- (void)setTemplateDirPath:(NSString *)path
{
    [mTemplateDirPath release];
    mTemplateDirPath = [path retain];
}

- (void)setUsesDocsetPackage:(BOOL)flag
{
    mUsesDocsetPackage = flag;
}

- (void)setIsVerbose:(BOOL)flag
{
    mIsVerbose = flag;
}

- (void)setSearchesRecursively:(BOOL)flag
{
    mSearchesRecursively = flag;
}

- (void)setUpdatesOuterDocsOnly:(BOOL)flag
{
    mUpdatesOuterDocsOnly = flag;
}


#pragma mark -

- (NSArray *)findTargetHeaderFilesFromPath:(NSString *)path recursively:(BOOL)recursively
{
    NSMutableArray *ret = [NSMutableArray array];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    path = [path stringByExpandingTildeInPath];
    NSURL *theURL = [NSURL fileURLWithPath:path];
    path = [theURL path];

    if (![fileManager fileExistsAtPath:path]) {
        [NSException raise:@"Error" format:@"Source path does not exist: %@", path];
    }

    NSArray *files = [fileManager directoryContentsAtPath:path];
    for (int i = 0; i < [files count]; i++) {
        NSString *aFile = [files objectAtIndex:i];
        NSString *aFilePath = [path stringByAppendingPathComponent:aFile];
        BOOL isDir;
        if ([fileManager fileExistsAtPath:aFilePath isDirectory:&isDir]) {
            if (recursively && isDir) {
                [ret addObjectsFromArray:[self findTargetHeaderFilesFromPath:aFilePath recursively:recursively]];
            } else {
                NSString *ext = [[aFile pathExtension] lowercaseString];
                if ([ext isEqualToString:@"h"]) {
                    [ret addObject:aFilePath];
                }
            }
        }
    }

    return ret;
}

- (NSArray *)findTargetHeaderFiles
{
    return [self findTargetHeaderFilesFromPath:mSourceDirPath recursively:mSearchesRecursively];
}

- (void)deleteDirectory:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        return;
    }
    
    if (mIsVerbose) {
        printf("Deleting directory: %s\n", [path cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
}

- (void)makeDirectories:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        return;
    }
    
    NSString *basePath = [path stringByDeletingLastPathComponent];
    [self makeDirectories:basePath];
    
    if (mIsVerbose) {
        printf("Making directory: %s\n", [[path stringByAbbreviatingWithTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    [fileManager createDirectoryAtPath:path attributes:nil];
}


#pragma mark -

- (void)build
{
    if (!mDestDirPath || [mDestDirPath length] == 0) {
        [NSException raise:@"Error" format:@"Destination path is not specified.", nil];
    }
    if (!mSourceDirPath || [mSourceDirPath length] == 0) {
        [NSException raise:@"Error" format:@"Source path is not specified.", nil];
    }
    
    if (mIsVerbose) {
        printf("Dest dir: %s\n", [mDestDirPath cStringUsingEncoding:NSUTF8StringEncoding]);
        printf("Source dir: %s\n", [mSourceDirPath cStringUsingEncoding:NSUTF8StringEncoding]);
        printf("Template dir: %s\n", [mTemplateDirPath cStringUsingEncoding:NSUTF8StringEncoding]);
        printf("Recursively: %s\n", (mSearchesRecursively? "YES": "NO"));
    }
 
    if (!mUpdatesOuterDocsOnly) {
        [[DSInfoRepository sharedRepository] clearAllInfos];

        NSArray *targetHeaderFiles = [self findTargetHeaderFiles];
        if ([targetHeaderFiles count] == 0) {
            [NSException raise:@"Error" format:@"No header files found.", nil];
        }
        
        for (int i = 0; i < [targetHeaderFiles count]; i++) {
            NSString *aTargetFilePath = [targetHeaderFiles objectAtIndex:i];
            if (mIsVerbose) {
                printf("Parsing: %s\n", [[aTargetFilePath lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding]);
            }
            DSCommentParser *parser = [[DSCommentParser alloc] initWithPath:aTargetFilePath];
            [parser parse];
            [parser release];
        }
        
        if (mIsVerbose) {
            [[DSInfoRepository sharedRepository] outputVerboseInformation];
        }
    }
    
    DSTemplateManager *templateManager = [[DSTemplateManager alloc] initWithPath:mTemplateDirPath];
    
    NSString *baseDirPath = nil;
    NSString *reflibDirPath = nil;
    if (mUsesDocsetPackage) {
        NSString *docSetPath = [mDestDirPath stringByAppendingPathComponent:@"MyDocSet.docset"];
        NSString *contentsDirPath = [docSetPath stringByAppendingPathComponent:@"Contents"];
        NSString *resourcesDirPath = [contentsDirPath stringByAppendingPathComponent:@"Resources"];
        baseDirPath = resourcesDirPath;
        reflibDirPath = [resourcesDirPath stringByAppendingPathComponent:@"referencelibrary"];
        if (!mUpdatesOuterDocsOnly) {
            [self deleteDirectory:docSetPath];
        }
    } else {
        NSString *documentPath = [mDestDirPath stringByAppendingPathComponent:@"document"];
        baseDirPath = documentPath;
        reflibDirPath = [documentPath stringByAppendingPathComponent:@"referencelibrary"];
        if (!mUpdatesOuterDocsOnly) {
            [self deleteDirectory:documentPath];
        }
    }
    
    if (!mUpdatesOuterDocsOnly) {
        [self makeDirectories:reflibDirPath];

        DSTemplate *indexTemplate = [templateManager templateForType:DSTemplateTypeIndex];
        [indexTemplate outputAtPath:[reflibDirPath stringByAppendingPathComponent:@"index.html"] baseInfo:nil];

        DSTemplate *listTemplate = [templateManager templateForType:DSTemplateTypeList];
        [listTemplate outputAtPath:[reflibDirPath stringByAppendingPathComponent:@"list.html"] baseInfo:nil];

        DSTemplate *tocTemplate = [templateManager templateForType:DSTemplateTypeTOC];
        [tocTemplate outputAtPath:[reflibDirPath stringByAppendingPathComponent:@"toc.html"] baseInfo:nil];
        
        // Write out groups
        DSTemplate *classTemplate = [templateManager templateForType:DSTemplateTypeClass];
        DSTemplate *structTemplate = [templateManager templateForType:DSTemplateTypeStruct];
        DSTemplate *functionTemplate = [templateManager templateForType:DSTemplateTypeFunction];
        DSTemplate *datatypeTemplate = [templateManager templateForType:DSTemplateTypeDataType];

        NSArray *groupInfos = [[DSInfoRepository sharedRepository] groupInfos];
        for (int i = 0; i < [groupInfos count]; i++) {
            DSInformation *aGroupInfo = [groupInfos objectAtIndex:i];
            NSString *groupPath = [reflibDirPath stringByAppendingPathComponent:[aGroupInfo value]];
            [self makeDirectories:groupPath];
            
            NSString *classesDirPath = [groupPath stringByAppendingPathComponent:@"Classes"];
            NSString *dataTypesDirPath = [groupPath stringByAppendingPathComponent:@"Data Types"];
            
            NSArray *classInfos = [aGroupInfo childInfosWithTag:@"@class"];
            for (int j = 0; j < [classInfos count]; j++) {
                DSInformation *aClassInfo = [classInfos objectAtIndex:j];
                NSString *classDirPath = [classesDirPath stringByAppendingPathComponent:[aClassInfo value]];
                [self makeDirectories:classDirPath];

                NSString *classIndexPath = [classDirPath stringByAppendingPathComponent:@"index.html"];
                [classTemplate outputAtPath:classIndexPath baseInfo:aClassInfo];
            }
            
            NSArray *structInfos = [aGroupInfo childInfosWithTag:@"@struct"];
            for (int j = 0; j < [structInfos count]; j++) {
                DSInformation *aStructInfo = [structInfos objectAtIndex:j];
                NSString *structDirPath = [dataTypesDirPath stringByAppendingPathComponent:[aStructInfo value]];
                [self makeDirectories:structDirPath];

                NSString *structIndexPath = [structDirPath stringByAppendingPathComponent:@"index.html"];
                [structTemplate outputAtPath:structIndexPath baseInfo:aStructInfo];
            }
            
            NSString *funcsFilePath = [groupPath stringByAppendingPathComponent:@"functions.html"];
            [functionTemplate outputAtPath:funcsFilePath baseInfo:aGroupInfo];
            
            NSString *datatypeFilePath = [dataTypesDirPath stringByAppendingPathComponent:@"index.html"];
            [self makeDirectories:dataTypesDirPath];
            [datatypeTemplate outputAtPath:datatypeFilePath baseInfo:aGroupInfo];
        }
    }
    
    [templateManager copyAdditionalFilesToPath:baseDirPath];
    
    [templateManager release];
}

@end



