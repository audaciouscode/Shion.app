//
//  MainMenuDelegate.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "MainMenuDelegate.h"

#import "IssueManager.h"
#import "PreferencesManager.h"
#import "ConsoleManager.h"
#import "EventManager.h"
#import "LuaManager.h"

@implementation MainMenuDelegate

- (IBAction) lua:(id) sender
{
	[[LuaManager sharedInstance] luaWindow:sender];
}

- (IBAction) reportIssue:(id) sender
{
	[[IssueManager sharedInstance] issueWindow:sender];
}

- (IBAction) preferences:(id) sender
{
	[[PreferencesManager sharedInstance] preferencesWindow:sender];
}

- (IBAction) console:(id) sender
{
	[[ConsoleManager sharedInstance] consoleWindow:sender];
}

@end
