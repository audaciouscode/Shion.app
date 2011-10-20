//
//  NotificationManager.m
//  Shion
//
//  Created by Chris Karr on 1/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NotificationManager.h"
#import "XMPPManager.h"

@implementation NotificationManager

static NotificationManager * sharedInstance = nil;

+ (NotificationManager *) sharedInstance
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
		[GrowlApplicationBridge setGrowlDelegate:self];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(post:) name:NOTIFICATION_MSG object:nil];
	}

	return self;
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	NSMutableDictionary * growlDict = [NSMutableDictionary dictionary];
	
	NSMutableArray * notes = [NSMutableArray array];
	[notes addObject:FETCHING_STATUS];	
	[notes addObject:DEVICE_STATE_CHANGED];	
	[notes addObject:SCHEDULED_ITEM];	
	[notes addObject:REMOTE_STATUS];	
	[notes addObject:ONLINE_STATUS];	
	[notes addObject:EVENT_NOTE];	
	[notes addObject:X10_NOTE];	
	[notes addObject:HARDWARE_NOTE];	
	[notes addObject:REMOTE_CLIENT_NOTE];	
	[notes addObject:XMPP_COMMAND];	
	[notes addObject:MOTION_STATUS];	
	[notes addObject:INCOMING_PHONE_CALL];	
	
	[growlDict setValue:notes forKey:GROWL_NOTIFICATIONS_ALL];
	[growlDict setValue:notes forKey:GROWL_NOTIFICATIONS_DEFAULT];
	
	return growlDict;
}

- (void) showMessage:(NSString *) message title:(NSString *) title icon:(NSImage *) icon type:(NSString *) type
{
	NSData * iconData = nil;
	
	if (icon != nil)
	{
		iconData = [icon TIFFRepresentation];
	}

	[GrowlApplicationBridge notifyWithTitle:title
								description:message
						   notificationName:type
								   iconData:iconData
								   priority:0
								   isSticky:NO
							   clickContext:nil];

	[[XMPPManager sharedInstance] updateStatus:message available:YES];
}

@end
