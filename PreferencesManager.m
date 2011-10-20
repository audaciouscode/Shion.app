//
//  PreferencesManager.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "PreferencesManager.h"

#import "ConsoleManager.h"
#import "LogManager.h"

#import "AMSerialPortList.h"
#import "AMSerialPort.h"
#include "LoginItemsAE.h"

#pragma mark -
#pragma mark Constants

// General Tab

#define START_AT_LOGIN @"start_at_login"
#define CONFIRM_QUIT @"confirm_quit"
#define UPDATE_CHECKING @"update_checking"
#define SUBMIT_STATS @"submit_stats"

#define LOG_DAYS @"log_days"

// Controllers Tab

#define ALL_LOCATIONS @"all_locations"
#define CONTROLLER_TAB_TAG @"controller_tab_tag"

#define SERIAL_CONTROLLER_MODELS @"serial_controller_models"
#define SERIAL_CONTROLLER_PORTS @"serial_controller_ports"

#define NETWORK_ADDRESS @"network_address"
#define NETWORK_BUTTON_NAME @"network_button_name"

// Devices Tab

#define ENABLE_CALLER_ID @"enable_caller_id"
#define MODEM_MODELS @"modem_models"

// Remotes Tab

#define ENABLE_REMOTE_CONTROL @"enable_remote_control"
#define ENABLE_SPEECH_PROMPTS @"enable_speech_prompts"
#define ENABLE_LD_DISPLAY @"enable_ld_display"

// Online Tab

#define ENABLE_SHION_ONLINE @"enable_shion_online"
#define SHION_ONLINE_USER @"shion_online_user"
#define SHION_ONLINE_PASS @"shion_online_pass"
#define SHION_ONLINE_SITE @"shion_online_site"

@implementation PreferencesManager

#pragma mark -
#pragma mark Singleton Implementation

static PreferencesManager * sharedInstance = nil;

+ (PreferencesManager *) sharedInstance
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedInstance;
}

+ (id) allocWithZone:(NSZone *) zone
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
	
    return nil; //on subsequent allocation attempts return nil
}

- (id) copyWithZone:(NSZone *) zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (unsigned) retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void) release
{
    //do nothing
}

- (id) autorelease
{
    return self;
}

#pragma mark -
#pragma mark Standard Class Methods

- (id) init
{
	if (self = [super init])
	{
		updater = [[SUUpdater alloc] init];
		
		windowController = [[NSWindowController alloc] initWithWindowNibName:@"PreferencesWindow" owner:self];
	}
	
	return self;
}

- (IBAction) testNetworkController:(id) sender
{
	if ([[self valueForKey:NETWORK_CONTROLLER_MODEL] isEqual:CONTROLLER_SL2414])
	{
		NSURLRequest * request = [NSURLRequest requestWithURL:
									[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/buffstatus.xml", 
														  [self valueForKey:NETWORK_CONTROLLER_ADDRESS]]]];
		
		[[NSURLConnection connectionWithRequest:request delegate:self] retain];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if ([[self valueForKey:NETWORK_CONTROLLER_MODEL] isEqual:CONTROLLER_SL2414])
	{
		NSString * string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		
		if ([string rangeOfString:@"<response>"].location != NSNotFound)
			NSRunInformationalAlertPanel(@"Network Controller Found", @"The specified network controller was found. It is ready for use with Shion.", @"OK", nil, nil);
		else 
			NSRunAlertPanel(@"Host Found", @"The host was found, but does not appear to be a SmartLinc 2414N. Please check your host or IP address and try again.", @"OK", nil, nil);
		
		[string release];
	}
}
										

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[connection release];
	
	NSRunAlertPanel(@"Network Controller Missing", @"The specified network controller was not found. Please check your host or IP address and try again.", @"OK", nil, nil);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[connection release];
}

- (id) valueForKey:(NSString *) key
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	if ([key isEqual:UPDATE_CHECKING])
	{
		return [NSNumber numberWithBool:[updater automaticallyChecksForUpdates]];
	}	
	else if ([key isEqual:SUBMIT_STATS])
	{
		return [NSNumber numberWithBool:[updater sendsSystemProfile]];
	}
	else if ([key isEqual:ALL_LOCATIONS])
	{
		return [[ConsoleManager sharedInstance] valueForKey:ALL_LOCATIONS];
	}
	else if ([key isEqual:SERIAL_CONTROLLER_MODELS])
	{
		return [NSArray arrayWithObjects:CONTROLLER_CM11A, CONTROLLER_PL2412, CONTROLLER_PL2413, nil];
	}
	else if ([key isEqual:LOG_DAYS])
	{
		NSNumber * days = [defaults valueForKey:LOG_DAYS];
		
		if (days == nil)
			days = [NSNumber numberWithInt:7];
		
		return days;
	}
	else if ([key isEqual:SERIAL_CONTROLLER_PORTS])
	{
		NSMutableArray * ports = [NSMutableArray array];
		
		NSEnumerator * portIter = [[[AMSerialPortList sharedPortList] serialPorts] objectEnumerator];
		AMSerialPort * port = nil;
		while (port = [portIter nextObject])
			[ports addObject:[port name]];
		
		return ports;
	}
	else if ([key isEqual:MODEM_MODELS])
	{
		return [NSArray arrayWithObjects:MODEM_APPLEUSB, nil];
	}
	else if ([key isEqual:SITE_ICON])
	{
		NSData * icon = [defaults valueForKey:SITE_ICON];
		
		if (icon == nil)
		{
			icon = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shion-64" ofType:@"png"]];

			[self setValue:icon forKey:SITE_ICON];
		}
		
		return icon;
	}
	else
	{
		return [defaults valueForKey:key];
	}
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	[self willChangeValueForKey:key];

	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	if ([key isEqual:START_AT_LOGIN])
	{
		[defaults setValue:value forKey:START_AT_LOGIN];

		BOOL enabled = [value boolValue];
		
		OSStatus status;
		CFArrayRef loginItems = NULL;
		NSURL * url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
		
		int existingLoginItemIndex = -1;
		
		status = LIAECopyLoginItems (&loginItems);
		
		if (status == noErr) 
		{
			NSEnumerator * enumerator = [(NSArray *) loginItems objectEnumerator];
			NSDictionary * loginItemDict;
			
			while ((loginItemDict = [enumerator nextObject])) 
			{
				if ([[loginItemDict objectForKey:(NSString *) kLIAEURL] isEqual:url]) 
				{
					existingLoginItemIndex = [(NSArray *) loginItems indexOfObjectIdenticalTo:loginItemDict];
					break;
				}
			}
		}
		
		if (enabled && (existingLoginItemIndex == -1))
			LIAEAddURLAtEnd ((CFURLRef) url, false);
		else if (!enabled && (existingLoginItemIndex != -1))
			LIAERemove (existingLoginItemIndex);
		
		if (loginItems)
			CFRelease (loginItems);
	}
	else if ([key isEqual:UPDATE_CHECKING])
	{
		[updater setAutomaticallyChecksForUpdates:[value boolValue]];
	}	
	else if ([key isEqual:SUBMIT_STATS])
	{
		[updater setSendsSystemProfile:[value boolValue]];
	}
	else
	{
		if ([key isEqual:SITE_ICON])
		{
			NSBitmapImageRep * imageRep = [NSBitmapImageRep imageRepWithData:value];

			value = [imageRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
		}
		else if ([key isEqual:CONTROLLER_TYPE])
		{
			NSNumber * show = [self valueForKey:@"confirm_controller_change"];
			
			if (show == nil)
				show = [NSNumber numberWithBool:YES];
			
			if ([show boolValue])
			{
				NSAlert * panel = [[[NSAlert alloc] init] autorelease];
				[panel setAlertStyle:NSWarningAlertStyle];
				[panel setMessageText:NSLocalizedString(@"Please Restart Shion", nil)];
				[panel setInformativeText:NSLocalizedString(@"Please restart Shion after making changes to the controller configuration.", nil)];
				[panel addButtonWithTitle:NSLocalizedString(@"Ok", nil)];
			 
				if (getVersion() >= 0x1050)
				{
					[panel setShowsSuppressionButton:YES];
					NSButton * suppress = [panel suppressionButton];
					[[suppress cell] setControlSize:NSSmallControlSize];
					[suppress setTitle:NSLocalizedString(@"Please remind me again in the future.", nil)];
			 
					[[suppress cell] setFont:[NSFont labelFontOfSize:11]];
			 
					[suppress bind:@"value" toObject:[PreferencesManager sharedInstance]
					   withKeyPath:@"confirm_controller_change" options:[NSDictionary dictionary]];
				}
			 
				[panel runModal];
			}
		}
		
		
		[defaults setValue:value forKey:key];
	}	
	
	[self didChangeValueForKey:key];
}

- (IBAction) checkForUpdates:(id) sender
{
	[updater checkForUpdates:sender];
}

- (IBAction) serialPortInfo:(id) sender
{
	// TODO: Launch website with serial port information...
}

- (IBAction) detectOrVerifyNetwork:(id) sender
{
	// TODO: Look for controllers if no address is available or verify address if available.
}

- (BOOL) logEvent:(NSString *) eventType
{
	// TODO: Log Event?
	
	return YES;
}
	
- (IBAction) revealLogs:(id) sender
{
	NSString * logFolder = [[LogManager sharedInstance] analyticsFolder];
	
	[[NSWorkspace sharedWorkspace] openFile:logFolder];
}

- (IBAction) shionOnlineInfo:(id) sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.shiononline.com/"]];
}

- (IBAction) preferencesWindow:(id) sender
{
	[NSApp activateIgnoringOtherApps:YES];

	[windowController showWindow:sender];

	[window center];
	
	[window makeKeyAndOrderFront:sender];
}

- (BOOL) confirmQuit
{
	return [[[NSUserDefaults standardUserDefaults] valueForKey:CONFIRM_QUIT] boolValue];
}

- (void) setConfirmQuit:(BOOL) confirm
{
	[self willChangeValueForKey:@"confirmQuit"];
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:confirm] forKey:CONFIRM_QUIT];
	[self didChangeValueForKey:@"confirmQuit"];
}

- (NSDictionary *) controllerDetails
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary * details = [NSMutableDictionary dictionary];
	
	[details setValue:[defaults valueForKey:CONTROLLER_TYPE] forKey:CONTROLLER_TYPE];
	[details setValue:[defaults valueForKey:CONTROLLER_LOCATION] forKey:CONTROLLER_LOCATION];
	
	if ([[details valueForKey:CONTROLLER_TYPE] isEqual:CONTROLLER_SERIAL])
	{
		[details setValue:[defaults valueForKey:SERIAL_CONTROLLER_PORT] forKey:SERIAL_CONTROLLER_PORT];
		[details setValue:[defaults valueForKey:SERIAL_CONTROLLER_MODEL] forKey:SERIAL_CONTROLLER_MODEL];
	}
	else if ([[details valueForKey:CONTROLLER_TYPE] isEqual:CONTROLLER_NETWORK])
	{
		[details setValue:[defaults valueForKey:NETWORK_CONTROLLER_ADDRESS] forKey:NETWORK_CONTROLLER_ADDRESS];
		[details setValue:[defaults valueForKey:NETWORK_CONTROLLER_MODEL] forKey:NETWORK_CONTROLLER_MODEL];
	}
	
	return details;
}

- (NSDictionary *) phoneDetails
{
	if ([self valueForKey:ENABLE_CALLER_ID] == nil || [[self valueForKey:ENABLE_CALLER_ID] boolValue] == false)
		return nil;
	
	NSMutableDictionary * details = [NSMutableDictionary dictionary];

	[details setValue:[self valueForKey:MODEM_MODEL] forKey:MODEM_MODEL];
	[details setValue:[self valueForKey:MODEM_PORT] forKey:MODEM_PORT];
	[details setValue:[self valueForKey:MODEM_LOCATION] forKey:MODEM_LOCATION];

	return details;
}

- (void) showControllerDetails
{
	[self preferencesWindow:self];
	
	[preferenceTabs selectTabViewItemWithIdentifier:@"2"];
}

- (IBAction) findPositionOnline:(id) sender
{
	NSURL * posUrl = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"Position Finder URL"]];
	
	[[NSWorkspace sharedWorkspace] openURL:posUrl];
}

- (BOOL) selectTabNamed:(NSString *) name
{
	[preferenceTabs selectTabViewItemWithIdentifier:@"Site"];
	
	return YES;
}

@end
