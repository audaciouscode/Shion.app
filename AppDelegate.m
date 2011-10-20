//
//  AppDelegate.m
//  Shion
//
//  Created by Chris Karr on 12/21/08.
//  Copyright 2008 CASIS LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "PreferencesManager.h"
#import "DeviceManager.h"
#import "SnapshotManager.h"
#import "EventManager.h"
#import "ConsoleManager.h"
#import "LogManager.h"
#import "LuaManager.h"
#import "XMPPManager.h"
#import "TriggerManager.h"
#import "SolarEventManager.h"

#import "Appliance.h"
#import "Chime.h"
#import "Camera.h"

#import "Shion.h"

@implementation AppDelegate

- (void) timedSave:(NSTimer *) theTimer
{
	[[DeviceManager sharedInstance] saveDevices];
	[[EventManager sharedInstance] saveEvents];
	[[SnapshotManager sharedInstance] saveSnapshots];
	[[TriggerManager sharedInstance] saveTriggers];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender
{
	BOOL doQuit = NO;
	
	BOOL confirmQuit = [[PreferencesManager sharedInstance] confirmQuit];
	
	if (!confirmQuit)
		doQuit = YES;
	else
	{
		[NSApp activateIgnoringOtherApps:YES];
		
		NSAlert * panel = [[[NSAlert alloc] init] autorelease];
		[panel setAlertStyle:NSWarningAlertStyle];
		[panel setMessageText:NSLocalizedString(@"Quit Shion?", nil)];
		[panel setInformativeText:NSLocalizedString(@"Are your sure you want to quit Shion? Active schedules will be interrupted.", nil)];
		[panel addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
		[panel addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
		
		if (getVersion() >= 0x1050)
		{
			[panel setShowsSuppressionButton:YES];
			NSButton * suppress = [panel suppressionButton];
			[[suppress cell] setControlSize:NSSmallControlSize];
			[suppress setTitle:NSLocalizedString(@"Do not ask for confirmation again.", nil)];
			
			[[suppress cell] setFont:[NSFont labelFontOfSize:11]];
			
			[suppress bind:@"value" toObject:[PreferencesManager sharedInstance]
			   withKeyPath:@"confirm_quit" options:[NSDictionary dictionaryWithObject:@"NSNegateBoolean" forKey:NSValueTransformerNameBindingOption]];
		}
		
		if ([panel runModal] == NSAlertSecondButtonReturn)
			doQuit = YES;
	}
	
	if (doQuit)
	{
		[self timedSave:nil];
		
		return NSTerminateNow;
	}
	else
		return NSTerminateCancel;
}

- (void) setStatusError:(BOOL) error
{
	if (error)
		[menuItem setImage:[NSImage imageNamed:@"cache-menu-error"]];
	else
		[menuItem setImage:[NSImage imageNamed:@"cache-menu-off"]];
}


- (void) awakeFromNib
{
	NSStatusBar * bar = [NSStatusBar systemStatusBar];
	
	menuItem = [[bar statusItemWithLength:NSVariableStatusItemLength] retain];
	
	[menuItem setTitle:nil];
	[menuItem setImage:[NSImage imageNamed:@"cache-menu-off"]];
	[menuItem setAlternateImage:[NSImage imageNamed:@"cache-menu-on"]];
	[menuItem setHighlightMode:YES];
	[menuItem setMenu:menu];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/Extensions/IndigoOverrides.kext"])
	{
		NSRunAlertPanel(@"Indigo Kernel Extensions Located", @"Shion cannot operate properly while the Indigo kernel extension is installed.", @"More Info...", nil, nil);
		
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"IndigoFixURL"]]];
		[[NSWorkspace sharedWorkspace] selectFile:@"/System/Library/Extensions/IndigoOverrides.kext" inFileViewerRootedAtPath:@"/"];
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/Extensions/ThinkingHomeUSB.kext"])
	{
		NSRunAlertPanel(@"Thinking Home Kernel Extensions Located", @"Shion cannot operate properly while the Thinking Home kernel extension is installed.", @"More Info...", nil, nil);
		
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"ThinkingHomeFixURL"]]];
		[[NSWorkspace sharedWorkspace] selectFile:@"/System/Library/Extensions/ThinkingHomeUSB.kext" inFileViewerRootedAtPath:@"/"];
	}

	[LogManager sharedInstance];
	[LuaManager sharedInstance];
	[XMPPManager sharedInstance];
	
	[PreferencesManager sharedInstance]; 
	[[ConsoleManager sharedInstance] consoleWindow:self];
	
	saveTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timedSave:) userInfo:nil repeats:YES] retain];
}

- (IBAction) troubleshoot:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"ShionTroubleshootingPage"]]];
}

- (IBAction) visitWebSite:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"ShionWebHome"]]];
}

- (IBAction) moreDevices:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"ShionMoreDevicesPage"]]];
}

- (IBAction) showTips:(id) sender
{
	[[ConsoleManager sharedInstance] showTips:sender];
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
	if ([key isEqual:@"devices"])
		return YES;
	else if ([key isEqual:@"snapshots"])
		return YES;
	else if ([key isEqual:@"triggers"])
		return YES;
	else if ([key isEqual:@"sunrise"])
		return YES;
	else if ([key isEqual:@"sunset"])
		return YES;
	
	return NO;
}

- (id) valueForKey:(NSString *)key
{
	if ([key isEqual:@"devices"])
		return [[DeviceManager sharedInstance] devices];
	else if ([key isEqual:@"snapshots"])
		return [[SnapshotManager sharedInstance] snapshots];
	else if ([key isEqual:@"triggers"])
		return [[TriggerManager sharedInstance] triggers];
	else if ([key isEqual:@"sunrise"] || [key isEqual:@"sunset"])
	{
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy.MM.dd"];
		
		NSString * dateString = [formatter stringFromDate:[NSDate date]];
		
		[formatter setDateFormat:@"yyyy.MM.dd HH:mm:ss"];
		NSTimeInterval time = [[formatter dateFromString:[NSString stringWithFormat:@"%@ 00:00:00", dateString]] timeIntervalSinceReferenceDate];
		[formatter release];

		if ([key isEqual:@"sunrise"])
		{
			int sunrise = [SolarEventManager sunrise];
			time += (sunrise * 60); 
		}
		else
		{
			int sunset = [SolarEventManager sunset];
			time += (sunset * 60); 
		}

		return [NSDate dateWithTimeIntervalSinceReferenceDate:time];
	}
	
	return nil;
}

- (void) refreshFavorites
{
	NSMenu * submenu = [favorites submenu];

	while ([submenu numberOfItems] > 0)
		[submenu removeItemAtIndex:0];
	
	NSMutableArray * favoriteDevices = [NSMutableArray array];
	
	NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * d = nil;
	while (d = [deviceIter nextObject])
	{
		NSNumber * isFave = [d valueForKey:@"favorite"];
		
		if (isFave != nil && [isFave boolValue])
			[favoriteDevices addObject:d];
	}

	NSMenuItem * header = [submenu addItemWithTitle:@"Devices" action:@selector(favoriteAction:) keyEquivalent:[NSString string]];
	[header setTarget:self];

	deviceIter = [favoriteDevices objectEnumerator];
	while (d = [deviceIter nextObject])
	{
		NSMenuItem * item = [[NSMenuItem alloc] init];
		
		[item setTarget:self];
		[item setAction:@selector(favoriteAction:)];
		[item setRepresentedObject:d];
		
		if ([d isKindOfClass:[Appliance class]])
			[item setTitle:[NSString stringWithFormat:@"Toggle %@", [d name]]];
		else if ([d isKindOfClass:[Chime class]])
			[item setTitle:[NSString stringWithFormat:@"Ring %@", [d name]]];
		else if ([d isKindOfClass:[Camera class]])
			[item setTitle:[NSString stringWithFormat:@"Capture Image With %@", [d name]]];
		else
			[item setTitle:[NSString stringWithFormat:@"Show %@", [d name]]];
		
		[submenu addItem:item];
		
		[item release];
	}
	
	[submenu addItem:[NSMenuItem separatorItem]];
	
	NSMutableArray * favoriteSnapshots = [NSMutableArray array];

	NSEnumerator * snapIter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
	Snapshot * s = nil;
	while (s = [snapIter nextObject])
	{
		NSNumber * isFave = [s valueForKey:@"favorite"];
		
		if (isFave != nil && [isFave boolValue])
			[favoriteSnapshots addObject:s];
	}
	
	header = [submenu addItemWithTitle:@"Snapshots" action:@selector(favoriteAction:) keyEquivalent:[NSString string]];
	[header setTarget:self];

	snapIter = [favoriteSnapshots objectEnumerator];
	while (s = [snapIter nextObject])
	{
		NSMenuItem * item = [[NSMenuItem alloc] init];
		
		[item setTarget:self];
		[item setAction:@selector(favoriteAction:)];
		[item setRepresentedObject:s];
		[item setTitle:[NSString stringWithFormat:@"Execute %@", [s name]]];
		
		[submenu addItem:item];
		
		[item release];
	}
	
	[submenu addItem:[NSMenuItem separatorItem]];

	NSMutableArray * favoriteTriggers = [NSMutableArray array];
	
	NSEnumerator * trigIter = [[[TriggerManager sharedInstance] triggers] objectEnumerator];
	Trigger * t = nil;
	while (t = [trigIter nextObject])
	{
		NSNumber * isFave = [t valueForKey:@"favorite"];
		
		if (isFave != nil && [isFave boolValue])
			[favoriteTriggers addObject:t];
	}
	
	header = [submenu addItemWithTitle:@"Triggers" action:@selector(favoriteAction:) keyEquivalent:[NSString string]];
	[header setTarget:self];
	
	trigIter = [favoriteTriggers objectEnumerator];
	while (t = [trigIter nextObject])
	{
		NSMenuItem * item = [[NSMenuItem alloc] init];
		
		[item setTarget:self];
		[item setAction:@selector(favoriteAction:)];
		[item setRepresentedObject:t];
		[item setTitle:[NSString stringWithFormat:@"Activate %@", [t name]]];
		
		[submenu addItem:item];
		
		[item release];
	}
}
						
- (void) favoriteAction:(id) sender
{
	if ([sender isKindOfClass:[NSMenuItem class]])
	{
		NSMenuItem * item = (NSMenuItem *) sender;
		
		id object = [item representedObject];
		
		if (object == nil)
			return;
		
		if ([object isKindOfClass:[Device class]])
		{
			Device * d = (Device *) object;

			if ([object isKindOfClass:[Appliance class]])
			{
				Appliance * a = (Appliance *) d;
				
				[a setActive:([a active] == NO)];
			}
			else if ([object isKindOfClass:[Chime class]])
			{
				Chime * a = (Chime *) d;
				
				[a chime];
			}
			else if ([object isKindOfClass:[Camera class]])
			{
				Camera * a = (Camera *) d;
				
				[a captureImage];
			}
			else
			{
				ConsoleManager * manager = [ConsoleManager sharedInstance];
				
				[manager selectItemWithIdentifier:[d identifier]];
				
				[manager consoleWindow:sender];
			}
		}
		else if ([object isKindOfClass:[Snapshot class]])
		{
			Snapshot * s = (Snapshot *) object;
			
			[s execute];
		}
		else if ([object isKindOfClass:[Trigger class]])
		{
			Trigger * s = (Trigger *) object;
			
			[s fire];
		}
	}
}

@end
