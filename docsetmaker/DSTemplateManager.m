//
//  DSTemplateManager.m
//  docsetmaker
//
//  Created by numata on 09/09/20.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "DSTemplateManager.h"


@implementation DSTemplateManager

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        mTemplateDirPath = [path retain];
    }
    return self;
}

- (void)dealloc
{
    [mTemplateDirPath release];
    [super dealloc];
}

- (DSTemplate *)templateForType:(DSTemplateType)type
{
    DSTemplate *ret = nil;
    if (mTemplateDirPath) {
        NSString *templateName = nil;
        if (type == DSTemplateTypeIndex) {
            templateName = @"index";
        }
        else if (type == DSTemplateTypeList) {
            templateName = @"list";
        }
        else if (type == DSTemplateTypeTOC) {
            templateName = @"toc";
        }
        else if (type == DSTemplateTypeClass) {
            templateName = @"class";
        }
        else if (type == DSTemplateTypeStruct) {
            templateName = @"struct";
        }
        else if (type == DSTemplateTypeFunction) {
            templateName = @"function";
        }
        else if (type == DSTemplateTypeDataType) {
            templateName = @"datatype";
        }
        NSString *path = [mTemplateDirPath stringByAppendingPathComponent:[templateName stringByAppendingPathExtension:@"rhtml"]];
        ret = [[[DSTemplate alloc] initWithPath:path type:type] autorelease];
    }
    if (!ret) {
        NSMutableString *source = [NSMutableString string];
        if (type == DSTemplateTypeTOC) {
            [source appendString:@"<html><head><title>TOC</title></head><body><h1>TOC<h1><%= Time.now %></body></html>"];
        } else if (type == DSTemplateTypeClass) {
            [source appendString:@"<html><head><title>Classes</title></head><body><h1>Class<h1><%= Time.now %></body></html>"];
        } else if (type == DSTemplateTypeStruct) {
            [source appendString:@"<html><head><title>Struct</title></head><body><h1>Struct<h1><%= Time.now %></body></html>"];
        } else if (type == DSTemplateTypeFunction) {
            [source appendString:@"<html><head><title>Functions</title></head><body><h1>Function<h1><%= Time.now %></body></html>"];
        } else if (type == DSTemplateTypeDataType) {
            [source appendString:@"<html><head><title>Data Types</title></head><body><h1>Data Types<h1><%= Time.now %></body></html>"];
        } else {
            [source appendString:@"<html><head><title>Unknown Template</title></head><body><h1>Unknown Template</h1></body></html>"];
        }
        ret = [[[DSTemplate alloc] initWithSource:source type:type] autorelease];
    }
    return ret;
}

- (void)copyAdditionalFilesToPath:(NSString *)basePath
{
    if (!mTemplateDirPath) {
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager directoryContentsAtPath:mTemplateDirPath];
    for (int i = 0; i < [files count]; i++) {
        NSString *aFileName = [files objectAtIndex:i];
        if ([aFileName hasPrefix:@"."] || [[[aFileName pathExtension] lowercaseString] isEqualToString:@"rhtml"]) {
            continue;
        }
        NSString *aFilePath = [mTemplateDirPath stringByAppendingPathComponent:aFileName];
        NSString *destPath = [basePath stringByAppendingPathComponent:aFileName];
        if ([fileManager fileExistsAtPath:destPath]) {
            printf("Deleting file: %s\n", [destPath cStringUsingEncoding:NSUTF8StringEncoding]);
            [fileManager removeFileAtPath:destPath handler:nil];
        }
        printf("Copying file: %s to %s\n", [aFilePath cStringUsingEncoding:NSUTF8StringEncoding], [destPath cStringUsingEncoding:NSUTF8StringEncoding]);
        [fileManager copyPath:aFilePath toPath:destPath handler:nil];
    }
}

@end



