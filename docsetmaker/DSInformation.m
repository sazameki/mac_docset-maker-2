//
//  DSInformation.m
//  DocSet Maker
//
//  Created by numata on 09/09/13.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "DSInformation.h"
#import "NSString+Tokenizer.h"


int DSCompareInfo(id anInfo1, id anInfo2, void *context)
{
    NSString *value1 = [((DSInformation *)anInfo1) value];
    NSString *value2 = [((DSInformation *)anInfo2) value];
	
    return [value1 compare:value2 options:NSCaseInsensitiveSearch];
}    


@implementation DSInformation

- (id)initWithTag:(NSString *)tag
{
    self = [super init];
    if (self) {
        mTagName = [tag retain];
        [self setValue:@""];
        
        mChildInfos = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc
{
    [mTagName release];
    [mValue release];
    [mChildInfos release];
    [super dealloc];
}


#pragma mark -

- (NSString *)tagName
{
    return mTagName;
}

- (NSString *)value
{
    return mValue;
}

- (void)setValue:(NSString *)value
{
    [mValue release];
    mValue = [value retain];
}

- (DSInformation *)parentInfo
{
    return mParentInfo;
}

- (void)setParentInfo:(DSInformation *)anInfo
{
    mParentInfo = anInfo;
}


#pragma mark -

- (BOOL)appendValue:(NSString *)value
{
    NSArray *appendableTagNames = [NSArray arrayWithObjects:/*@"@param",*/ @"@discussion", @"@return", nil];
    
    if (![appendableTagNames containsObject:mTagName]) {
        return NO;
    }
    
    //value = [@" " stringByAppendingString:value];
    [self setValue:[[self value] stringByAppendingString:value]];
    return YES;
}

- (void)addChildInformation:(DSInformation *)anInfo
{
    [anInfo setParentInfo:self];
    [mChildInfos addObject:anInfo];
}

- (NSArray *)childInfosWithTag:(NSString *)tag
{
    NSMutableArray *ret = [NSMutableArray array];
    for (int i = 0; i < [mChildInfos count]; i++) {
        DSInformation *aChildInfo = [mChildInfos objectAtIndex:i];
        if ([[aChildInfo tagName] isEqualToString:tag]) {
            [ret addObject:aChildInfo];
        }
    }
    return ret;
}

- (NSArray *)childInfosWithTags:(NSArray *)tags
{
    NSMutableArray *ret = [NSMutableArray array];
    for (int i = 0; i < [tags count]; i++) {
        NSString *aTag = [tags objectAtIndex:i];
        [ret addObjectsFromArray:[self childInfosWithTag:aTag]];
    }
    return ret;
}

- (NSArray *)allChildInfos
{
    return mChildInfos;
}

- (BOOL)hasChildWithTag:(NSString *)tag
{
    for (int i = 0; i < [mChildInfos count]; i++) {
        DSInformation *aChildInfo = [mChildInfos objectAtIndex:i];
        if ([[aChildInfo tagName] isEqualToString:tag]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)declaration
{
    NSString *decl = nil;
    NSArray *decls = [self childInfosWithTag:@"@declare"];
    if ([decls count] > 0) {
        DSInformation *declInfo = [decls objectAtIndex:0];
        decl = [declInfo value];
    }
    if ([decl length] == 0) {
        decl = nil;
    }
    decl = [decl stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    decl = [decl stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    return decl;
}

- (NSString *)abstractStr
{
    NSString *ret = nil;
    NSArray *abstracts = [self childInfosWithTag:@"@abstract"];
    if ([abstracts count] > 0) {
        DSInformation *abstractInfo = [abstracts objectAtIndex:0];
        ret = [abstractInfo value];
    }
    NSString *abst = [ret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([abst length] == 0) {
        abst = nil;
    }
    if (!abst) {
        NSMutableString *ret = [NSMutableString string];
        NSArray *discussions = [self childInfosWithTag:@"@discussion"];
        for (int i = 0; i < [discussions count]; i++) {
            DSInformation *aDiscussInfo = [discussions objectAtIndex:i];
            [ret appendString:[aDiscussInfo value]];
        }
        abst = [ret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([abst length] == 0) {
            abst = nil;
        }
    }
    return abst;
}

- (NSString *)discussion
{
    if ([[self childInfosWithTag:@"@abstract"] count] == 0) {
        return nil;
    }
    NSMutableString *ret = [NSMutableString string];
    NSArray *discussions = [self childInfosWithTag:@"@discussion"];
    for (int i = 0; i < [discussions count]; i++) {
        DSInformation *aDiscussInfo = [discussions objectAtIndex:i];
        [ret appendString:[aDiscussInfo value]];
    }
    NSString *discussion = [ret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([discussion length] == 0) {
        discussion = nil;
    }
    return discussion;
}

- (NSString *)docIdentifier
{
    if (![[self tagName] isEqualToString:@"@method"] && ![[self tagName] isEqualToString:@"@function"]) {
        return [self value];
    }
    NSString *decl = [self declaration];
    if (!decl) {
        return [self value];
    }
    NSMutableString *ret = [NSMutableString string];
    [ret appendFormat:@"%@/", [self value]];
    unsigned pos = 0;
    unsigned length = [decl length];
    BOOL wasSpace = NO;
    while (pos < length) {
        unichar c = [decl characterAtIndex:pos++];
        if (isspace((int)c)) {
            if (!wasSpace) {
                [ret appendString:@"_"];
                wasSpace = YES;
            }
        } else if (c == '#') {
            [ret appendString:@"_pp_"];
            wasSpace = NO;
        } else if (c == '&') {
            [ret appendString:@"@"];
            wasSpace = NO;
        } else if (c == '<' || c == '>') {
            [ret appendString:@"@"];
            wasSpace = NO;
        } else {
            [ret appendFormat:@"%C", c];
            wasSpace = NO;
        }
    }
    return ret;
}

- (NSString *)languageType
{
    // TODO: Distinguish corrent language type
    return @"cpp";
}

- (BOOL)isGroup
{
    return [[self tagName] isEqualToString:@"@group"];
}

- (BOOL)isInstantVariable
{
    if (![[self tagName] isEqualToString:@"@var"]) {
        return NO;
    }
    if ([[self languageType] isEqualToString:@"cpp"]) {
        NSString *decl = [self declaration];
        return ![decl hasPrefix:@"static"];
    }
    return NO;
}

- (BOOL)isInstantMethod
{
    if (![[self tagName] isEqualToString:@"@method"]) {
        return NO;
    }
    if ([[self languageType] isEqualToString:@"cpp"]) {
        NSString *decl = [self declaration];
        return ![decl hasPrefix:@"static"];
    }
    return NO;
}

- (BOOL)isClassMethod
{
    if (![[self tagName] isEqualToString:@"@method"]) {
        return NO;
    }
    if ([[self languageType] isEqualToString:@"cpp"]) {
        NSString *decl = [self declaration];
        return [decl hasPrefix:@"static"];
    }
    return NO;
}

- (NSString *)newScriptName
{
    static int count = 0;
    return [NSString stringWithFormat:@"var_%d", count++];
}

- (NSString *)rubyScriptForGroup
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"%@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"$groups.push(%@)\n\n", scriptName];
    
    NSArray *childInfos = [self allChildInfos];
    for (int i = 0; i < [childInfos count]; i++) {
        DSInformation *aChildInfo = [childInfos objectAtIndex:i];
        if ([[aChildInfo tagName] isEqualToString:@"@abstract"]) {
            continue;
        }
        if ([[aChildInfo tagName] isEqualToString:@"@discussion"]) {
            continue;
        }
        NSString *childScriptName = nil;
        NSString *childScript = [aChildInfo rubyScriptForParent:self parentScriptName:scriptName scriptName:&childScriptName];
        if (childScript) {
            [script appendString:childScript];
        }
    }
    
    return script;
}

- (NSString *)rubyScriptForFunction:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];
    [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/func/%@\"\n", scriptName, [self languageType], [self docIdentifier]];

    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([parentInfo isGroup]) {
        [script appendFormat:@"  %@.d_href = \"%@/functions.html#//apple_ref/%@/func/%@\"\n", scriptName, [parentInfo value], [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_group = %@\n", scriptName, parentScriptName];
        [script appendFormat:@"  %@.add_function(%@)\n", parentScriptName, scriptName];
    } else {
        [NSException raise:@"Error" format:@"Parent of functions should be groups."];
    }
    
    return script;
}

- (NSString *)rubyScriptForClass:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];
    [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/cl/%@\"\n", scriptName, [self languageType], [self docIdentifier]];

    NSString *langType = [self languageType];
    if ([langType isEqualToString:@"cpp"]) {
        NSString *decl = [self declaration];
        NSEnumerator *declEnum = [decl tokenize:@":"];
        [declEnum nextObject];
        NSString *parentStr = [declEnum nextObject];
        if (parentStr) {
            NSEnumerator *parentEnum = [parentStr tokenize:@" "];
            NSString *token1 = [parentEnum nextObject];
            NSString *token2 = [parentEnum nextObject];
            if (token2) {
                [script appendFormat:@"  %@.d_parent_class_name = \"%@\"\n", scriptName, token2];
            } else {
                [script appendFormat:@"  %@.d_parent_class_name = \"%@\"\n", scriptName, token1];
            }
        }
    }
    
    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([parentInfo isGroup]) {
        [script appendFormat:@"  %@.d_href = \"%@/Classes/%@/index.html#//apple_ref/%@/cl/%@\"\n", scriptName, [parentInfo value], [self value], [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_group = %@\n", scriptName, parentScriptName];
        [script appendFormat:@"  %@.add_class(%@)\n", parentScriptName, scriptName];
        [script appendFormat:@"  $classes.push(%@)\n\n", scriptName];
        [script appendFormat:@"  $classes_and_structs.push(%@)\n\n", scriptName];
    } else {
        [NSException raise:@"Error" format:@"Parent of classes should be groups."];
    }
    
    NSString *taskScriptName = nil;

    NSArray *childInfos = [self allChildInfos];
    for (int i = 0; i < [childInfos count]; i++) {
        DSInformation *aChildInfo = [childInfos objectAtIndex:i];
        NSString *childScriptName = nil;
        NSString *childScript = [aChildInfo rubyScriptForParent:self parentScriptName:scriptName scriptName:&childScriptName];
        if (childScript) {
            [script appendString:childScript];
        }
        if ([[aChildInfo tagName] isEqualToString:@"@task"]) {
            taskScriptName = childScriptName;
        } else if (taskScriptName && childScriptName) {
            if ([aChildInfo isInstantMethod]) {
                [script appendFormat:@"  %@.add_instant_method(%@)\n", taskScriptName, childScriptName];
            } else if ([aChildInfo isClassMethod]) {
                [script appendFormat:@"  %@.add_class_method(%@)\n", taskScriptName, childScriptName];
            } else if ([aChildInfo isInstantVariable]) {
                [script appendFormat:@"  %@.add_inst_var(%@)\n", taskScriptName, childScriptName];
            }
        }
    }
    
    return script;
}

- (NSString *)rubyScriptForStruct:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];
    [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/tag/%@\"\n", scriptName, [self languageType], [self docIdentifier]];
    
    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([parentInfo isGroup]) {
        [script appendFormat:@"  %@.d_href = \"%@/Data Types/%@/index.html#//apple_ref/%@/tag/%@\"\n", scriptName, [parentInfo value], [self value], [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_group = %@\n", scriptName, parentScriptName];
        [script appendFormat:@"  %@.add_struct(%@)\n", parentScriptName, scriptName];
        [script appendFormat:@"  $structs.push(%@)\n\n", scriptName];
        [script appendFormat:@"  $classes_and_structs.push(%@)\n\n", scriptName];
    } else {
        [NSException raise:@"Error" format:@"Parent of structs should be groups."];
    }
    
    NSString *taskScriptName = nil;

    NSArray *childInfos = [self allChildInfos];
    for (int i = 0; i < [childInfos count]; i++) {
        DSInformation *aChildInfo = [childInfos objectAtIndex:i];
        NSString *childScriptName = nil;
        NSString *childScript = [aChildInfo rubyScriptForParent:self parentScriptName:scriptName scriptName:&childScriptName];
        if (childScript) {
            [script appendString:childScript];
        }
        if ([[aChildInfo tagName] isEqualToString:@"@task"]) {
            taskScriptName = childScriptName;
        } else if (taskScriptName && childScriptName) {
            if ([aChildInfo isInstantMethod]) {
                [script appendFormat:@"  %@.add_instant_method(%@)\n", taskScriptName, childScriptName];
            } else if ([aChildInfo isClassMethod]) {
                [script appendFormat:@"  %@.add_class_method(%@)\n", taskScriptName, childScriptName];
            }
        }
    }
    
    return script;
}

- (NSString *)rubyScriptForMethod:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];

    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([self isInstantMethod]) {
        [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/instm/%@/%@\"\n", scriptName, [self languageType], [parentInfo value], [self docIdentifier]];
        [script appendFormat:@"  %@.d_href = \"%@/Classes/%@/index.html#//apple_ref/%@/instm/%@/%@\"\n", scriptName, [[parentInfo parentInfo] value], [parentInfo value], [self languageType], [parentInfo value], [self docIdentifier]];
        [script appendFormat:@"  %@.add_instant_method(%@)\n",  parentScriptName, scriptName];
    } else {
        [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/clm/%@/%@\"\n", scriptName, [self languageType], [parentInfo value], [self docIdentifier]];
        [script appendFormat:@"  %@.d_href = \"%@/Classes/%@/index.html#//apple_ref/%@/clm/%@/%@\"\n", scriptName, [[parentInfo parentInfo] value], [parentInfo value], [self languageType], [parentInfo value], [self docIdentifier]];
        [script appendFormat:@"  %@.add_class_method(%@)\n",  parentScriptName, scriptName];
    }
    
    return script;
}

- (NSString *)rubyScriptForVariable:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];

    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];
    
    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([parentInfo isGroup]) {
        [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/data/%@\"\n", scriptName, [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_href = \"%@/Data Types/index.html#//apple_ref/%@/data/%@\"\n", scriptName, [parentInfo value], [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_group = %@\n", scriptName, parentScriptName];
        [script appendFormat:@"  %@.add_variable(%@)\n",  parentScriptName, scriptName];
    } else {
        [script appendFormat:@"  %@.add_inst_var(%@)\n", parentScriptName, scriptName];
    }
    return script;
}

- (NSString *)rubyScriptForEnum:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];

    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([parentInfo isGroup]) {
        [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/tag/%@\"\n", scriptName, [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_href = \"%@/Data Types/index.html#//apple_ref/%@/tag/%@\"\n", scriptName, [parentInfo value], [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_group = %@\n", scriptName, parentScriptName];
    } else {
    }

    [script appendFormat:@"  %@.add_enum(%@)\n",  parentScriptName, scriptName];
    
    NSArray *childInfos = [self allChildInfos];
    for (int i = 0; i < [childInfos count]; i++) {
        DSInformation *aChildInfo = [childInfos objectAtIndex:i];
        NSString *childScriptName = nil;
        NSString *childScript = [aChildInfo rubyScriptForParent:self parentScriptName:scriptName scriptName:&childScriptName];
        if (childScript) {
            [script appendString:childScript];
        }
    }
    
    return script;    
}

- (NSString *)rubyScriptForConstant:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];
    
    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([parentInfo isGroup]) {
        [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/data/%@\"\n", scriptName, [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_href = \"%@/Data Types/index.html#//apple_ref/%@/data/%@\"\n", scriptName, [parentInfo value], [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
        [script appendFormat:@"  %@.d_group = %@\n", scriptName, parentScriptName];
    } else if (![[parentInfo tagName] isEqualToString:@"@enum"]) {
        [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    } else {
        NSEnumerator *valueEnum = [[self value] tokenize:@" \t"];
        NSString *constName = [valueEnum nextObject];
        NSMutableString *exp = [NSMutableString string];
        NSString *anExp = nil;
        while (anExp = [valueEnum nextObject]) {
            if ([exp length] > 0) {
                [exp appendString:@" "];
            }
            [exp appendString:anExp];
        }
        if (constName) {
            [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, constName];
            [script appendFormat:@"  %@.d_abstract = \"%@\"\n", scriptName, exp];
        }
    }
    
    [script appendFormat:@"  %@.add_constant(%@)\n",  parentScriptName, scriptName];
    
    return script;    
}

- (NSString *)rubyScriptForTask:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.add_task(%@)\n", parentScriptName, scriptName];
    
    return script;
}

- (NSString *)rubyScriptForTypedef:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.add_typedef(%@)\n", parentScriptName, scriptName];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];

    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([parentInfo isGroup]) {
        [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/tdef/%@\"\n", scriptName, [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_href = \"%@/Data Types/index.html#//apple_ref/%@/tdef/%@\"\n", scriptName, [parentInfo value], [self languageType], [self docIdentifier]];
    }
    
    return script;
}

- (NSString *)rubyScriptForDefine:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    NSMutableString *script = [NSMutableString string];
    
    NSString *scriptName = [self newScriptName];
    if (childScriptName != NULL) {
        *childScriptName = scriptName;
    }
    
    [script appendFormat:@"%@ = BaseInfo.new\n", scriptName];
    [script appendFormat:@"  %@.d_name = \"%@\"\n", scriptName, [self value]];
    [script appendFormat:@"  %@.add_macro(%@)\n", parentScriptName, scriptName];
    [script appendFormat:@"  %@.d_declare = \"%@\"\n", scriptName, [self declaration]];

    NSString *abst = [self abstractStr];
    if (abst) {
        [script appendFormat:@"%@.d_abstract = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:abst];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    NSString *discussion = [self discussion];
    if (discussion) {
        [script appendFormat:@"%@.d_discussion = <<__EOS_9028C205D22545C394761AB14E8F800B__\n", scriptName];
        [script appendString:discussion];
        [script appendString:@"\n__EOS_9028C205D22545C394761AB14E8F800B__\n"];
    }
    
    if ([parentInfo isGroup]) {
        [script appendFormat:@"  %@.d_tag = \"//apple_ref/%@/macro/%@\"\n", scriptName, [self languageType], [self docIdentifier]];
        [script appendFormat:@"  %@.d_href = \"%@/Data Types/index.html#//apple_ref/%@/macro/%@\"\n", scriptName, [parentInfo value], [self languageType], [self docIdentifier]];
    }
    
    return script;
}

- (NSString *)rubyScriptForParent:(DSInformation *)parentInfo parentScriptName:(NSString *)parentScriptName scriptName:(NSString **)childScriptName
{
    if ([mTagName isEqualToString:@"@group"]) {
        if (parentInfo) {
            return nil;
        }
        return [self rubyScriptForGroup];
    } else if ([mTagName isEqualToString:@"@function"]) {
        return [self rubyScriptForFunction:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@class"]) {
        return [self rubyScriptForClass:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@struct"]) {
        return [self rubyScriptForStruct:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@method"]) {
        return [self rubyScriptForMethod:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@var"]) {
        return [self rubyScriptForVariable:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@enum"]) {
        return [self rubyScriptForEnum:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@const"] || [mTagName isEqualToString:@"@constant"]) {
        return [self rubyScriptForConstant:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@task"]) {
        return [self rubyScriptForTask:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@typedef"]) {
        return [self rubyScriptForTypedef:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else if ([mTagName isEqualToString:@"@define"]) {
        return [self rubyScriptForDefine:parentInfo parentScriptName:parentScriptName scriptName:childScriptName];
    } else {
        //printf("Ignored tag: %s\n", [mTagName cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"info{ tag=%@, value=\"%@\", children=%@ }", mTagName, mValue, mChildInfos];
}

@end



