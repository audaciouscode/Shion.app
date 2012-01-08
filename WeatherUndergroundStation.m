//
//  WeatherUndergroundStation.m
//  Shion
//
//  Created by Chris Karr on 7/30/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "WeatherUndergroundStation.h"

#import "EventManager.h"

#define OBSERVATION_DATE @"observation_date"
#define WEATHER_STRING @"weather_string"
#define TEMPERATURE @"temperature"
#define HUMIDITY @"humidity"
#define WIND @"wind"
#define WIND_DIRECTION @"wind_direction"
#define WIND_SPEED @"wind_speed"
#define BAROMETRIC_PRESSURE @"barometric_pressure"
#define DEW_POINT @"dew_point"
#define HEAT_INDEX @"heat_index"
#define WIND_CHILL @"wind_chill"
#define VISIBILTY @"visibility"
#define CREDIT @"credit"
#define STATION_ID @"station_id"

#import <Shion/ASThermostatDevice.h>

#import "TriggerManager.h"

@implementation WeatherUndergroundStation

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Weather Station" forKey:TYPE];
		[self setValue:WU_STATION forKey:MODEL];
		
		useAlternative = NO;
		
		buffer = [[NSMutableData alloc] init];
		[[NSTimer scheduledTimerWithTimeInterval:900.0 target:self selector:@selector(updateReading:) userInfo:nil repeats:YES] retain];
	}
	
	return self;
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	if ([key isEqual:TEMPERATURE] && [[value description] isEqual:@"0"])
		return;
	
	[self willChangeValueForKey:key];

	if (value == nil)
		[self removeObjectForKey:key];
	else
		[super setValue:value forKey:key];

	[self didChangeValueForKey:key];
}

- (BOOL) checksStatus
{
	return YES;
}

- (void) updateReading:(NSTimer *) theTimer
{
	[self fetchStatus];
}

- (void) fetchStatus
{
	[self setValue:[NSDate date] forKey:LAST_CHECK];
	//	[self removeObjectForKey:LAST_RESPONSE];
	
	// http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=KORD
	
	NSURLRequest * request = nil;
	
	if (!useAlternative)
	{
		request = [NSURLRequest requestWithURL:
				   [NSURL URLWithString:[NSString stringWithFormat:@"http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml?query=%@", 
										 [[self address] uppercaseString]]]];
	}
	else
	{
		request = [NSURLRequest requestWithURL:
					[NSURL URLWithString:[NSString stringWithFormat:@"http://api.wunderground.com/weatherstation/WXCurrentObXML.asp?ID=%@", 
										  [[self address] uppercaseString]]]];
	}

	[buffer setData:[NSData data]];
	[[NSURLConnection connectionWithRequest:request delegate:self] retain];
		
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (!useAlternative)
	{
		useAlternative = YES;
		
		[self fetchStatus];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[buffer appendData:data];
}

- (BOOL) canReset
{
	return NO;
}

- (NSNumber *) temperature
{
	return [self valueForKey:TEMPERATURE];
}
 
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[connection release];
	
	NSXMLDocument * document = [[NSXMLDocument alloc] initWithData:buffer options:NSXMLDocumentTidyXML error:NULL];
	
	if (document)
	{
		NSXMLElement * container = [document rootElement];
		
		NSDictionary * dateFields = [NSDictionary dictionaryWithObjectsAndKeys:OBSERVATION_DATE, @"observation_time_rfc822", nil];

		NSDictionary * stringFields = [NSDictionary dictionaryWithObjectsAndKeys:WEATHER_STRING, @"weather", WIND, @"wind_string", CREDIT, @"credit", 
									   STATION_ID, @"station_id", nil];

		NSDictionary * numberFields = [NSDictionary dictionaryWithObjectsAndKeys:TEMPERATURE, @"temp_f", HUMIDITY, @"relative_humidity",
									   WIND_SPEED, @"wind_mph", BAROMETRIC_PRESSURE, @"pressure_mb", DEW_POINT, @"dewpoint_f", 
									   HEAT_INDEX, @"heat_index_f", WIND_CHILL, @"windchill_f", VISIBILTY, @"visibility_mi", nil];

		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss z"];
		
		NSString * key = nil;
		NSEnumerator * iter = [dateFields keyEnumerator];
		while (key = [iter nextObject])
		{
			NSXMLElement * element = [[container elementsForName:key] lastObject];
			
			NSDate * date = [formatter dateFromString:[element stringValue]];
			
			[self setValue:date forKey:[dateFields valueForKey:key]];
		}

		iter = [stringFields keyEnumerator];
		while (key = [iter nextObject])
		{
			NSXMLElement * element = [[container elementsForName:key] lastObject];
			
			[self setValue:[element stringValue] forKey:[stringFields valueForKey:key]];
		}
		
		if ([self valueForKey:@"station_id"] == nil || [[self valueForKey:@"station_id"] isEqual:@""])
		{
			useAlternative = YES;
			
			[self fetchStatus];
		}
		else 
		{
			iter = [numberFields keyEnumerator];
			while (key = [iter nextObject])
			{
				NSXMLElement * element = [[container elementsForName:key] lastObject];
				
				NSNumber * number = [NSNumber numberWithFloat:[[element stringValue] floatValue]];
				
				[self setValue:number forKey:[numberFields valueForKey:key]];
				
				if ([key isEqual:@"temp_f"])
				{
					NSManagedObject * lastEvent = [[EventManager sharedInstance] lastUpdateForIdentifier:[self identifier] event:@"device"];
					
					if (lastEvent == nil || [[lastEvent valueForKey:@"value"] floatValue] != [number floatValue])
					{
						NSString * message = [NSString stringWithFormat:@"Current temperature is %@°.", number];
						
						[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
													   description:message value:[number description]];
					}
					
					NSMutableDictionary * theNote = [NSMutableDictionary dictionary];
					
					[theNote setValue:[self address] forKey:DEVICE_ADDRESS];
					[theNote setValue:number forKey:THERMOSTAT_TEMPERATURE];
					[theNote setValue:[NSNumber numberWithBool:NO] forKey:IS_INDOORS];
					
					[[TriggerManager sharedInstance] deviceUpdate:[NSNotification notificationWithName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:theNote]];
				}
			}
			
			[self recordResponse];
		}
		
		[document release];
	}
	
	[buffer setData:[NSData data]];
}

@end
 