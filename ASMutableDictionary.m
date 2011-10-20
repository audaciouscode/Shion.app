//
//  ASMutableDictionary.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ASMutableDictionary.h"
#import "ConsoleManager.h"
#import "AppDelegate.h"
#import "Phone.h"
#import "PreferencesManager.h"
#import "Controller.h"

@implementation ASMutableDictionary

#pragma mark -
#pragma mark NSMutableDictionary Methods

- (id) initWithCapacity:(unsigned int) numItems
{
	store = [[NSMutableDictionary alloc] initWithCapacity:numItems];
	
	return self;
}

- (void) removeObjectForKey:(id) key
{
	[store removeObjectForKey:key];
}

- (unsigned int) count
{
	return [store count];
}

- (id) objectForKey:(id) key
{
	return [store objectForKey:key];
}

- (void) setObject:(id) object forKey:(id) key
{
	[self willChangeValueForKey:key];

	[store setObject:object forKey:key];
	
	if ([key isEqual:@"favorite"])
	{
		if ([self isKindOfClass:[Controller class]])
			[[PreferencesManager sharedInstance] setValue:object forKey:@"controller_favorite"];
		else if ([self isKindOfClass:[Phone class]])
			[[PreferencesManager sharedInstance] setValue:object forKey:@"phone_favorite"];
			
		[[ConsoleManager sharedInstance] willChangeValueForKey:NAV_TREE];
		[[ConsoleManager sharedInstance] didChangeValueForKey:NAV_TREE];
		
		AppDelegate	* delegate = (AppDelegate *) [NSApp delegate];
		
		[delegate refreshFavorites];
	}
	
	dirty = YES;
	
	[self didChangeValueForKey:key];
}

- (BOOL) isDirty
{
	return dirty;
}

- (void) clearDirty
{
	dirty = NO;
}

- (NSEnumerator *) keyEnumerator
{
	return [store keyEnumerator];
}

- (void) dealloc
{
	[store release];
	
	[super dealloc];
}

@end
