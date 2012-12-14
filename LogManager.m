//
//  LogManager.m
//  Shion
//
//  Created by Chris Karr on 2/9/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "LogManager.h"
#import "ASDeviceController.h"

#define ENABLE_LOGGING @"enable_logging"

#define ENABLE_LOCAL @"log_local_commands"
#define ENABLE_NETWORK @"log_network_commands"
#define ENABLE_ASSOCIATED @"log_events_with_actions"
#define ENABLE_UNASSOCIATED @"log_events_without_actions"
#define ENABLE_X10 @"log_xten_events"
#define ENABLE_EXTERNAL_EVENTS @"log_external_events"
#define ENABLE_DEVICE_TRAFFIC @"log_device_traffic"

@implementation LogManager

static LogManager * sharedInstance = nil;

- (id) init
{
	if (self = [super init])
	{
		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
		pendingEvents = [[NSMutableArray alloc] init];
		
		logTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(writeEvents:) userInfo:nil repeats:YES] retain];
	}

	return self;
}

+ (LogManager *) sharedInstance
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            [[self alloc] init]; // assignment not done here

			[[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(log:) name:LOG_NOTIFICATION object:nil];
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

- (NSString *) analyticsFolder
{
	NSFileManager * fileManager = [NSFileManager defaultManager];

	NSArray * desktops = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
	
	NSMutableString * analyticsFolder = [NSMutableString stringWithString:[desktops lastObject]];
	[analyticsFolder appendFormat:@"/Shion Log"];
	
	BOOL isDir = NO;
	if (![fileManager fileExistsAtPath:analyticsFolder isDirectory:&isDir] || !isDir)
	{
		[fileManager removeFileAtPath:analyticsFolder handler:nil];
		[fileManager createDirectoryAtPath:analyticsFolder attributes:nil];
	}
	
	return analyticsFolder;
}

- (void) write:(NSDictionary *) theEvent
{
	@synchronized(pendingEvents)
	{
		[pendingEvents addObject:theEvent];
	}
}

- (void) writeEvents:(NSTimer *) theTimer
{
	if ([pendingEvents count] == 0)
		return;
	
	NSDictionary * theEvent = [pendingEvents objectAtIndex:0];
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	
	NSDate * now = [NSDate date];
	
	NSFileManager * fileManager = [NSFileManager defaultManager];
	
	NSMutableString * analyticsFolder = [NSMutableString stringWithString:[self analyticsFolder]];
	
	BOOL isDir = NO;
	[formatter setDateFormat:@"yyyy"];
	[analyticsFolder appendFormat:@"/%@", [formatter stringFromDate:now]];
	
	if (![fileManager fileExistsAtPath:analyticsFolder isDirectory:&isDir] || !isDir)
	{
		[fileManager removeFileAtPath:analyticsFolder handler:nil];
		[fileManager createDirectoryAtPath:analyticsFolder attributes:nil];
	}
	
	isDir = NO;
	[formatter setDateFormat:@"MM"];
	[analyticsFolder appendFormat:@"/%@", [formatter stringFromDate:now]];
	
	if (![fileManager fileExistsAtPath:analyticsFolder isDirectory:&isDir] || !isDir)
	{
		[fileManager removeFileAtPath:analyticsFolder handler:nil];
		[fileManager createDirectoryAtPath:analyticsFolder attributes:nil];
	}
	
	isDir = NO;
	[formatter setDateFormat:@"dd"];
	[analyticsFolder appendFormat:@"/%@", [formatter stringFromDate:now]];
	
	if (![fileManager fileExistsAtPath:analyticsFolder isDirectory:&isDir] || !isDir)
	{
		[fileManager removeFileAtPath:analyticsFolder handler:nil];
		[fileManager createDirectoryAtPath:analyticsFolder attributes:nil];
	}
	
	[formatter setDateFormat:@"HH"];
	
	NSString * logFile = [analyticsFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", [formatter stringFromDate:now]]];
	
	[formatter setDateFormat:@"HH:mm.ss"];
	
	NSMutableString * logString = [NSMutableString string];
	
	if ([theEvent valueForKey:LOG_DESCRIPTION] != nil)
	{
		[logString appendFormat:@"%@: [%@] %@\n", [formatter stringFromDate:now], [theEvent valueForKey:LOG_TYPE], [theEvent valueForKey:LOG_DESCRIPTION]];
		
		if (![fileManager fileExistsAtPath:logFile isDirectory:&isDir])
			[[NSData data] writeToFile:logFile atomically:YES];
		
		NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:logFile];
		[handle seekToEndOfFile];
		
		[handle writeData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
		
		[handle closeFile];
	}
	
	[formatter release];
	
	[pendingEvents removeObjectAtIndex:0];
}

- (void) log:(NSNotification *) theNote
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:ENABLE_LOGGING])
	{
		NSDictionary * dict = [theNote userInfo];
		
		NSString * type = [dict valueForKey:LOG_TYPE];

		if (([type isEqual:LOG_LOCAL_COMMAND] && [defaults boolForKey:ENABLE_LOCAL]) ||
			([type isEqual:LOG_NETWORK_COMMAND] && [defaults boolForKey:ENABLE_NETWORK]) ||
			([type isEqual:LOG_EVENT_ASSOCIATED] && [defaults boolForKey:ENABLE_ASSOCIATED]) ||
			([type isEqual:LOG_EVENT_UNASSOCIATED] && [defaults boolForKey:ENABLE_UNASSOCIATED]) ||
			([type isEqual:LOG_EXTERNAL_X10] && [defaults boolForKey:ENABLE_X10]) ||
			([type isEqual:LOG_EXTERNAL_EVENTS] && [defaults boolForKey:ENABLE_EXTERNAL_EVENTS]) ||
			([type isEqual:LOG_DEVICE_TRAFFIC] && [defaults boolForKey:ENABLE_DEVICE_TRAFFIC]))
		{
			[self write:dict];
		}
	}
}

@end
