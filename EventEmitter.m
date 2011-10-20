//
//  EventEmitter.m
//  Shion
//
//  Created by Chris Karr on 1/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EventEmitter.h"
#import "LogManager.h"

#import <Shion/ASDeviceController.h>

#import "NotificationManager.h"

@implementation EventEmitter

- (float) fractionalYearWithDayOffset:(float) offset
{
	NSCalendarDate * now = [NSCalendarDate date];
	
	return ((2 * M_PI) / 365) * (((float) [now dayOfYear]) + offset - 1 + ((((float) [now hourOfDay]) - 12) / 24));
}

- (float) eqTimeWithDayOffset:(float) offset
{
	float fractYear = [self fractionalYearWithDayOffset:offset];
	
	float et = 229.18 * (0.000075 + (0.001868 * cos (fractYear)) - (0.032077 * sin (fractYear)) - 
						   (0.014615 * cos (2 * fractYear)) - (0.040849 * sin (2 * fractYear)));
	
	return et;
}

- (float) solarDeclinationWithDayOffset:(float) offset
{
	float fractYear = [self fractionalYearWithDayOffset:offset];
	
	float decl = 0.006918 - (0.399912 * cos (fractYear)) + (0.070257 * sin (fractYear)) - (0.006758 * cos (2 * fractYear)) +
	(0.000907 * sin (2 * fractYear)) - (0.002697 * cos (3 * fractYear)) + (0.00148 * sin (3 * fractYear));
	
	return decl;
}

- (float) radiansForDegrees:(float) degrees
{
	return (M_PI / 180.0) * degrees;
}

- (float) degreesForRadians:(float) rads
{
	return (180 / M_PI) * rads;
}

- (float) hourAngleForLatitude:(float) lat longitude:(float) lon dayOffset:(float) offset
{
	float decl = [self solarDeclinationWithDayOffset:offset];
	
	float ha =  acos ((cos ([self radiansForDegrees:90.833]) / (cos ([self radiansForDegrees:lat]) * cos (decl))) - 
						(tan ([self radiansForDegrees:lat]) * tan (decl)));
	
	return ha;
}

- (float) sunriseForLatitude:(float) lat longitude:(float) lon dayOffset:(float) offset
{
	return 720 + (4 * (lon - [self degreesForRadians:[self hourAngleForLatitude:lat longitude:lon dayOffset:offset]])) - [self eqTimeWithDayOffset:offset];
}

- (float) sunsetForLatitude:(float) lat longitude:(float) lon dayOffset:(float) offset
{
	return 720 + (4 * (lon + [self degreesForRadians:[self hourAngleForLatitude:lat longitude:lon dayOffset:offset]])) - [self eqTimeWithDayOffset:offset];
}

- (float) solarNoonForLatitude:(float) lat longitude:(float) lon dayOffset:(float) offset
{
	return 720 + (4 * lon) - [self eqTimeWithDayOffset:offset];
}

- (NSDictionary *) getSolarEvents
{
	NSMutableDictionary * solarEvents = [NSMutableDictionary dictionary];

	ReadLocation (location);
	
	NSTimeZone * myTimeZone = [NSTimeZone localTimeZone];
	
	float latitude = 90 * FractToFloat (location->latitude);
	float longitude = -90 * FractToFloat (location->longitude);

	NSCalendarDate * now = [NSCalendarDate date];
	unsigned int nowMinutes = ([now hourOfDay] * 60) + [now minuteOfHour];

	float utcSunrise = [self sunriseForLatitude:latitude longitude:longitude dayOffset:0] + ([myTimeZone secondsFromGMT] / 60);
	float sunriseDiff = nowMinutes - utcSunrise;
	[solarEvents setValue:[NSNumber numberWithFloat:sunriseDiff] forKey:SUNRISE_DIFF];
		
	float utcSunset = [self sunsetForLatitude:latitude longitude:longitude dayOffset:0]  + ([myTimeZone secondsFromGMT] / 60);
	float sunsetDiff = nowMinutes - utcSunset;
	[solarEvents setValue:[NSNumber numberWithFloat:sunsetDiff] forKey:SUNSET_DIFF];
	
	return solarEvents;
}

- (BOOL) isDay
{
	ReadLocation (location);
	
	NSTimeZone * myTimeZone = [NSTimeZone localTimeZone];
	
	float latitude = 90 * FractToFloat (location->latitude);
	float longitude = -90 * FractToFloat (location->longitude);
	
	float utcSunrise = [self sunriseForLatitude:latitude longitude:longitude dayOffset:0] + ([myTimeZone secondsFromGMT] / 60);
	float utcSunset = [self sunsetForLatitude:latitude longitude:longitude dayOffset:0]  + ([myTimeZone secondsFromGMT] / 60);
	
	NSCalendarDate * now = [NSCalendarDate date];
	unsigned int nowMinutes = ([now hourOfDay] * 60) + [now minuteOfHour];
	
	if (nowMinutes > utcSunrise && nowMinutes < utcSunset)
		return true;
	else
		return false;
}

- (void) awakeFromNib
{
	heartbeat = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(beat:) userInfo:nil repeats:YES] retain];
	[heartbeat fire];
	
	location = malloc (sizeof (MachineLocation));
	sunTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(sunrise:) userInfo:nil repeats:YES] retain];
	[sunTimer fire];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xten:) name:X10_COMMAND_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hardware:) name:HARDWARE_ERROR object:nil];
}

- (void) xten:(NSNotification *) theNote
{
	[self emitEvent:X10_EVENT value:[theNote userInfo]];
}

- (void) sunrise:(NSTimer *) theTimer
{
	[self emitEvent:SOLAR_EVENT value:[self getSolarEvents]];
}

- (void) beat:(NSTimer *) theTimer
{
	[self emitEvent:TIME_EVENT value:[NSDate date]];
}

- (void) emitEvent:(NSString *) kind value:(id) value
{
	NSDate * now = [NSDate date];
	
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];

	[formatter setDateStyle:NSDateFormatterMediumStyle];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	
	[userInfo setValue:kind forKey:EVENT_KIND];
	
	if (value != nil)
		[userInfo setValue:value forKey:EVENT_VALUE];
	
	if ([kind isEqual:SOLAR_EVENT])
	{
		float sunsetDiff = [[value valueForKey:SUNSET_DIFF] floatValue];
		float sunriseDiff = [[value valueForKey:SUNRISE_DIFF] floatValue];
		
		if (sunsetDiff >= 0 && sunsetDiff < 1)
		{
			NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
			[userInfo setValue:NSLocalizedString(@"Sunset", nil) forKey:NOTIFICATION_TITLE];
			[userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"The sun set at %@.", nil), [formatter stringFromDate:now]] forKey:NOTIFICATION_MESSAGE];
			[userInfo setValue:EVENT_NOTE forKey:NOTIFICATION_TYPE];
		
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];
		}
		
		if (sunriseDiff >= 0 && sunriseDiff < 1)
		{
			NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
			[userInfo setValue:NSLocalizedString(@"Sunrise", nil) forKey:NOTIFICATION_TITLE];
			[userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"The sun rose at %@.", nil), [formatter stringFromDate:now]] forKey:NOTIFICATION_MESSAGE];
			[userInfo setValue:EVENT_NOTE forKey:NOTIFICATION_TYPE];
		
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];
		}
	}
	else if ([kind isEqual:X10_EVENT])
	{
		NSDictionary * dict = (NSDictionary *) value;
		
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setValue:NSLocalizedString(@"X10 Event", nil) forKey:NOTIFICATION_TITLE];

		NSString * message = nil;
		
		NSArray * addresses = [NSArray arrayWithObject:[dict valueForKey:X10_ADDRESS]]; // TODO: Fix - not array any more
		
		if ([addresses count] == 0)
			message = [NSString stringWithFormat:NSLocalizedString(@"Received '%@' command.", nil), [dict valueForKey:X10_COMMAND], nil];
		else
		{
			message = [NSString stringWithFormat:NSLocalizedString(@"Received '%@' command for unit '%@'.", nil), [dict valueForKey:X10_COMMAND],
					   [addresses lastObject], nil];
		}
		
		NSMutableDictionary * logDict = [NSMutableDictionary dictionary];
		[logDict setValue:LOG_EXTERNAL_X10 forKey:LOG_TYPE];
		[logDict setValue:message forKey:LOG_DESCRIPTION];
		[[NSNotificationCenter defaultCenter] postNotificationName:LOG_NOTIFICATION object:nil userInfo:logDict];
		
		[userInfo setValue:message forKey:NOTIFICATION_MESSAGE];
		[userInfo setValue:X10_NOTE forKey:NOTIFICATION_TYPE];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];
	}
	else if ([kind isEqual:HARDWARE_EVENT])
	{
		if ([[devices arrangedObjects] count] > 0)
		{
			NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
			[userInfo setValue:NSLocalizedString(@"Hardware Error Event", nil) forKey:NOTIFICATION_TITLE];
		
			NSString * message = [value description];
		
			[userInfo setValue:message forKey:NOTIFICATION_MESSAGE];
			[userInfo setValue:HARDWARE_NOTE forKey:NOTIFICATION_TYPE];
		
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_MSG object:nil userInfo:userInfo];

			[NSApp activateIgnoringOtherApps:YES];
			[shionWindow makeKeyAndOrderFront:nil];
			
			NSTimer * errorTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(hardwareAlert:) userInfo:userInfo repeats:NO];
			[errorTimer retain];
		}
	}
	
	[formatter release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EVENT_EMITTED object:nil userInfo:userInfo];
}

-(void) hardwareAlert:(NSTimer *) theTimer
{
	NSString * message = [[theTimer userInfo] valueForKey:NOTIFICATION_MESSAGE];
	
	if (NSAlertAlternateReturn == NSRunAlertPanel(@"Hardware Error Encountered", [NSString stringWithFormat:@"%@ Please resolve the issue and restart Shion.",
																				  message, nil], @"OK", @"Help", nil))
	{
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"ShionTroubleshootingPage"]]];
	}
	
	[theTimer release];
}

- (void) dealloc
{
	[heartbeat invalidate];
	[sunTimer invalidate];
	
	[super dealloc];
}

- (void) hardware:(NSNotification *) theNote
{
	[self emitEvent:HARDWARE_EVENT value:[[theNote userInfo] valueForKey:HARDWARE_ERROR_MSG]];
}


@end
