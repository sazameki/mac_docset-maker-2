//
//  DSInfoRepository.m
//  DocSet Maker
//
//  Created by numata on 09/09/13.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "DSInfoRepository.h"
#import "DSInformation.h"


static DSInfoRepository *_instance = nil;


@implementation DSInfoRepository

+ (DSInfoRepository *)sharedRepository
{
    if (!_instance) {
        _instance = [DSInfoRepository new];
    }
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        mGroupInfos = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc
{
    [mGroupInfos release];
    [mBaseRubyScript release];
    [super dealloc];
}

- (void)clearAllInfos
{
    [mGroupInfos removeAllObjects];
    [mBaseRubyScript release];
    mBaseRubyScript = nil;
}

- (NSArray *)groupNames
{
    NSMutableArray *ret = [NSMutableArray array];
    for (int i = 0; i < [mGroupInfos count]; i++) {
        DSInformation *aGroupInfo = [mGroupInfos objectAtIndex:i];
        if ([[aGroupInfo childInfosWithTags:[NSArray arrayWithObjects:@"@class", @"@struct", @"@function", @"@enum", @"@var", @"const", @"constant", @"macro", nil]] count] == 0) {
            continue;
        }
        [ret addObject:[aGroupInfo value]];
    }
    return ret;
}

- (NSArray *)sortedGroupNames
{
    // Sort specific for Karakuri Framework just now (2009/09/15)
    // TODO: Prepare any kind of setting method for users
    NSArray *priorGroupNames = [NSArray arrayWithObjects:@"Game Foundation", @"Game 2D Graphics", @"Game Audio", @"Game Text Processing", @"Game Controls", @"Game 2D Simulator", @"Game Network", nil];
    
    NSMutableArray *ret = [NSMutableArray array];
    NSMutableArray *groupNames = [NSMutableArray arrayWithArray:[self groupNames]];
    
    for (int i = 0; i < [priorGroupNames count]; i++) {
        NSString *aPriorGroupName = [priorGroupNames objectAtIndex:i];
        if ([groupNames containsObject:aPriorGroupName]) {
            [ret addObject:aPriorGroupName];
        }
    }
    
    [groupNames removeObjectsInArray:ret];
    [ret addObjectsFromArray:groupNames];
    
    return ret;
}

- (DSInformation *)groupInfoForName:(NSString *)groupName
{
    DSInformation *ret = nil;
    for (int i = 0; i < [mGroupInfos count]; i++) {
        DSInformation *aGroupInfo = [mGroupInfos objectAtIndex:i];
        if ([[aGroupInfo value] isEqualToString:groupName]) {
            ret = aGroupInfo;
            break;
        }
    }
    if (!ret) {
        ret = [[DSInformation alloc] initWithTag:@"@group"];
        [ret setValue:groupName];
        [mGroupInfos addObject:ret];
    }
    return ret;
}

- (void)addInfos:(NSArray *)infos
{
    for (int i = 0; i < [infos count]; i++) {
        DSInformation *anInfo = [infos objectAtIndex:i];
        NSArray *groups = [anInfo childInfosWithTag:@"@group"];
        DSInformation *theGroupInfo = nil;
        if ([groups count] > 0) {
            DSInformation *groupInfo = [groups objectAtIndex:0];
            theGroupInfo = [self groupInfoForName:[groupInfo value]];
        } else {
            theGroupInfo = [self groupInfoForName:@"Global Reference"];
        }
        [theGroupInfo addChildInformation:anInfo];
    }
}

- (NSArray *)groupInfos
{
    NSMutableArray *ret = [NSMutableArray array];
    for (int i = 0; i < [mGroupInfos count]; i++) {
        DSInformation *aGroupInfo = [mGroupInfos objectAtIndex:i];
        if ([[aGroupInfo childInfosWithTags:[NSArray arrayWithObjects:@"@class", @"@struct", @"@function", @"@enum", @"@var", @"const", @"constant", @"macro", nil]] count] == 0) {
            continue;
        }
        [ret addObject:aGroupInfo];
    }
    return ret;
}

- (NSArray *)allInfosWithTag:(NSString *)tagName
{
    NSMutableArray *ret = [NSMutableArray array];
    for (int i = 0; i < [mGroupInfos count]; i++) {
        DSInformation *aGroupInfo = [mGroupInfos objectAtIndex:i];
        NSArray *classInfos = [aGroupInfo childInfosWithTag:tagName];
        [ret addObjectsFromArray:classInfos];
    }
    return ret;
}

- (NSArray *)allInfosWithTags:(NSArray *)tagNames
{
    NSMutableArray *ret = [NSMutableArray array];
    for (int i = 0; i < [tagNames count]; i++) {
        NSString *aTagName = [tagNames objectAtIndex:i];
        [ret addObjectsFromArray:[self allInfosWithTag:aTagName]];
    }
    return ret;
}

- (void)outputVerboseInformation
{
    printf("=====================\n");
    printf("Result:\n");
    printf("  %d groups\n", [mGroupInfos count]);
    printf("  %d classes\n", [[self allInfosWithTag:@"@class"] count]);
    printf("  %d global functions\n", [[self allInfosWithTag:@"@function"] count]);
    printf("  %d global variables\n", [[self allInfosWithTag:@"@var"] count]);
    printf("  %d global constants\n", [[self allInfosWithTags:[NSArray arrayWithObjects:@"@const", @"@constant", nil]] count]);
    printf("  %d macros\n", [[self allInfosWithTag:@"@define"] count]);
    printf("=====================\n");
}

- (NSString *)classDefScript
{
    NSMutableString *script = [NSMutableString string];
    
    [script appendString:@"class BaseInfo\n"];
    [script appendString:@"  def initialize()\n"];
    [script appendString:@"    @inst_method_infos = Array.new\n"];
    [script appendString:@"    @class_method_infos = Array.new\n"];
    [script appendString:@"    @class_infos = Array.new\n"];
    [script appendString:@"    @function_infos = Array.new\n"];
    [script appendString:@"    @var_infos = Array.new\n"];
    [script appendString:@"    @macro_infos = Array.new\n"];
    [script appendString:@"    @struct_infos = Array.new\n"];
    [script appendString:@"    @enum_infos = Array.new\n"];
    [script appendString:@"    @constant_infos = Array.new\n"];
    [script appendString:@"    @typedef_infos = Array.new\n"];
    [script appendString:@"    @task_infos = Array.new\n"];
    [script appendString:@"    @inst_var_infos = Array.new\n"];
    [script appendString:@"    @child_class_infos = Array.new\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def do_sort\n"];
    [script appendString:@"    @class_infos = @class_infos.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
    [script appendString:@"    @struct_infos = @struct_infos.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
    [script appendString:@"    @function_infos = @function_infos.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
    [script appendString:@"    @macro_infos = @macro_infos.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
    [script appendString:@"    @enum_infos = @enum_infos.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
    [script appendString:@"    @typedef_infos = @typedef_infos.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
    [script appendString:@"    @var_infos = @var_infos.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def find_parent_class\n"];
    [script appendString:@"    if @d_parent_class_name == nil\n"];
    [script appendString:@"      @d_parent_class = nil\n"];
    [script appendString:@"      return\n"];
    [script appendString:@"    end\n"];
    [script appendString:@"    @d_parent_class = find_class_info(@d_parent_class_name)\n"];
    [script appendString:@"    if @d_parent_class != nil\n"];
    [script appendString:@"      @d_parent_class.add_child_class(self)\n"];
    [script appendString:@"    end\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_instant_method(method_info)\n"];
    [script appendString:@"    @inst_method_infos.push(method_info)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_instant_methods()\n"];
    [script appendString:@"    return @inst_method_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_class_method(method_info)\n"];
    [script appendString:@"    @class_method_infos.push(method_info)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_child_class(a_class)\n"];
    [script appendString:@"    @child_class_infos.push(a_class)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_sub_classes()\n"];
    [script appendString:@"    return @child_class_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_class_methods()\n"];
    [script appendString:@"    return @class_method_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_methods()\n"];
    [script appendString:@"    ret = Array.new\n"];
    [script appendString:@"    @class_method_infos.each do |a_method|\n ret.push(a_method)\nend\n"];
    [script appendString:@"    @inst_method_infos.each do |a_method|\n ret.push(a_method)\nend\n"];
    [script appendString:@"    return ret\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_parent_class\n"];
    [script appendString:@"    return @d_parent_class\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_task(a_task)\n"];
    [script appendString:@"    @task_infos.push(a_task)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_tasks()\n"];
    [script appendString:@"    return @task_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_declare_p=(str)\n"];
    [script appendString:@"    @d_declare_p = str\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_declare_p\n"];
    [script appendString:@"    decl = self.d_declare\n"];
    [script appendString:@"    name_pos = decl.index(self.d_name)\n"];
    [script appendString:@"    if name_pos != nil\n"];
    [script appendString:@"      decl = decl.slice(name_pos, decl.length-name_pos)\n"];
    [script appendString:@"    end\n"];
    [script appendString:@"    return decl\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_parent_class_name=(str)\n"];
    [script appendString:@"    @d_parent_class_name = str\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_parent_class_name\n"];
    [script appendString:@"    return @d_parent_class_name\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_abstract=(str)\n"];
    [script appendString:@"    @d_abstract = str\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_abstract\n"];
    [script appendString:@"    return @d_abstract\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_discussion=(str)\n"];
    [script appendString:@"    @d_discussion = str\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_discussion\n"];
    [script appendString:@"    return @d_discussion\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_name=(str)\n"];
    [script appendString:@"    @d_name = str\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_name\n"];
    [script appendString:@"    return @d_name\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_tag=(str)\n"];
    [script appendString:@"    @d_tag = str\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_tag\n"];
    [script appendString:@"    return @d_tag\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_declare=(str)\n"];
    [script appendString:@"    @d_declare = str\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_declare\n"];
    [script appendString:@"    return @d_declare\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_group=(a_group)\n"];
    [script appendString:@"    @d_group = a_group\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_group\n"];
    [script appendString:@"    return @d_group\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_href=(str)\n"];
    [script appendString:@"    @d_href = str\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_href\n"];
    [script appendString:@"    return @d_href\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_class(a_class)\n"];
    [script appendString:@"    @class_infos.push(a_class)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_struct(a_struct)\n"];
    [script appendString:@"    @struct_infos.push(a_struct)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_enum(an_enum)\n"];
    [script appendString:@"    @enum_infos.push(an_enum)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_constant(an_enum)\n"];
    [script appendString:@"    @constant_infos.push(an_enum)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_macro(a_macro)\n"];
    [script appendString:@"    @macro_infos.push(a_macro)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_inst_var(a_var)\n"];
    [script appendString:@"    @inst_var_infos.push(a_var)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_variable(a_var)\n"];
    [script appendString:@"    @var_infos.push(a_var)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_function(a_func)\n"];
    [script appendString:@"    @function_infos.push(a_func)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def add_typedef(a_typedef)\n"];
    [script appendString:@"    @typedef_infos.push(a_typedef)\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_classes\n"];
    [script appendString:@"    return @class_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_structs\n"];
    [script appendString:@"    return @struct_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_enums\n"];
    [script appendString:@"    return @enum_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_functions\n"];
    [script appendString:@"    return @function_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_instant_variables\n"];
    [script appendString:@"    return @inst_var_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_variables\n"];
    [script appendString:@"    return @var_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_constants\n"];
    [script appendString:@"    return @constant_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_macros\n"];
    [script appendString:@"    return @macro_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  def d_typedefs\n"];
    [script appendString:@"    return @typedef_infos\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"end\n"];

    [script appendString:@"def find_group_info(group_name)\n"];
    [script appendString:@"  $groups.each do |a_group|\n"];
    [script appendString:@"    if a_group.d_name == group_name\n"];
    [script appendString:@"      return a_group\n"];
    [script appendString:@"    end\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  return nil\n"];
    [script appendString:@"end\n"];
    
    [script appendString:@"def find_class_info(class_name)\n"];
    [script appendString:@"  $classes.each do |a_class|\n"];
    [script appendString:@"    if a_class.d_name == class_name\n"];
    [script appendString:@"      return a_class\n"];
    [script appendString:@"    end\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  return nil\n"];
    [script appendString:@"end\n"];

    [script appendString:@"def find_struct_info(struct_name)\n"];
    [script appendString:@"  $structs.each do |a_struct|\n"];
    [script appendString:@"    if a_struct.d_name == struct_name\n"];
    [script appendString:@"      return a_struct\n"];
    [script appendString:@"    end\n"];
    [script appendString:@"  end\n"];
    [script appendString:@"  return nil\n"];
    [script appendString:@"end\n"];
    
    return script;
}

- (NSString *)setupRubyScriptForType:(DSTemplateType)type baseInfo:(DSInformation *)baseInfo
{
    NSMutableString *script = [NSMutableString string];

    if (!mBaseRubyScript) {
        [script appendString:@"<%\n"];
        
        [script appendString:[self classDefScript]];

        [script appendString:@"$groups = Array.new\n"];
        [script appendString:@"$classes = Array.new\n"];
        [script appendString:@"$structs = Array.new\n"];
        [script appendString:@"$classes_and_structs = Array.new\n\n"];
        
        NSArray *groupInfos = [self groupInfos];
        
        for (int i = 0; i < [groupInfos count]; i++) {
            DSInformation *aGroupInfo = [groupInfos objectAtIndex:i];
            NSString *childScriptName = nil;
            [script appendString:[aGroupInfo rubyScriptForParent:nil parentScriptName:nil scriptName:&childScriptName]];
        }

        [script appendString:@"$groups.each do |a_group|\n"];
        [script appendString:@"  a_group.do_sort\n"];
        [script appendString:@"end\n"];

        [script appendString:@"$classes.each do |a_class|\n"];
        [script appendString:@"  a_class.find_parent_class\n"];
        [script appendString:@"end\n"];
        
        [script appendString:@"$classes = $classes.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
        [script appendString:@"$classes_and_structs = $classes_and_structs.sort {|a, b| (a.d_name.downcase <=> b.d_name.downcase) }\n"];
        
        [script appendString:@"\n%>\n"];
        
        mBaseRubyScript = [script copy];
    } else {
        [script appendString:mBaseRubyScript];
    }

    [script appendString:@"<%\n"];

    if ([baseInfo isGroup]) {
        [script appendFormat:@"$the_group = find_group_info(\"%@\")\n", [baseInfo value]];
    } else if ([[baseInfo tagName] isEqualToString:@"@class"]) {
        [script appendFormat:@"$the_class = find_class_info(\"%@\")\n", [baseInfo value]];
    } else if ([[baseInfo tagName] isEqualToString:@"@struct"]) {
        [script appendFormat:@"$the_struct = find_struct_info(\"%@\")\n", [baseInfo value]];
    }

    [script appendString:@"\n%>\n"];

    return script;
}

@end


