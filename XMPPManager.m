//
//  XMPPManager.m
//  Shion
//
//  Created by Chris Karr on 7/27/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Shion/ASDeviceController.h>

#import "XMPPManager.h"
#import "XMPPIQCommand.h"
#import "XMPPUserActivityCommand.h"
#import "XMPPPublishAvatarDataCommand.h"
#import "XMPPUpdateAvatarMetadataCommand.h"

#import "XMPPVCardTempRequestCommand.h"

#import "NotificationManager.h"
#import "Command.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <SSCrypto/SSCrypto.h>

#import "ShionRemoteEventMessage.h"

#import "DialogManager.h"
#import "PreferencesManager.h"
#import "DeviceManager.h"
#import "SnapshotManager.h"
#import "EventManager.h"
#import "TriggerManager.h"

#import "Appliance.h"
#import "Thermostat.h"
#import "MotionSensor.h"
#import "PowerSensor.h"
#import "Controller.h"
#import "Phone.h"
#import "ApertureSensor.h"
#import "MobileClient.h"
#import "Lock.h"
#import "GarageHawk.h"
#import "PowerMeterSensor.h"
#import "WeatherUndergroundStation.h"

#import "AppDelegate.h"

#define SHION_SUFFIX @"@subspace.shiononline.com"

@implementation XMPPManager

static XMPPManager * sharedInstance = nil;

+ (XMPPManager *) sharedInstance
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

- (id) init
{
	if (self = [super init])
	{
		PreferencesManager * preferences = [PreferencesManager sharedInstance];
		
		client = [[XMPPClient alloc] init];
		[client addDelegate:self];
		[client setAutoLogin:NO];
		[client setAutoRoster:YES];
		[client setAutoPresence:YES];
		[client setAllowsSelfSignedCertificates:YES];
		[client setAllowsSSLHostNameMismatch:YES];
		
		if ([preferences valueForKey:@"shion_online_site"] == nil)
			[preferences setValue:[(NSString *) SCDynamicStoreCopyComputerName(NULL, NULL) autorelease] forKeyPath:@"shion_online_site"];
		
		if ([preferences valueForKey:@"enable_shion_online"] == nil)
			[preferences setValue:[NSNumber numberWithBool:NO] forKeyPath:@"enable_shion_online"];
		
		[preferences addObserver:self forKeyPath:@"enable_shion_online" options:0 context:NULL];
		[preferences addObserver:self forKeyPath:@"shion_online_user" options:0 context:NULL];
		[preferences addObserver:self forKeyPath:@"shion_online_pass" options:0 context:NULL];
		[preferences addObserver:self forKeyPath:@"shion_online_site" options:0 context:NULL];
		[preferences addObserver:self forKeyPath:@"site_icon" options:0 context:NULL];
		
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(post:) name:XMPP_NOTIFICATION object:nil];
		
		[self observeValueForKeyPath:@"enable_shion_online" ofObject:preferences change:nil context:NULL];
		
		iconPosted = NO;
		
		clientJids = [[NSMutableArray alloc] init];
		
		[[NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(refreshPresence:) userInfo:nil repeats:YES] retain];
		
		lastStatusString = nil;
	}
	
	return self;
}

- (void) updateStatus:(NSString *) status available:(BOOL) available
{
	if (lastStatusString != nil)
	{
		[lastStatusString release];
		lastStatusString = [status retain];
	}
	
	if ([client isConnected] && [client isAuthenticated])
	{
		if (!iconPosted)
		{
			XMPPVCardTempRequestCommand * vcardCommand = [[XMPPVCardTempRequestCommand alloc] initWithFrom:@"" to:@"" type:@"set" id:@"upload-vcard" query:@""];
			[client sendElement:[vcardCommand execute]];
			[vcardCommand release];
			
			iconPosted = YES;
		}
		
		XMPPUserActivityCommand * command = [[XMPPUserActivityCommand alloc] initWithFrom:@""
																					   to:[[client myJID] full]
																					 type:@"set" 
																					   id:@"publish"
																					query:@""];
		[command setActivity:status];
		
		[client sendElement:[command execute]];
		
		[command release];
		
		NSXMLElement * presence = [NSXMLElement elementWithName:@"presence"];
		
		NSXMLElement * show = [NSXMLElement elementWithName:@"show"];
		[show setStringValue:@"chat"];
		[presence addChild:show];
		
		NSXMLElement * statusElement = [NSXMLElement elementWithName:@"status"];
		[statusElement setStringValue:status];
		[presence addChild:statusElement];
		
		[client sendElement:presence];
	}
}

- (void) refreshPresence:(NSTimer *) theTimer
{
	if ([client isConnected] && [client isAuthenticated])
	{
		NSXMLElement * presence = [NSXMLElement elementWithName:@"presence"];
		
		NSXMLElement * statusElement = [NSXMLElement elementWithName:@"status"];
		[statusElement setStringValue:lastStatusString];
		[presence addChild:statusElement];
		
		[client sendElement:presence];
	}
}

- (NSString *) domainForString:(NSString *) username
{
	if (username == nil)
		return nil;
	
	int start = [username rangeOfString:@"@"].location;
	
	if (start == NSNotFound)
		start = 0;
	
	return [username substringFromIndex:start + 1];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	PreferencesManager * preferences = [PreferencesManager sharedInstance];
	
	if ([client isConnected])
	{
		[client disconnect];
		
		// TODO: Verify
		
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setValue:@"Remote Sharing: Disconnected" forKey:NOTIFICATION_TITLE];
		[userInfo setValue:@"Shion disconnected from the remote sharing server." forKey:NOTIFICATION_MESSAGE];
		[userInfo setValue:XMPP_COMMAND forKey:NOTIFICATION_TYPE];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];
	}		
	
	if ([[preferences valueForKey:@"enable_shion_online"] boolValue])
	{
		NSString * username = [[preferences valueForKey:@"shion_online_user"] stringByAppendingString:SHION_SUFFIX];

		NSString * domain = [self domainForString:username];
		
		NSString * password = [preferences valueForKey:@"shion_online_pass"];
		
		NSMutableString * site = [NSMutableString stringWithString:[preferences valueForKey:@"shion_online_site"]];
		
		[site replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [site length])];
		
		if (domain != nil && username != nil && password != nil)
		{
			iconPosted = NO;
			
			[client setDomain:domain];
			
			[client setPort:5222];
			
			XMPPJID *jid = [XMPPJID jidWithString:username resource:site];
			
			[client setMyJID:jid];
			
			[client setPassword:password];
			
			[client connect];
			
			[((AppDelegate *) [NSApp delegate]) setStatusError:YES];
		}
	}
	else
		[((AppDelegate *) [NSApp delegate]) setStatusError:NO];
}

- (void)xmppClientDidConnect:(XMPPClient *)sender
{
	[client authenticateUser];

	[((AppDelegate *) [NSApp delegate]) setStatusError:YES];
}

- (void)xmppClientDidNotConnect:(XMPPClient *)sender
{
	if ([sender streamError])
	{
		// TODO: Verify
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setValue:@"Remote Sharing: Error" forKey:NOTIFICATION_TITLE];
		[userInfo setValue:[NSString stringWithFormat:@"Shion was unable to connect to the remote sharing server: %@", [sender streamError]] forKey:NOTIFICATION_MESSAGE];
		[userInfo setValue:XMPP_COMMAND forKey:NOTIFICATION_TYPE];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];
	}

	[((AppDelegate *) [NSApp delegate]) setStatusError:YES];
}

- (void)xmppClientDidDisconnect:(XMPPClient *)sender
{
	if ([sender streamError])
	{
		// TODO: Verify
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setValue:@"Remote Sharing: Disconnected" forKey:NOTIFICATION_TITLE];
		[userInfo setValue:[NSString stringWithFormat:@"Shion was disconnected from the remote sharing server: %@", [sender streamError]] forKey:NOTIFICATION_MESSAGE];
		[userInfo setValue:XMPP_COMMAND forKey:NOTIFICATION_TYPE];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];
	}

	[((AppDelegate *) [NSApp delegate]) setStatusError:YES];

	[self observeValueForKeyPath:@"enable_shion_online" ofObject:[PreferencesManager sharedInstance] change:nil context:NULL];
}

- (void)xmppClientDidAuthenticate:(XMPPClient *)sender
{
	// TODO: Verify
	
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setValue:@"Remote Sharing: Connected" forKey:NOTIFICATION_TITLE];
	[userInfo setValue:@"Shion successfully connected to the remote sharing server." forKey:NOTIFICATION_MESSAGE];
	[userInfo setValue:XMPP_COMMAND forKey:NOTIFICATION_TYPE];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];
	
	[self updateStatus:@"Initializing" available:YES];
	
	[((AppDelegate *) [NSApp delegate]) setStatusError:NO];
}

- (void)xmppClient:(XMPPClient *)sender didNotAuthenticate:(NSXMLElement *)error
{
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setValue:@"Remote Sharing: Authentication Problem" forKey:NOTIFICATION_TITLE];
	[userInfo setValue:@"Shion did not successfully connect to the remote sharing server. Please check your username and password." forKey:NOTIFICATION_MESSAGE];
	[userInfo setValue:XMPP_COMMAND forKey:NOTIFICATION_TYPE];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];

	[((AppDelegate *) [NSApp delegate]) setStatusError:YES];
}

- (void)xmppClientDidUpdateRoster:(XMPPClient *)sender
{
}

- (void)xmppClient:(XMPPClient *)sender didReceiveIQ:(XMPPIQ *)iq
{
	BOOL authorized = NO;
	
	XMPPJID * from = [iq from];
	
	if ([[[iq attributeForName:@"type"] stringValue] isEqual:@"result"])
	{
		// DO something?
	}
	else
	{
		XMPPIQCommand * command = [XMPPIQCommand commandForElement:iq sender:self];
		
		[sender sendElement:[command execute]];
		
		authorized = YES;
	}
	
	if (!authorized)
	{
		NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
		
		[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"error", @"type", [[[sender myUser] jid] bare], @"from", [from bare], @"to", nil]];
		
		NSXMLElement * error = [NSXMLElement elementWithName:@"error"];
		[error setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"auth" forKey:@"type"]];
		
		NSXMLElement * forbidden = [NSXMLElement elementWithName:@"forbidden"];
		[forbidden addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"urn:ietf:params:xml:ns:xmpp-stanzas"]];
		[error addChild:forbidden];
		
		[iq addChild:error];
		
		[sender sendElement:iq];
	}
}

- (NSString *) responseForMessage:(NSString *) message
{
	Command * cmd = [[DialogManager sharedInstance] commandForString:message];
	
	NSString * response = nil;
	
	if (cmd != nil)
	{
		NSDictionary * results = [cmd execute];
		
		if ([[results valueForKey:CMD_SUCCESS] boolValue])
			response = [results valueForKey:CMD_RESULT_DESC];
		else
			response = [NSString stringWithFormat:@"There was a problem carrying out your request: %@", [results valueForKey:CMD_RESULT_DESC]];
	}
	else
		response = [NSString stringWithFormat:@"Sorry, but I was unable to understand your request. Can you state it another way, perhaps?", message];
	
	return response;
}

- (void) replyTo:(NSString *) sender forMessage:(NSString *) message client:(XMPPClient *) xmpp 
{
	// TODO: Verify
	
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setValue:@"Remote Sharing: Received Request" forKey:NOTIFICATION_TITLE];
	[userInfo setValue:[NSString stringWithFormat:@"%@: %@", sender, message] forKey:NOTIFICATION_MESSAGE];
	[userInfo setValue:XMPP_COMMAND forKey:NOTIFICATION_TYPE];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];
	
	NSString * response = [self responseForMessage:message];
	
	NSXMLElement * body = [NSXMLElement elementWithName:@"body"];
	[body setStringValue:response];
	
	NSXMLElement * myMessage = [NSXMLElement elementWithName:@"message"];
	[myMessage addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"chat"]];
	[myMessage addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:sender]];
	
	[myMessage addChild:body];
	
	[xmpp sendElement:myMessage];
}

- (void)xmppClient:(XMPPClient *)sender didReceiveMessage:(XMPPMessage *)message
{
	BOOL authorized = NO;
	
	XMPPJID * from = [message from];
	
	[client fetchRoster];
	NSArray * online = [[client unsortedUsers] arrayByAddingObject:[sender myUser]];
	
	NSEnumerator * iter = [online objectEnumerator];
	XMPPUser * user = nil;
	while (user = [iter nextObject])
	{
		if ([[[user jid] bare] isEqual:[from bare]] && !authorized)
		{
			NSArray * children = [message elementsForName:@"body"];
			
			if ([children count] > 0)
			{
				NSEnumerator * childIter = [children objectEnumerator];
				NSXMLElement * body = nil;
				while (body = [childIter nextObject])
					[self replyTo:[[message attributeForName:@"from"] stringValue] forMessage:[body stringValue] client:sender];
			}
			
			authorized = YES;
		}
	}
	
	if (!authorized)
	{
		NSXMLElement * myMessage = [NSXMLElement elementWithName:@"message"];
		[myMessage addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:[from bare]]];
		
		NSXMLElement * error = [NSXMLElement elementWithName:@"error"];
		[error setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"auth" forKey:@"type"]];
		
		NSXMLElement * forbidden = [NSXMLElement elementWithName:@"forbidden"];
		[forbidden addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"urn:ietf:params:xml:ns:xmpp-stanzas"]];
		[error addChild:forbidden];
		
		[myMessage addChild:error];
		
		[sender sendElement:myMessage];
	}
}

- (BOOL) sendEnvironmentToJid:(NSString *) jid
{
	if (![clientJids containsObject:jid])
		[clientJids addObject:jid];
	
	PreferencesManager * preferences = [PreferencesManager sharedInstance];
	
	NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
	
	[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"set", @"type", [[[client myUser] jid] bare], @"from", jid, @"to", nil]];
	[iq addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:site-information"]];
	
	NSXMLElement * site = [NSXMLElement elementWithName:@"site-information"];
	[site setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[preferences valueForKey:@"shion_online_site"] forKey:@"name"]];
	
	NSXMLElement * devices = [NSXMLElement elementWithName:@"ds"];
	
	NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		NSXMLElement * deviceElement = [NSXMLElement elementWithName:@"d"];
		
		NSMutableDictionary * atts = [NSMutableDictionary dictionary];
		
		[atts setValue:[device name] forKey:@"n"];
		[atts setValue:[device address] forKey:@"a"];
		[atts setValue:[device location] forKey:@"l"];
		[atts setValue:[device type] forKey:@"t"];
		[atts setValue:[device model] forKey:@"m"];
		[atts setValue:[device identifier] forKey:@"i"];
		[atts setValue:[device platform] forKey:@"p"];
		
		if ([device isKindOfClass:[Appliance class]])
		{
			Appliance * a = (Appliance *) device;
			
			[atts setValue:[[a level] stringValue] forKey:@"lv"];
		}
		else if ([device isKindOfClass:[Thermostat class]])
		{
			Thermostat * t = (Thermostat *) device;
			
			[atts setValue:[t mode] forKey:@"md"];
			[atts setValue:[[t temperature] stringValue] forKey:@"tp"];
			[atts setValue:[[t coolPoint] stringValue] forKey:@"cp"];
			[atts setValue:[[t heatPoint] stringValue] forKey:@"hp"];
		}
		else if ([device isKindOfClass:[MotionSensor class]])
		{
			MotionSensor * a = (MotionSensor *) device;
			
			if ([a detectingMotion])
				[atts setValue:[NSNumber numberWithInt:255] forKey:@"lv"];
			else
				[atts setValue:[NSNumber numberWithInt:0] forKey:@"lv"];
		}
		else if ([device isKindOfClass:[ApertureSensor class]])
		{
			ApertureSensor * a = (ApertureSensor *) device;
			
			if ([a open])
				[atts setValue:[NSNumber numberWithInt:255] forKey:@"lv"];
			else
				[atts setValue:[NSNumber numberWithInt:0] forKey:@"lv"];
		}
		else if ([device isKindOfClass:[PowerSensor class]])
		{
			PowerSensor * a = (PowerSensor *) device;
			
			if ([a isActive])
				[atts setValue:[NSNumber numberWithInt:255] forKey:@"lv"];
			else
				[atts setValue:[NSNumber numberWithInt:0] forKey:@"lv"];
		}
		else if ([device isKindOfClass:[PowerMeterSensor class]])
		{
			PowerMeterSensor * a = (PowerMeterSensor *) device;
			
			[atts setValue:[a level] forKey:@"lv"];
		}
		else if ([device isKindOfClass:[WeatherUndergroundStation class]])
		{
			WeatherUndergroundStation * a = (WeatherUndergroundStation *) device;
			
			[atts setValue:[[a temperature] stringValue] forKey:@"tp"];
		}
		else if ([device isKindOfClass:[Lock class]])
		{
			Lock * a = (Lock *) device;
			
			if ([a isLocked])
				[atts setValue:[NSNumber numberWithInt:255] forKey:@"lv"];
			else
				[atts setValue:[NSNumber numberWithInt:0] forKey:@"lv"];
		}
		else if ([device isKindOfClass:[GarageHawk class]])
		{
			GarageHawk * a = (GarageHawk *) device;
			
			NSNumber * level = [a valueForKey:DEVICE_LEVEL];
			
			if (level == nil)
				level = [NSNumber numberWithUnsignedInt:192];
			
			[atts setValue:level forKey:@"lv"];
		}
		else if ([device isKindOfClass:[Controller class]])
		{
			Controller * a = (Controller *) device;
			
			float lastStatus = [a networkState];
			
			if (lastStatus >= 0)
				[atts setValue:[NSNumber numberWithFloat:(255 * lastStatus)] forKey:@"lv"];
		}
		else if ([device isKindOfClass:[Phone class]])
		{
			[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
			NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"yyyy-MM-dd kk:mm.ssz"];

			Event * event = [[EventManager sharedInstance] lastUpdateForIdentifier:@"Phone" event:@"device"];

			if (event != nil)
			{
				NSMutableDictionary * call = [event value];
				
				[atts setValue:[call valueForKey:@"caller_name"] forKey:@"nm"];
				[atts setValue:[call valueForKey:@"number"] forKey:@"nb"];
				[atts setValue:[formatter stringFromDate:[event date]] forKey:@"dt"];
			}
			
			[formatter release];
		}
		else if ([device isKindOfClass:[MobileClient class]])
		{
			MobileClient * a = (MobileClient *) device;

			[atts setValue:[a version] forKey:@"sv"];
			[atts setValue:[a valueForKey:@"mobile_status"] forKey:@"st"];
			[atts setValue:[a valueForKey:@"mobile_caller"] forKey:@"lc"];

			NSNumber * lat = [a valueForKey:@"mobile_latitude"];
			NSString * lon = [a valueForKey:@"mobile_longitude"];
			
			if (lat != nil && lon != nil)
			{
				[atts setValue:[lat description] forKey:@"lat"];
				[atts setValue:[lon description] forKey:@"lon"];
			}
		}
		
		[deviceElement setAttributesAsDictionary:atts];
		[devices addChild:deviceElement];
	}
	
	[site addChild:devices];
	
	NSXMLElement * snapshots = [NSXMLElement elementWithName:@"ss"];
	
	NSEnumerator * snapIter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
	Snapshot * snap = nil;
	while (snap = [snapIter nextObject])
	{
		NSXMLElement * snapshotElement = [NSXMLElement elementWithName:@"s"];
		
		NSMutableDictionary * atts = [NSMutableDictionary dictionary];
		
		[atts setValue:[snap name] forKey:@"n"];
		[atts setValue:[snap category] forKey:@"c"];
		[atts setValue:[snap identifier] forKey:@"i"];

		[snapshotElement setAttributesAsDictionary:atts];
		deviceIter = [[snap snapshotDevices] objectEnumerator];
		NSDictionary * deviceDict = nil;
		while (deviceDict = [deviceIter nextObject])
		{
			NSXMLElement * deviceElement = [NSXMLElement elementWithName:@"d"];

			[deviceElement setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[deviceDict valueForKey:@"name"] forKey:@"n"]];
			[deviceElement setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[deviceDict valueForKey:@"identifier"] forKey:@"i"]];
			[deviceElement setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[deviceDict valueForKey:@"description"] forKey:@"d"]];

			[snapshotElement addChild:deviceElement];
		}
		
		[snapshots addChild:snapshotElement];
	}
	
	[site addChild:snapshots];

	NSXMLElement * triggers = [NSXMLElement elementWithName:@"ts"];

	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd kk:mm.ssz"];
	
	NSEnumerator * triggerIter = [[[TriggerManager sharedInstance] triggers] objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [triggerIter nextObject])
	{
		NSXMLElement * triggerElement = [NSXMLElement elementWithName:@"t"];
		
		NSMutableDictionary * atts = [NSMutableDictionary dictionary];
		
		[atts setValue:[trigger name] forKey:@"n"];
		[atts setValue:[trigger identifier] forKey:@"i"];
		[atts setValue:[trigger description] forKey:@"d"];
		[atts setValue:[trigger actionDescription] forKey:@"a"];
		
		if ([trigger fired] != nil)
			[atts setValue:[formatter stringFromDate:[trigger fired]] forKey:@"df"];

		if ([trigger type] != nil)
			[atts setValue:[trigger type] forKey:@"ty"];

		[triggerElement setAttributesAsDictionary:atts];

		[triggers addChild:triggerElement];
	}
	
	[formatter release];
	
	[site addChild:triggers];
	
	[iq addChild:site];
	
	[client sendElement:iq];
	
	return YES;
}

- (BOOL) sendEventsForDevice:(NSString *) deviceId toJid:(NSString *) jid forDateString:(NSString *) dateString
{
	NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		if ([[device identifier] isEqual:deviceId])
		{
			if ([device isKindOfClass:[Controller class]])
				deviceId = @"Controller";
			else if ([device isKindOfClass:[Phone class]])
				deviceId = @"Phone";
		}
	}
	
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];

	NSDateFormatter * dayFormatter = [[NSDateFormatter alloc] init];
	[dayFormatter setDateFormat:@"yyyy-MM-dd"];
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd kk:mm.ssz"];
	
	NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
	
	[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"set", @"type", [[[client myUser] jid] bare], @"from", jid, @"to", nil]];
	[iq addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:device-events"]];
	
	NSXMLElement * events = [NSXMLElement elementWithName:@"es"];
	
	if ([deviceId isEqual:@"Controller"])
	{
		NSArray * controllerEvents = [[EventManager sharedInstance] eventsForIdentifier:@"Controller"];			
		
		deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([device isKindOfClass:[Controller class]])
			{
				[events setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[device identifier] forKey:@"d"]];
				
				NSEnumerator * eventIter = [controllerEvents objectEnumerator];
				Event * event = nil;
				while (event = [eventIter nextObject])
				{
					if ([[dayFormatter stringFromDate:[event date]] isEqual:dateString])
					{
						NSXMLElement * eventElement = [NSXMLElement elementWithName:@"e"];
						
						NSMutableDictionary * atts = [NSMutableDictionary dictionary];
						[atts setValue:[formatter stringFromDate:[event date]] forKey:@"dt"];
						[atts setValue:[event value] forKey:@"v"];
						[atts setValue:[event type] forKey:@"t"];
						
						[eventElement setAttributesAsDictionary:atts];
						
						[events addChild:eventElement];
					}
				}
			}
		}
	}
	else if ([deviceId isEqual:@"Phone"])
	{
		NSArray * controllerEvents = [[EventManager sharedInstance] eventsForIdentifier:@"Phone"];			
		
		deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([device isKindOfClass:[Phone class]])
			{
				[events setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[device identifier] forKey:@"d"]];
				
				NSEnumerator * eventIter = [controllerEvents objectEnumerator];
				Event * event = nil;
				while (event = [eventIter nextObject])
				{
					if ([[dayFormatter stringFromDate:[event date]] isEqual:dateString])
					{
						NSDictionary * call = [event value];
						
						NSXMLElement * eventElement = [NSXMLElement elementWithName:@"e"];
						
						NSMutableDictionary * atts = [NSMutableDictionary dictionary];
						[atts setValue:[formatter stringFromDate:[event date]] forKey:@"dt"];
						[atts setValue:[event type] forKey:@"t"];
						
						[atts setValue:[call valueForKey:@"number"] forKey:@"nb"];
						[atts setValue:[call valueForKey:@"caller_name"] forKey:@"nm"];
						
						[atts setValue:[NSNumber numberWithInt:((256 * 256) - 1)] forKey:@"v"];
						
						// [eventElement setStringValue:[event description]];
						
						[eventElement setAttributesAsDictionary:atts];
						
						[events addChild:eventElement];
					}
				}
			}
		}
	}
	else
	{
		deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		device = nil;
		while(device = [deviceIter nextObject])
		{
			if ([[device identifier] isEqual:deviceId])
			{
				[events setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[device identifier] forKey:@"d"]];
				
				NSEnumerator * eventIter = [[device events] objectEnumerator];
				Event * event = nil;
				while (event = [eventIter nextObject])
				{
					if ([[dayFormatter stringFromDate:[event date]] isEqual:dateString])
					{
						NSXMLElement * eventElement = [NSXMLElement elementWithName:@"e"];
						
						id value = [event value];
						
						NSMutableDictionary * atts = [NSMutableDictionary dictionary];
						[atts setValue:[formatter stringFromDate:[event date]] forKey:@"dt"];

						if ([value isKindOfClass:[NSNumber class]])
							[atts setValue:[value stringValue] forKey:@"v"];
						else
							[atts setValue:[value description] forKey:@"v"];
						
						[atts setValue:[event type] forKey:@"t"];
						
						[eventElement setAttributesAsDictionary:atts];
						
						[events addChild:eventElement];
					}
				}
			}
		}
	}
	
	[iq addChild:events];
	[client sendElement:iq];
	
	[formatter release];
	[dayFormatter release];
	
	return YES;
}


- (BOOL) sendEventsForDevice:(NSString *) deviceId toJid:(NSString *) jid
{
	NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		if ([[device identifier] isEqual:deviceId])
		{
			if ([device isKindOfClass:[Controller class]])
				deviceId = @"Controller";
			else if ([device isKindOfClass:[Phone class]])
				deviceId = @"Phone";
		}
	}
	
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd kk:mm.ssz"];
	
	NSTimeInterval twoWeeks = 60 * 60 * 24 * 14;
	
	NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
	
	[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"set", @"type", [[[client myUser] jid] bare], @"from", jid, @"to", nil]];
	[iq addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:device-events"]];

	NSXMLElement * events = [NSXMLElement elementWithName:@"es"];

	if ([deviceId isEqual:@"Controller"])
	{
		NSArray * controllerEvents = [[EventManager sharedInstance] eventsForIdentifier:@"Controller"];			
		
		deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([device isKindOfClass:[Controller class]])
			{
				[events setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[device identifier] forKey:@"d"]];
				
				NSEnumerator * eventIter = [controllerEvents objectEnumerator];
				Event * event = nil;
				while (event = [eventIter nextObject])
				{
					if (fabs([[event date] timeIntervalSinceNow]) <= twoWeeks)
					{
						NSXMLElement * eventElement = [NSXMLElement elementWithName:@"e"];
						
						NSMutableDictionary * atts = [NSMutableDictionary dictionary];
						[atts setValue:[formatter stringFromDate:[event date]] forKey:@"dt"];
						[atts setValue:[event value] forKey:@"v"];
						[atts setValue:[event type] forKey:@"t"];
						
						[eventElement setAttributesAsDictionary:atts];
						
						[events addChild:eventElement];
					}
				}
			}
		}
	}
	else if ([deviceId isEqual:@"Phone"])
	{
		NSArray * controllerEvents = [[EventManager sharedInstance] eventsForIdentifier:@"Phone"];			
		
		deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([device isKindOfClass:[Phone class]])
			{
				[events setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[device identifier] forKey:@"d"]];
				
				NSEnumerator * eventIter = [controllerEvents objectEnumerator];
				Event * event = nil;
				while (event = [eventIter nextObject])
				{
					if (fabs([[event date] timeIntervalSinceNow]) <= twoWeeks)
					{
						NSDictionary * call = [event value];
						
						NSXMLElement * eventElement = [NSXMLElement elementWithName:@"e"];
						
						NSMutableDictionary * atts = [NSMutableDictionary dictionary];
						[atts setValue:[formatter stringFromDate:[event date]] forKey:@"dt"];
						[atts setValue:[event type] forKey:@"t"];

						[atts setValue:[call valueForKey:@"number"] forKey:@"nb"];
						[atts setValue:[call valueForKey:@"caller_name"] forKey:@"nm"];

						[atts setValue:[NSNumber numberWithInt:((256 * 256) - 1)] forKey:@"v"];

//						[eventElement setStringValue:[event description]];
						
						[eventElement setAttributesAsDictionary:atts];
						
						[events addChild:eventElement];
					}
				}
			}
		}
	}
	else
	{
		deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		device = nil;
		while(device = [deviceIter nextObject])
		{
			if ([[device identifier] isEqual:deviceId])
			{
				[events setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[device identifier] forKey:@"d"]];

				NSEnumerator * eventIter = [[device events] objectEnumerator];
				Event * event = nil;
				while (event = [eventIter nextObject])
				{
					if (fabs([[event date] timeIntervalSinceNow]) <= twoWeeks)
					{
						NSXMLElement * eventElement = [NSXMLElement elementWithName:@"e"];

						id value = [event value];
						
						NSMutableDictionary * atts = [NSMutableDictionary dictionary];
						[atts setValue:[formatter stringFromDate:[event date]] forKey:@"dt"];
						[atts setValue:[event type] forKey:@"t"];

						if ([value isKindOfClass:[NSNumber class]])
							[atts setValue:[value stringValue] forKey:@"v"];
						else
							[atts setValue:[value description] forKey:@"v"];

						[eventElement setAttributesAsDictionary:atts];
						
						[events addChild:eventElement];
					}
				}
			}
		}
		
	}
	
	[iq addChild:events];
	[client sendElement:iq];
	
	[formatter release];
	
	return YES;
}

- (void) broadcastEvent:(Event *) event forIdentifier:(NSString *) identifier
{
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd kk:mm.ssz"];
	
	if ([identifier isEqual:@"Phone"])
	{
		NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		Device * device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([device isKindOfClass:[Phone class]])
				identifier = [device identifier];
		}
	}
	else if ([identifier isEqual:@"Controller"])
	{
		NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		Device * device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([device isKindOfClass:[Controller class]])
				identifier = [device identifier];
		}
	}

	NSEnumerator * jidIter = [clientJids objectEnumerator];
	NSString * jid = nil;
	while (jid = [jidIter nextObject])
	{
		NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
		
		[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"set", @"type", [[[client myUser] jid] bare], @"from", jid, @"to", nil]];
		[iq addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:device-event"]];
		
		NSXMLElement * eventElement = [NSXMLElement elementWithName:@"event"];
		
		NSMutableDictionary * atts = [NSMutableDictionary dictionary];
		[atts setValue:[formatter stringFromDate:[event date]] forKey:@"dt"];

		id value = [event value];
		
		if ([value isKindOfClass:[NSDictionary class]])
		{
			NSXMLElement * valueElement = [NSXMLElement elementWithName:@"dictionary"];
			
			[valueElement setAttributesAsDictionary:value];
			
			[eventElement addChild:valueElement];
		}
		else
			[atts setValue:[value description] forKey:@"v"];

		[atts setValue:[event description] forKey:@"description"];
		[atts setValue:[event type] forKey:@"t"];
		[atts setValue:identifier forKey:@"s"];
		
		[eventElement setAttributesAsDictionary:atts];
		
		[iq addChild:eventElement];
		[client sendElement:iq];
	}
	
	[formatter release];
}

- (void) beaconDevice:(Device *) device
{
	if (![device isKindOfClass:[MobileClient class]])
		return;
	
	NSEnumerator * jidIter = [clientJids objectEnumerator];
	NSString * jid = nil;
	while (jid = [jidIter nextObject])
	{
		NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
		
		[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"set", @"type", [[[client myUser] jid] bare], @"from", jid, @"to", nil]];
		[iq addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:device-event"]];
		
		NSXMLElement * beaconElement = [NSXMLElement elementWithName:@"beacon"];
		
		NSMutableDictionary * atts = [NSMutableDictionary dictionary];
		[atts setValue:[device identifier] forKey:@"id"];
		
		[beaconElement setAttributesAsDictionary:atts];
		
		[iq addChild:beaconElement];
		[client sendElement:iq];
	}
}

- (void) transmitPhotoList:(NSArray *) photos forCamera:(Camera *) camera
{
	if (![camera isKindOfClass:[Camera class]])
		return;
	
	NSEnumerator * jidIter = [clientJids objectEnumerator];
	NSString * jid = nil;
	while (jid = [jidIter nextObject])
	{
		NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
		
		[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"set", @"type", [[[client myUser] jid] bare], @"from", jid, @"to", nil]];
		[iq addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:photo-list"]];
		
		NSXMLElement * photosElement = [NSXMLElement elementWithName:@"photos"];
		[photosElement setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[camera identifier] forKey:@"camera"]];
		
		NSEnumerator * listIter = [photos objectEnumerator];
		NSString * photoId = nil;
		while (photoId = [listIter nextObject])
		{
			NSXMLElement * photoElement = [NSXMLElement elementWithName:@"photo"];
			[photoElement setAttributesAsDictionary:[NSDictionary dictionaryWithObject:photoId forKey:@"id"]];
			
			[photosElement addChild:photoElement];
		}

		[iq addChild:photosElement];
		[client sendElement:iq];
	}
}

- (void) transmitPhoto:(NSDictionary *) photo forCamera:(Camera *) camera
{
	if (![camera isKindOfClass:[Camera class]])
		return;
	
	NSEnumerator * jidIter = [clientJids objectEnumerator];
	NSString * jid = nil;
	while (jid = [jidIter nextObject])
	{
		NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
		
		[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"set", @"type", [[[client myUser] jid] bare], @"from", jid, @"to", nil]];
		[iq addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:photo-list"]];
		
		NSXMLElement * photoElement = [NSXMLElement elementWithName:@"photo"];

		NSString * date = [[photo valueForKey:@"date"] description];
		
		NSMutableDictionary * photoDict = [NSMutableDictionary dictionary];
		[photoDict setValue:[photo valueForKey:@"identifier"] forKey:@"id"];
		[photoDict setValue:date forKey:@"date"];
		[photoDict setValue:[camera identifier] forKey:@"camera"];

		[photoElement setAttributesAsDictionary:photoDict];
		
		NSData * data = [photo valueForKey:@"data"];
		
		[photoElement setStringValue:[data encodeBase64]];
		
		[iq addChild:photoElement];
		[client sendElement:iq];
	}
}

- (NSXMLElement *) elementForRecording:(NSDictionary *) show
{
	if ([show valueForKey:@"children"] != nil)
	{
		NSXMLElement * element = [NSXMLElement elementWithName:@"folder"];
		
		NSMutableDictionary * atts = [NSMutableDictionary dictionary];
		[atts setValue:[show valueForKey:@"title"] forKey:@"title"];
		[element setAttributesAsDictionary:atts];
		
		NSEnumerator * showIter = [[show valueForKey:@"children"] objectEnumerator];
		NSDictionary * child = nil;
		while (child = [showIter nextObject])
			[element addChild:[self elementForRecording:child]];
		
		return element;
	}
	else 
	{
		NSXMLElement * element = [NSXMLElement elementWithName:@"recording"];
		
		NSMutableDictionary * atts = [NSMutableDictionary dictionary];
		[atts setValue:[show valueForKey:@"title"] forKey:@"title"];
		[atts setValue:[show valueForKey:@"episode"] forKey:@"episode"];
		[atts setValue:[show valueForKey:@"episode_number"] forKey:@"episode_number"];
		[atts setValue:[show valueForKey:@"high_definition"] forKey:@"high_definition"];
		[atts setValue:[show valueForKey:@"synopsis"] forKey:@"synopsis"];
		[atts setValue:[show valueForKey:@"rating"] forKey:@"rating"];
		[atts setValue:[show valueForKey:@"station"] forKey:@"station"];
		[atts setValue:[[show valueForKey:@"recorded"] description] forKey:@"recorded"];

		[atts setValue:[[show valueForKey:@"duration"] description] forKey:@"duration"];

		[element setAttributesAsDictionary:atts];

		return element;
	}
}

- (void) transmitRecordings:(NSArray *) recordings forTivo:(Tivo *) tivo
{
	if (![tivo isKindOfClass:[Tivo class]])
		return;
	
	NSEnumerator * jidIter = [clientJids objectEnumerator];
	NSString * jid = nil;
	while (jid = [jidIter nextObject])
	{
		NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
		
		[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"set", @"type", [[[client myUser] jid] bare], @"from", jid, @"to", nil]];
		[iq addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:recording-list"]];
		
		NSXMLElement * recordingsElement = [NSXMLElement elementWithName:@"recordings"];
		[recordingsElement setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[tivo identifier] forKey:@"recorder"]];

		NSEnumerator * showIter = [recordings objectEnumerator];
		NSDictionary * show = nil;
		while (show = [showIter nextObject])
		{
			[recordingsElement addChild:[self elementForRecording:show]];
		}
		
		[iq addChild:recordingsElement];
		[client sendElement:iq];
	}
}

@end
