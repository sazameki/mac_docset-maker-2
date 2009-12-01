//
//  DSTemplate.m
//  docsetmaker
//
//  Created by numata on 09/09/20.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "DSTemplate.h"
#import "DSInfoRepository.h"
#import "DSTemplateManager.h"


@implementation DSTemplate

- (id)initWithPath:(NSString *)path type:(int)type
{
    self = [super init];
    if (self) {
        NSError *error;
        mSource = [[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error] retain];
        if (!mSource) {
            [self release];
            return nil;
        }
        mType = type;
    }
    return self;
}

- (id)initWithSource:(NSString *)source type:(int)type
{
    self = [super init];
    if (self) {
        mSource = [source retain];
        mType = type;
    }
    return self;
}

- (void)dealloc
{
    [mSource release];
    [super dealloc];
}

- (NSData *)buildForType:(DSTemplateType)type baseInfo:(DSInformation *)baseInfo
{
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/usr/bin/erb"];
    [task setArguments:[NSArray arrayWithObjects:@"-K", @"utf8", nil]];
    
    NSString *setupScript = [[DSInfoRepository sharedRepository] setupRubyScriptForType:type baseInfo:baseInfo];
    
    NSPipe *stdinPipe = [NSPipe pipe];
    NSPipe *stdoutPipe = [NSPipe pipe];
    NSFileHandle *stdinHandle = [stdinPipe fileHandleForWriting];
    [task setStandardInput:stdinPipe];
    [task setStandardOutput:stdoutPipe];
    
    [task launch];
    
    [stdinHandle writeData:[setupScript dataUsingEncoding:NSUTF8StringEncoding]];
    [stdinHandle writeData:[mSource dataUsingEncoding:NSUTF8StringEncoding]];

    [stdinHandle closeFile];
    //[task waitUntilExit];
    
    return [[stdoutPipe fileHandleForReading] readDataToEndOfFile];
}

- (void)outputAtPath:(NSString *)path baseInfo:(DSInformation *)baseInfo
{
    NSData *data = [self buildForType:mType baseInfo:baseInfo];
    [data writeToFile:path atomically:NO];
}

@end

