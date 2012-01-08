//
//  MobileClient.m
//  Shion
//
//  Created by Chris Karr on 8/16/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "NSDictionary+BSJSONAdditions.h"
#import "NSScanner+BSJSONAdditions.h"

#import "MobileClient.h"
#import "ConsoleManager.h"
#import "XMPPManager.h"
#import "EventManager.h"

@implementation MobileClient

+ (MobileClient *) mobileClient;
{
	return [MobileClient dictionary];
}

- (NSString *) type
{
	return @"Mobile Device";
}

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Mobile Device" forKey:TYPE];
		[self setValue:@"Other" forKey:LOCATION];
		
		statusTimer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(expireStatus:) userInfo:nil repeats:YES] retain];
		lastStatus = [[NSDate distantPast] retain];
		connectedDate = nil;
		
		lastFetch = [[NSDate distantPast] retain];
	}
	
	return self;
}

- (void) expireStatus:(NSTimer *) theTimer
{
	[self willChangeValueForKey:@"mobile_duration"];
	
	if ([lastStatus timeIntervalSinceNow] < -120)
	{
		[self setStatus:@"Offline"];
//		[self setLatitude:nil longitude:nil];
//		[self setLocationError:nil];
	}
	
	[self didChangeValueForKey:@"mobile_duration"];
}

- (void) setLatitude:(NSNumber *) latitude longitude:(NSNumber *) longitude
{
	[self willChangeValueForKey:LAST_UPDATE];
	
	[self willChangeValueForKey:@"mobile_location"];
	[self willChangeValueForKey:@"mobile_map_url"];
	
	if (latitude == nil)
		[self removeObjectForKey:@"mobile_latitude"];
	else
		[self setValue:latitude forKey:@"mobile_latitude"];
	
	if (latitude == nil)
		[self removeObjectForKey:@"mobile_longitude"];
	else
		[self setValue:longitude forKey:@"mobile_longitude"];

	NSDate * now = [NSDate date];

	if (latitude != nil && longitude != nil) //  && [now timeIntervalSinceDate:lastFetch] > 60)
	{
		NSMutableDictionary * eventDict = [NSMutableDictionary dictionary];
		[eventDict setValue:[NSString stringWithFormat:@"%.4f", [latitude doubleValue]] forKey:@"latitude"];
		[eventDict setValue:[NSString stringWithFormat:@"%.4f", [longitude doubleValue]] forKey:@"longitude"];
		
		NSString * locationString = [NSString stringWithFormat:@"%@,%@", latitude, longitude];
		
		[[EventManager sharedInstance] createEvent:@"location" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"%@ is located at %@.", [self name], locationString]
											 value:[eventDict jsonStringValue]];
		[lastFetch release];
	
		lastFetch = [now retain];
	}		
	
	[self didChangeValueForKey:@"mobile_map_url"];
	[self didChangeValueForKey:@"mobile_location"];
	
	[self didChangeValueForKey:LAST_UPDATE];
}

- (void) setStatus:(NSString *) status
{
	[lastStatus release];
	
	lastStatus = [[NSDate date] retain];
	
	[self willChangeValueForKey:LAST_UPDATE];
	
	NSString * oldStatus = [self valueForKey:@"mobile_status"];
	
	if (oldStatus == nil)
		oldStatus = @"";
	
	if ([status isEqual:oldStatus])
	{

	}
	else
	{
		[self willChangeValueForKey:@"mobile_status"];
		[self willChangeValueForKey:@"mobile_status_icon"];
		[self willChangeValueForKey:@"mobile_can_beacon"];
		[self willChangeValueForKey:@"mobile_duration"];

		NSDictionary * eventDict = [NSDictionary dictionaryWithObject:status forKey:@"status"];
		
		if (![status isEqual:@"Offline"])
		{
			if (connectedDate == nil)
				connectedDate = [[NSDate date] retain];
			
			if ([status isEqual:@"Private"])
			{
				[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
											   description:[NSString stringWithFormat:@"%@ switched to private mode.", [self name]]
													 value:[eventDict jsonStringValue]];
			}
			else
			{
				[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
											   description:[NSString stringWithFormat:@"%@ switched to location-reporting mode.", [self name]]
													 value:[eventDict jsonStringValue]];
			}
		}
		else if ([status isEqual:@"Offline"])
		{
			if (connectedDate != nil)
			{
				[connectedDate release];
				connectedDate = nil;
			}
			
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
										   description:[NSString stringWithFormat:@"%@ went offline.", [self name]]
												 value:[eventDict jsonStringValue]];
		}
		
		[self setValue:status forKey:@"mobile_status"];
		
		[self didChangeValueForKey:@"mobile_duration"];
		[self didChangeValueForKey:@"mobile_can_beacon"];
		[self didChangeValueForKey:@"mobile_status_icon"];
		[self didChangeValueForKey:@"mobile_status"];
	}
	
	[self didChangeValueForKey:LAST_UPDATE];
}

- (void) setLastCaller:(NSString *) lastCaller
{
	[self willChangeValueForKey:LAST_UPDATE];
	
	[self willChangeValueForKey:@"mobile_caller"];
	
	[self setValue:lastCaller forKey:@"mobile_caller"];
	
	if (![lastCaller isEqual:@"Restricted"])
	{
		NSDictionary * eventDict = [NSDictionary dictionaryWithObject:lastCaller forKey:@"caller"];

		[[EventManager sharedInstance] createEvent:@"last-caller" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"%@ was called by %@.", [self name], lastCaller]
											 value:[eventDict jsonStringValue]];
	}
	
	[self didChangeValueForKey:@"mobile_caller"];
	
	[self didChangeValueForKey:LAST_UPDATE];
}

- (void) setLocationError:(NSString *) error
{
	[self willChangeValueForKey:LAST_UPDATE];
	
	[self willChangeValueForKey:@"mobile_location"];
	[self willChangeValueForKey:@"mobile_map_url"];
	
	if (error != nil)
	{
		[[EventManager sharedInstance] createEvent:@"error" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"%@ encountered an error: %@.", [self name], error]
											 value:@"65535"];
	}
	
	if (error == nil)
		[self removeObjectForKey:@"mobile_error"];
	else
		[self setValue:error forKey:@"mobile_error"];
	
	[self didChangeValueForKey:@"mobile_map_url"];
	[self didChangeValueForKey:@"mobile_location"];
	
	[self didChangeValueForKey:LAST_UPDATE];
}

- (id) valueForKey:(NSString *) key
{
	if ([key isEqual:@"mobile_location"])
	{
		NSString * error = [self valueForKey:@"mobile_error"];
		
		NSString * lat = [self valueForKey:@"mobile_latitude"];
		NSString * lon = [self valueForKey:@"mobile_longitude"];
		
		if (error != nil)
			return error;
		else if (lat != nil && lon != nil)
			return [NSString stringWithFormat:@"%@, %@", lat, lon, nil];
		
		return @"Waiting...";
	}
	else if ([key isEqual:@"mobile_duration"])
	{
		if (connectedDate == nil)
			return @"Not Connected";
		else
		{
			float seconds = 0 - [connectedDate timeIntervalSinceNow];
			
			if (seconds < 60)
				return @"Less than a minute";
			else if (seconds < 120)
				return [NSString stringWithFormat:@"%d seconds", (int) seconds, nil];
			
			return [NSString stringWithFormat:@"%d minutes", (int) (seconds / 60), nil];
		}
		
		return @"Unknown";
	}
	else if ([key isEqual:@"mobile_status_icon"])
	{
		if ([[self valueForKey:@"mobile_status"] isEqual:@"Online"])
			return [NSImage imageNamed:@"mobile-device-online"];
		else if ([[self valueForKey:@"mobile_status"] isEqual:@"Private"])
			return [NSImage imageNamed:@"mobile-device-private"];
		
		return [NSImage imageNamed:@"mobile-device-offline"];
	}
	else if ([key isEqual:@"mobile_can_beacon"])
	{
		if ([[self valueForKey:@"mobile_status"] isEqual:@"Online"])
			return [NSNumber numberWithBool:YES];
		else if ([[self valueForKey:@"mobile_status"] isEqual:@"Private"])
			return [NSNumber numberWithBool:YES];
		
		return [NSNumber numberWithBool:NO];
	}
	else if ([key isEqual:@"mobile_map_url"])
	{
		NSString * lat = [self valueForKey:@"mobile_latitude"];
		NSString * lon = [self valueForKey:@"mobile_longitude"];
		
		if (lat != nil && lon != nil)
		{
			// http://maps.google.com/maps/api/staticmap?center=Brooklyn+Bridge,New+York,NY&zoom=14&size=512x512&maptype=roadmap
			// &markers=color:blue|label:S|40.702147,-74.015794&markers=color:green|label:G|40.711614,-74.012318
			// &markers=color:red|color:red|label:C|40.718217,-73.998284&sensor=false
			
			NSSize mapSize = [[ConsoleManager sharedInstance] mapSize];
			
			//			NSString * urlString = [NSString stringWithFormat:@"http://maps.google.com/maps/api/staticmap?center=%@,%@&zoom=14&size=%dx%d&maptype=hybrid&markers=color:blue|label:P|%@,%@&sensor=true",
			//					lat, lon, (int) mapSize.width, (int) mapSize.height, lat, lon, nil];
			
			
			NSString * urlString = [NSString stringWithFormat:@"http://dev.openstreetmap.de/staticmap/staticmap.php?center=%@,%@&zoom=14&size=%dx%d&markers=%@,%@,red-pushpin&maptype=mapnik",
									lat, lon, (int) mapSize.width, (int) mapSize.height, lat, lon, nil];
			
			//			NSString * urlString = [NSString stringWithFormat:@"http://dev.openstreetmap.de/staticmap/staticmap.php?center=%@,%@&zoom=14&size=%dx%d&markers=%@,%@,red-pushpin&maptype=mapnik",
			//									lat, lon, 1024, 1024, lat, lon, nil];
			
 			NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
			
			return data;
		}
		
		return nil;
	}
	
	return [super valueForKey:key];
}

- (void) beacon
{
	[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
								   description:[NSString stringWithFormat:@"The beacon of %@ was activated.", [self name]]
										 value:@"65535"];
	
	[[XMPPManager sharedInstance] beaconDevice:self];
}

@end
