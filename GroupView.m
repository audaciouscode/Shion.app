//
//  GroupView.m
//  Shion
//
//  Created by Chris Karr on 4/12/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "GroupView.h"
#import "Device.h"
#import "Snapshot.h"
#import "Trigger.h"

#import "EventManager.h"

#import "Controller.h"
#import "Thermostat.h"
#import "PowerMeterSensor.h"
#import "Camera.h"
#import "Phone.h"
#import "MobileClient.h"
#import "WeatherUndergroundStation.h"

#import "ConsoleManager.h"

#import "NSBezierPathRoundRects.h"

@implementation GroupView


- (void) drawChartForFavoriteDevices:(NSArray *) devices snapshots:(NSArray *) snapshots triggers:(NSArray *) triggers drawn:(unsigned int *) count;
{
	[self resetCursorRects];
	
	NSEnumerator * rectIter = [deviceAreas objectEnumerator];
	NSDictionary * dict = nil;
	while (dict = [rectIter nextObject])
	{
		int area = [[dict valueForKey:@"area_tag"] intValue];
		[self removeTrackingRect:area];
	}
	
	[deviceAreas removeAllObjects];
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	
	devices = [devices sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sort, nil]];
	
	float minWidth = 200;
	
 	NSRect bounds = [self bounds];
	
	bounds.size.width -= 20;
	bounds.size.height -= 70;
	bounds.origin.x += 10;
	bounds.origin.y += 10;
	
	float daySeconds = 24 * 60 * 60;
	
	NSDate * today = [NSDate dateWithNaturalLanguageString:@"12:00:00 am"];
	
	NSTimeInterval latestInterval = floor([today timeIntervalSince1970]) + daySeconds;
	NSTimeInterval startInterval = latestInterval - (daySeconds * 2);
	
	*count = 0;
	
	unsigned int allCount = ([devices count] + [snapshots count] + [triggers count]);
	
	unsigned int rows = bounds.size.height / 50; // Charts are 50px high at the moment.
	unsigned int columns = allCount / rows;
	
	bounds.size.height -= 40;
	
	if (allCount % rows != 0)
		columns += 1;
	
	while ((bounds.size.width + 10 < (minWidth + 10) * columns) && columns >= 1)
		columns -= 1;
	
	unsigned int currentColumn = 0;
	unsigned int currentRow = 0;
	
	float columnWidth = (bounds.size.width + 10) / columns;
	if (columns > 1)
		columnWidth -= 10;
	else
		columnWidth = bounds.size.width;
	
	NSEnumerator * deviceIter = [devices objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		float x = ceil(((columnWidth + 10) * currentColumn) + bounds.origin.x);
		
		float y = ceil(bounds.size.height - (50 * currentRow));
		
		NSRect timeRect = NSMakeRect(x, y + 20, columnWidth, 30);
		
		currentColumn += 1;
		if (currentColumn < columns)
		{
			
		}
		else
		{
			currentRow += 1;
			currentColumn = 0;
		}
		
		if (timeRect.origin.y - 20 > 0)
		{
			NSString * identifier = [device identifier];
			
			NSRect trackRect = NSMakeRect(timeRect.origin.x - 8, timeRect.origin.y - 8, timeRect.size.width + 15, timeRect.size.height + 5);
			
			NSMutableDictionary * mapDict = [NSMutableDictionary dictionary];
			[mapDict setValue:identifier forKey:@"identifier"];
			[mapDict setValue:[NSValue valueWithRect:trackRect] forKey:@"area"];
			
			NSTrackingRectTag tag = [self addTrackingRect:trackRect owner:self userData:identifier assumeInside:NO];
			
			[mapDict setValue:[NSNumber numberWithInt:tag] forKey:@"area_tag"];
			
			[deviceAreas addObject:mapDict];
			
			[self addCursorRect:trackRect cursor:[NSCursor pointingHandCursor]];
			
			BOOL highlight = NO;
			
			if (highlighted != nil && [identifier isEqual:highlighted])
			{
				[[NSColor darkGrayColor] setFill];
				
				[NSBezierPath fillRoundRectInRect:trackRect radius:5];
				
				highlight = YES;
			}
			
			if ([device isKindOfClass:[Controller class]])
				identifier = @"Controller";
			
			NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:identifier event:@"device"];
			
			NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
			
			Event * e = [Event eventWithType:@"device" source:@"" initiator:@"" description:@"" value:[NSNumber numberWithFloat:0]  date:[NSDate date]];
			[chartEvents addObject:e];
			
			NSString * cacheKey = [NSString stringWithFormat:@"%@-%f-%f", identifier, startInterval, latestInterval];
			
			PresenceTimeline * timeline = [timelineCache valueForKey:cacheKey];
			
			if (timeline == nil && [device isKindOfClass:[Thermostat class]])
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];
				
				float averageTemp = 0;
				int count = 0;
				
				
				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					if ([[event value] respondsToSelector:@selector(floatValue)])
					{
						float temp = [[event value] floatValue];
						
						averageTemp += temp;
						
						count += 1;
					}
				}
				
				averageTemp = averageTemp / count;
				
				float minTemp = 9999;
				float maxTemp = -9999;
				
				eventIter = [chartEvents objectEnumerator];
				event = nil;
				while ((event = [eventIter nextObject]))
				{
					float f = 0;
					
					if ([[event value] respondsToSelector:@selector(floatValue)])
						f = [[event value] floatValue];
					
					float temp = f;
					
					if (fabs(averageTemp - temp) < 20)
					{
						if (temp < minTemp)
							minTemp = temp;
						
						if (temp > maxTemp)
							maxTemp = temp;
					}
				}
				
				float diff = maxTemp - minTemp;
				
				eventIter = [chartEvents objectEnumerator];
				event = nil;
				while ((event = [eventIter nextObject]))
				{
					if ([[event date] timeIntervalSince1970] > startInterval)
					{
						float normalizedTemp = ([[event value] floatValue] - minTemp) / diff;
						
						if (normalizedTemp < 0)
							normalizedTemp = 0;
						
						if (normalizedTemp > 1)
							normalizedTemp = 1;
						
						[timeline setValue:(255 * normalizedTemp) atInterval:[[event date] timeIntervalSince1970]];
					}
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				[timeline release];
			}
			else if (timeline == nil && [device isKindOfClass:[PowerMeterSensor class]])
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];

				float minPower = 9999;
				float maxPower = -9999;
				
				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					float f = 0;
					
					if ([[event value] respondsToSelector:@selector(floatValue)])
						f = [[event value] floatValue];
					
					float power = f;
					
					if (power > 0 && power < 10000)
					{
						if (power < minPower)
							minPower = power;
						
						if (power > maxPower)
							maxPower = power;
					}
				}
				
				float diff = maxPower - minPower;
				
				eventIter = [chartEvents objectEnumerator];
				event = nil;
				while ((event = [eventIter nextObject]))
				{
					if ([[event date] timeIntervalSince1970] > startInterval)
					{
						float normalizedPower = ([[event value] floatValue] - minPower) / diff;
						
						if (normalizedPower < 0.0)
							normalizedPower = 0.0;
						else if (normalizedPower > 1.0)
							normalizedPower = 1.0;
						
						[timeline setValue:(255 * normalizedPower) atInterval:[[event date] timeIntervalSince1970]];
					}
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				[timeline release];
			}
			else if (timeline == nil)
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];
				
				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					float f = 255;
					
					if ([[event value] respondsToSelector:@selector(floatValue)])
						f = [[event value] floatValue];
					
					if ([[event date] timeIntervalSince1970] > startInterval)
						[timeline setValue:f atInterval:[[event date] timeIntervalSince1970]];
					
					if ([device isKindOfClass:[Camera class]] || [device isKindOfClass:[MobileClient class]] || 
						[device isKindOfClass:[Phone class]])
						[timeline setValue:0 atInterval:([[event date] timeIntervalSince1970] + 10)];
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				
				[timeline release];
			}
			
			NSString * desc = [device name];
			
			NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:11] forKey:NSFontAttributeName];
			[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			NSSize descSize = [desc sizeWithAttributes:attributes];
			NSPoint point = NSMakePoint(timeRect.origin.x + timeRect.size.width - descSize.width, timeRect.origin.y - 20);
			[desc drawAtPoint:point withAttributes:attributes];
			
			[self drawTimeline:timeline start:(startInterval + daySeconds) end:latestInterval inRect:timeRect object:device highlighted:highlight];
			
			*count += 1;
		}
	}

	snapshots = [snapshots sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sort, nil]];

	NSEnumerator * snapIter = [snapshots objectEnumerator];
	Snapshot * snapshot = nil;
	while (snapshot = [snapIter nextObject])
	{
		float x = ceil(((columnWidth + 10) * currentColumn) + bounds.origin.x);
		
		float y = ceil(bounds.size.height - (50 * currentRow));
		
		NSRect timeRect = NSMakeRect(x, y + 20, columnWidth, 30);
		
		currentColumn += 1;
		if (currentColumn < columns)
		{
			
		}
		else
		{
			currentRow += 1;
			currentColumn = 0;
		}
		
		if (timeRect.origin.y - 20 > 0)
		{
			NSString * identifier = [snapshot identifier];
			
			NSRect trackRect = NSMakeRect(timeRect.origin.x - 8, timeRect.origin.y - 8, timeRect.size.width + 15, timeRect.size.height + 5);
			
			NSMutableDictionary * mapDict = [NSMutableDictionary dictionary];
			[mapDict setValue:identifier forKey:@"identifier"];
			[mapDict setValue:[NSValue valueWithRect:trackRect] forKey:@"area"];
			
			NSTrackingRectTag tag = [self addTrackingRect:trackRect owner:self userData:identifier assumeInside:NO];
			
			[mapDict setValue:[NSNumber numberWithInt:tag] forKey:@"area_tag"];
			
			[deviceAreas addObject:mapDict];
			
			[self addCursorRect:trackRect cursor:[NSCursor pointingHandCursor]];
			
			BOOL highlight = NO;
			
			if (highlighted != nil && [identifier isEqual:highlighted])
			{
				[[NSColor darkGrayColor] setFill];
				
				[NSBezierPath fillRoundRectInRect:trackRect radius:5];
				
				highlight = YES;
			}
			
			NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:identifier event:@"snapshot"];
			
			NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
			
			Event * e = [Event eventWithType:@"snapshot" source:@"" initiator:@"" description:@"" value:[NSNumber numberWithFloat:0]  date:[NSDate date]];
			[chartEvents addObject:e];
			
			NSString * cacheKey = [NSString stringWithFormat:@"%@-%f-%f", identifier, startInterval, latestInterval];
			
			PresenceTimeline * timeline = [timelineCache valueForKey:cacheKey];

			if (timeline == nil)
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];
				
				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					float f = 255;
					
					if ([[event value] respondsToSelector:@selector(floatValue)])
						f = [[event value] floatValue];
					
					if ([[event date] timeIntervalSince1970] > startInterval)
						[timeline setValue:f atInterval:[[event date] timeIntervalSince1970]];
					
					[timeline setValue:0 atInterval:([[event date] timeIntervalSince1970] + 1)];
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				
				[timeline release];
			}
			
			NSString * desc = [snapshot name];
			
			NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:11] forKey:NSFontAttributeName];
			[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			NSSize descSize = [desc sizeWithAttributes:attributes];
			NSPoint point = NSMakePoint(timeRect.origin.x + timeRect.size.width - descSize.width, timeRect.origin.y - 20);
			[desc drawAtPoint:point withAttributes:attributes];
			
			[self drawTimeline:timeline start:(startInterval + daySeconds) end:latestInterval inRect:timeRect object:snapshot highlighted:highlight];
			
			*count += 1;
		}
	}

	triggers = [triggers sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sort, nil]];
	
	NSEnumerator * trigIter = [triggers objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [trigIter nextObject])
	{
		float x = ceil(((columnWidth + 10) * currentColumn) + bounds.origin.x);
		
		float y = ceil(bounds.size.height - (50 * currentRow));
		
		NSRect timeRect = NSMakeRect(x, y + 20, columnWidth, 30);
		
		currentColumn += 1;
		if (currentColumn < columns)
		{
			
		}
		else
		{
			currentRow += 1;
			currentColumn = 0;
		}
		
		if (timeRect.origin.y - 20 > 0)
		{
			NSString * identifier = [trigger identifier];
			
			NSRect trackRect = NSMakeRect(timeRect.origin.x - 8, timeRect.origin.y - 8, timeRect.size.width + 15, timeRect.size.height + 5);
			
			NSMutableDictionary * mapDict = [NSMutableDictionary dictionary];
			[mapDict setValue:identifier forKey:@"identifier"];
			[mapDict setValue:[NSValue valueWithRect:trackRect] forKey:@"area"];
			
			NSTrackingRectTag tag = [self addTrackingRect:trackRect owner:self userData:identifier assumeInside:NO];
			
			[mapDict setValue:[NSNumber numberWithInt:tag] forKey:@"area_tag"];
			
			[deviceAreas addObject:mapDict];
			
			[self addCursorRect:trackRect cursor:[NSCursor pointingHandCursor]];
			
			BOOL highlight = NO;
			
			if (highlighted != nil && [identifier isEqual:highlighted])
			{
				[[NSColor darkGrayColor] setFill];
				
				[NSBezierPath fillRoundRectInRect:trackRect radius:5];
				
				highlight = YES;
			}
			
			NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:identifier event:@"trigger"];
			
			NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
			
			Event * e = [Event eventWithType:@"trigger" source:@"" initiator:@"" description:@"" value:[NSNumber numberWithFloat:0]  date:[NSDate date]];
			[chartEvents addObject:e];
			
			NSString * cacheKey = [NSString stringWithFormat:@"%@-%f-%f", identifier, startInterval, latestInterval];
			
			PresenceTimeline * timeline = [timelineCache valueForKey:cacheKey];

			if (timeline == nil)
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];
				
				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					float f = 255;
					
					if ([[event value] respondsToSelector:@selector(floatValue)])
						f = [[event value] floatValue];
					
					if ([[event date] timeIntervalSince1970] > startInterval)
						[timeline setValue:f atInterval:[[event date] timeIntervalSince1970]];
					
					[timeline setValue:0 atInterval:([[event date] timeIntervalSince1970] + 1)];
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				
				[timeline release];
			}
			
			NSString * desc = [trigger name];
			
			NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:11] forKey:NSFontAttributeName];
			[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			NSSize descSize = [desc sizeWithAttributes:attributes];
			NSPoint point = NSMakePoint(timeRect.origin.x + timeRect.size.width - descSize.width, timeRect.origin.y - 20);
			[desc drawAtPoint:point withAttributes:attributes];
			
			[self drawTimeline:timeline start:(startInterval + daySeconds) end:latestInterval inRect:timeRect object:trigger highlighted:highlight];
			
			*count += 1;
		}
	}
	
	[sort release];
}

- (NSArray *) devicesForNode:(NSDictionary *) node
{
	NSMutableSet * devices = [NSMutableSet set];
	
	NSDictionary * device = [node valueForKey:@"device"];
	
	if (device != nil)
		[devices addObject:device];
	
	NSArray * children = [node valueForKey:@"children"];
	
	if (children != nil)
	{
		NSEnumerator * iter = [children objectEnumerator];
		NSDictionary * childNode = nil;
		while (childNode = [iter nextObject])
		{
			NSArray * childArray = [self devicesForNode:childNode];
			
			[devices addObjectsFromArray:childArray];
		}
	}
	
	return [devices allObjects];
}

- (NSArray *) snapshotsForNode:(NSDictionary *) node
{
	NSMutableSet * snapshots = [NSMutableSet set];
	
	NSDictionary * snapshot = [node valueForKey:@"snapshot"];
	
	if (snapshot != nil)
		[snapshots addObject:snapshot];
	
	NSArray * children = [node valueForKey:@"children"];
	
	if (children != nil)
	{
		NSEnumerator * iter = [children objectEnumerator];
		NSDictionary * childNode = nil;
		while (childNode = [iter nextObject])
		{
			NSArray * childArray = [self snapshotsForNode:childNode];
			
			[snapshots addObjectsFromArray:childArray];
		}
	}
	
	return [snapshots allObjects];
}

- (NSArray *) triggersForNode:(NSDictionary *) node
{
	NSMutableSet * triggers = [NSMutableSet set];
	
	NSDictionary * trigger = [node valueForKey:@"trigger"];
	
	if (trigger != nil)
		[triggers addObject:trigger];
	
	NSArray * children = [node valueForKey:@"children"];
	
	if (children != nil)
	{
		NSEnumerator * iter = [children objectEnumerator];
		NSDictionary * childNode = nil;
		while (childNode = [iter nextObject])
		{
			NSArray * childArray = [self triggersForNode:childNode];
			
			[triggers addObjectsFromArray:childArray];
		}
	}
	
	return [triggers allObjects];
}

- (void) drawChartForDevices:(NSArray *) devices drawn:(unsigned int *) count;
{
	[self resetCursorRects];
	
	NSEnumerator * rectIter = [deviceAreas objectEnumerator];
	NSDictionary * dict = nil;
	while (dict = [rectIter nextObject])
	{
		int area = [[dict valueForKey:@"area_tag"] intValue];
		[self removeTrackingRect:area];
	}
	
	[deviceAreas removeAllObjects];
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	
	devices = [devices sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sort, nil]];
	
	float minWidth = 200;
	
	[sort release];
	
 	NSRect bounds = [self bounds];
	
	bounds.size.width -= 20;
	bounds.size.height -= 70;
	bounds.origin.x += 10;
	bounds.origin.y += 10;
	
	float daySeconds = 24 * 60 * 60;
	
	NSDate * today = [NSDate dateWithNaturalLanguageString:@"12:00:00 am"];
	
	NSTimeInterval latestInterval = floor([today timeIntervalSince1970]) + daySeconds;
	NSTimeInterval startInterval = latestInterval - (daySeconds * 2);
	
	*count = 0;
	
	unsigned int rows = bounds.size.height / 50; // Charts are 50px high at the moment.
	unsigned int columns = [devices count] / rows;
	
	bounds.size.height -= 40;
	
	if ([devices count] % rows != 0)
		columns += 1;
	
	while ((bounds.size.width + 10 < (minWidth + 10) * columns) && columns >= 1)
		columns -= 1;
	
	unsigned int currentColumn = 0;
	unsigned int currentRow = 0;
	
	float columnWidth = (bounds.size.width + 10) / columns;
	if (columns > 1)
		columnWidth -= 10;
	else
		columnWidth = bounds.size.width;
	
	NSEnumerator * deviceIter = [devices objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		float x = ceil(((columnWidth + 10) * currentColumn) + bounds.origin.x);
		
		float y = ceil(bounds.size.height - (50 * currentRow));
		
		NSRect timeRect = NSMakeRect(x, y + 20, columnWidth, 30);
		
		currentColumn += 1;
		if (currentColumn < columns)
		{
			
		}
		else
		{
			currentRow += 1;
			currentColumn = 0;
		}
		
		if (timeRect.origin.y - 20 > 0)
		{
			NSString * identifier = [device identifier];
			
			NSRect trackRect = NSMakeRect(timeRect.origin.x - 8, timeRect.origin.y - 8, timeRect.size.width + 15, timeRect.size.height + 5);
			
			NSMutableDictionary * mapDict = [NSMutableDictionary dictionary];
			[mapDict setValue:identifier forKey:@"identifier"];
			[mapDict setValue:[NSValue valueWithRect:trackRect] forKey:@"area"];
			
			NSTrackingRectTag tag = [self addTrackingRect:trackRect owner:self userData:identifier assumeInside:NO];
			
			[mapDict setValue:[NSNumber numberWithInt:tag] forKey:@"area_tag"];
			
			[deviceAreas addObject:mapDict];
			
			[self addCursorRect:trackRect cursor:[NSCursor pointingHandCursor]];
			
			BOOL highlight = NO;
			
			if (highlighted != nil && [identifier isEqual:highlighted])
			{
				[[NSColor darkGrayColor] setFill];
				
				[NSBezierPath fillRoundRectInRect:trackRect radius:5];
				
				highlight = YES;
			}
			
			if ([device isKindOfClass:[Controller class]])
				identifier = @"Controller";
			else if ([device isKindOfClass:[Phone class]])
				identifier = @"Phone";
			
			NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:identifier event:@"device"];
			
			NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
			
			Event * e = [Event eventWithType:@"device" source:@"" initiator:@"" description:@"" value:[NSNumber numberWithFloat:0]  date:[NSDate date]];
			[chartEvents addObject:e];
			
			NSString * cacheKey = [NSString stringWithFormat:@"%@-%f-%f", identifier, startInterval, latestInterval];
			
			PresenceTimeline * timeline = [timelineCache valueForKey:cacheKey];

			if (timeline == nil && [device isKindOfClass:[Thermostat class]])
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];
				
				float averageTemp = 0;
				int count = 0;
				
				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					if ([[event value] respondsToSelector:@selector(floatValue)])
					{
						float temp = [[event value] floatValue];
						
						averageTemp += temp;
						
						count += 1;
					}
				}
				
				averageTemp = averageTemp / count;
				
				float minTemp = 9999;
				float maxTemp = -9999;
				
				eventIter = [chartEvents objectEnumerator];
				event = nil;
				while ((event = [eventIter nextObject]))
				{
					float f = 0;
					
					if ([[event value] respondsToSelector:@selector(floatValue)])
						f = [[event value] floatValue];
					
					float temp = f;
					
					if (fabs(averageTemp - temp) < 20)
					{
						if (temp < minTemp)
							minTemp = temp;
						
						if (temp > maxTemp)
							maxTemp = temp;
					}
				}
				
				float diff = maxTemp - minTemp;
				
				unsigned int length = [chartEvents count];
				
				if (length > 0)
				{
					unsigned int i = 0;
					
					Event * thisEvent = [chartEvents objectAtIndex:0];
					Event * nextEvent = nil;
					
					NSTimeInterval thisTime = [[thisEvent date] timeIntervalSince1970];
					NSTimeInterval nextTime = 0;
					
					if (length > 1)
					{
						nextEvent = [chartEvents objectAtIndex:1];
						nextTime = [[nextEvent date] timeIntervalSince1970];
					}
					
					for (i = 0; i < length; i++)
					{
						if (thisTime > startInterval)
						{
							float normalizedTemp = ([[thisEvent value] floatValue] - minTemp) / diff;
							
							if (normalizedTemp < 0)
								normalizedTemp = 0;
							
							if (normalizedTemp > 1)
								normalizedTemp = 1;
							
							if (nextEvent != nil)
								[timeline setValue:(255 * normalizedTemp) atInterval:thisTime duration:(nextTime - thisTime)];
							else
								[timeline setValue:(255 * normalizedTemp) atInterval:thisTime];
						}
						
						if (nextEvent != nil)
						{
							thisEvent = nextEvent;
							thisTime = nextTime;
						}
						
						if (i < (length - 1))
						{
							nextEvent = [chartEvents objectAtIndex:(i + 1)];
							nextTime = [[nextEvent date] timeIntervalSince1970];
						}
						else
							nextEvent = nil;
					}
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				[timeline release];
			}
			else if (timeline == nil && [device isKindOfClass:[PowerMeterSensor class]])
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];
				
				float minPower = 9999;
				float maxPower = -9999;
				
				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					float f = 0;
					
					if ([[event value] respondsToSelector:@selector(floatValue)])
						f = [[event value] floatValue];
					
					float power = f;
					
					if (power > 0 && power < 10000)
					{
						if (power < minPower)
							minPower = power;
						
						if (power > maxPower)
							maxPower = power;
					}
				}
			
				float diff = maxPower - minPower;
				
				unsigned int length = [chartEvents count];
				
				if (length > 0)
				{
					unsigned int i = 0;
					
					Event * thisEvent = [chartEvents objectAtIndex:0];
					Event * nextEvent = nil;
					
					NSTimeInterval thisTime = [[thisEvent date] timeIntervalSince1970];
					NSTimeInterval nextTime = 0;
					
					if (length > 1)
					{
						nextEvent = [chartEvents objectAtIndex:1];
						nextTime = [[nextEvent date] timeIntervalSince1970];
					}
					
					for (i = 0; i < length; i++)
					{
						if (thisTime > startInterval)
						{
							float normalizedPower = ([[thisEvent value] floatValue] - minPower) / diff;
							
							if (normalizedPower < 0.0)
								normalizedPower = 0.0;
							else if (normalizedPower > 1.0)
								normalizedPower = 1.0;
							
							if (nextEvent != nil)
								[timeline setValue:(255 * normalizedPower) atInterval:thisTime duration:(nextTime - thisTime)];
							else
								[timeline setValue:(255 * normalizedPower) atInterval:thisTime];
						}
						
						if (nextEvent != nil)
						{
							thisEvent = nextEvent;
							thisTime = nextTime;
						}
						
						if (i < (length - 1))
						{
							nextEvent = [chartEvents objectAtIndex:(i + 1)];
							nextTime = [[nextEvent date] timeIntervalSince1970];
						}
						else
							nextEvent = nil;
					}
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				[timeline release];
			}
			if (timeline == nil && [device isKindOfClass:[WeatherUndergroundStation class]])
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];
				
				float minTemp = 9999;
				float maxTemp = -9999;
				
				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					float f = 0;
					
					if ([[event value] respondsToSelector:@selector(floatValue)])
						f = [[event value] floatValue];
					
					float temp = f;
					
					if (temp != 0)
					{
						if (temp < minTemp)
							minTemp = temp;
					
						if (temp > maxTemp)
							maxTemp = temp;
					}
				}
				
				float diff = maxTemp - minTemp;
				
				unsigned int length = [chartEvents count];
				
				if (length > 0)
				{
					unsigned int i = 0;
					
					Event * thisEvent = [chartEvents objectAtIndex:0];
					Event * nextEvent = nil;
					
					NSTimeInterval thisTime = [[thisEvent date] timeIntervalSince1970];
					NSTimeInterval nextTime = 0;
					
					if (length > 1)
					{
						nextEvent = [chartEvents objectAtIndex:1];
						nextTime = [[nextEvent date] timeIntervalSince1970];
					}
					
					for (i = 0; i < length; i++)
					{
						if (thisTime > startInterval)
						{
							float normalizedPower = ([[thisEvent value] floatValue] - minTemp) / diff;
							
							if (normalizedPower < 0)
								normalizedPower = 0.5;
							
							if (nextEvent != nil)
								[timeline setValue:(255 * normalizedPower) atInterval:thisTime duration:(nextTime - thisTime)];
							else
								[timeline setValue:(255 * normalizedPower) atInterval:thisTime];
						}
						
						if (nextEvent != nil)
						{
							thisEvent = nextEvent;
							thisTime = nextTime;
						}
						
						if (i < (length - 1))
						{
							nextEvent = [chartEvents objectAtIndex:(i + 1)];
							nextTime = [[nextEvent date] timeIntervalSince1970];
						}
						else
							nextEvent = nil;
					}
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				[timeline release];
			}
			else if (timeline == nil)
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];

				unsigned int length = [chartEvents count];

				if (length > 0)
				{
					unsigned int i = 0;
					
					Event * thisEvent = [chartEvents objectAtIndex:0];
					Event * nextEvent = nil;
					
					NSTimeInterval thisTime  = [[thisEvent date] timeIntervalSince1970];
					NSTimeInterval nextTime = 0;
					
					if (length > 1)
					{
						nextEvent = [chartEvents objectAtIndex:1];
						nextTime = [[nextEvent date] timeIntervalSince1970];
					}
					
					for (i = 0; i < length; i++)
					{
						if (thisTime > startInterval)
						{
							id value = [thisEvent value];
							
							float f = 255;
							
							if ([value respondsToSelector:@selector(floatValue)])
								f = [value floatValue];
							
							if (nextEvent != nil)
							{
								if ([device isKindOfClass:[Camera class]] || [device isKindOfClass:[Phone class]] || 
									[device isKindOfClass:[MobileClient class]])
								{
									[timeline setValue:f atInterval:thisTime duration:10];
									[timeline setValue:0 atInterval:(thisTime + 10) duration:(nextTime - thisTime - 10)];
								}
								else
								{
									[timeline setValue:f atInterval:thisTime duration:(nextTime - thisTime)];
								}
							}
							else
							{
								[timeline setValue:f atInterval:thisTime];

								if ([device isKindOfClass:[Camera class]] || [device isKindOfClass:[Phone class]] ||
									[device isKindOfClass:[MobileClient class]])
									[timeline setValue:0 atInterval:(thisTime + 10)];
							}
						}									
						
						if (nextEvent != nil)
						{
							thisEvent = nextEvent;
							thisTime = nextTime;
						}
							
						if (i < (length - 1))
						{
							nextEvent = [chartEvents objectAtIndex:(i + 1)];
							nextTime = [[nextEvent date] timeIntervalSince1970];
						}
						else
							nextEvent = nil;
					}
				}

				[timelineCache setValue:timeline forKey:cacheKey];
				[timeline release];
			} 
			
			NSString * desc = [device name];
			
			NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:11] forKey:NSFontAttributeName];
			[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			NSSize descSize = [desc sizeWithAttributes:attributes];
			NSPoint point = NSMakePoint(timeRect.origin.x + timeRect.size.width - descSize.width, timeRect.origin.y - 20);
			[desc drawAtPoint:point withAttributes:attributes];
			
			[self drawTimeline:timeline start:(startInterval + daySeconds) end:latestInterval inRect:timeRect object:device highlighted:highlight];
			
			*count += 1;
		}
	}
}

- (void) drawChartForSnapshots:(NSArray *) snapshots drawn:(unsigned int *) count;
{
	[self resetCursorRects];
	
	NSEnumerator * rectIter = [deviceAreas objectEnumerator];
	NSDictionary * dict = nil;
	while (dict = [rectIter nextObject])
	{
		int area = [[dict valueForKey:@"area_tag"] intValue];
		[self removeTrackingRect:area];
	}
	
	[deviceAreas removeAllObjects];
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	
	snapshots = [snapshots sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sort, nil]];
	
	float minWidth = 200;
	
	[sort release];
	
 	NSRect bounds = [self bounds];
	
	bounds.size.width -= 20;
	bounds.size.height -= 70;
	bounds.origin.x += 10;
	bounds.origin.y += 10;
	
	float daySeconds = 24 * 60 * 60;
	
	NSDate * today = [NSDate dateWithNaturalLanguageString:@"12:00:00 am"];
	
	NSTimeInterval latestInterval = floor([today timeIntervalSince1970]) + daySeconds;
	NSTimeInterval startInterval = latestInterval - (daySeconds * 2);
	
	*count = 0;
	
	unsigned int rows = bounds.size.height / 50; // Charts are 50px high at the moment.
	unsigned int columns = [snapshots count] / rows;
	
	bounds.size.height -= 40;
	
	if ([snapshots count] % rows != 0)
		columns += 1;
	
	while ((bounds.size.width + 10 < (minWidth + 10) * columns) && columns >= 1)
		columns -= 1;
	
	unsigned int currentColumn = 0;
	unsigned int currentRow = 0;
	
	float columnWidth = (bounds.size.width + 10) / columns;
	if (columns > 1)
		columnWidth -= 10;
	else
		columnWidth = bounds.size.width;
	
	NSEnumerator * snapIter = [snapshots objectEnumerator];
	Snapshot * snapshot = nil;
	while (snapshot = [snapIter nextObject])
	{
		float x = ceil(((columnWidth + 10) * currentColumn) + bounds.origin.x);
		
		float y = ceil(bounds.size.height - (50 * currentRow));
		
		NSRect timeRect = NSMakeRect(x, y + 20, columnWidth, 30);
		
		currentColumn += 1;
		if (currentColumn < columns)
		{
			
		}
		else
		{
			currentRow += 1;
			currentColumn = 0;
		}
		
		if (timeRect.origin.y - 20 > 0)
		{
			NSString * identifier = [snapshot identifier];
			
			NSRect trackRect = NSMakeRect(timeRect.origin.x - 8, timeRect.origin.y - 8, timeRect.size.width + 15, timeRect.size.height + 5);
			
			NSMutableDictionary * mapDict = [NSMutableDictionary dictionary];
			[mapDict setValue:identifier forKey:@"identifier"];
			[mapDict setValue:[NSValue valueWithRect:trackRect] forKey:@"area"];
			
			NSTrackingRectTag tag = [self addTrackingRect:trackRect owner:self userData:identifier assumeInside:NO];
			
			[mapDict setValue:[NSNumber numberWithInt:tag] forKey:@"area_tag"];
			
			[deviceAreas addObject:mapDict];
			
			[self addCursorRect:trackRect cursor:[NSCursor pointingHandCursor]];
			
			BOOL highlight = NO;
			
			if (highlighted != nil && [identifier isEqual:highlighted])
			{
				[[NSColor darkGrayColor] setFill];
				
				[NSBezierPath fillRoundRectInRect:trackRect radius:5];
				
				highlight = YES;
			}
			
			NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:identifier event:@"snapshot"];
			
			NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
			
			Event * e = [Event eventWithType:@"snapshot" source:@"" initiator:@"" description:@"" value:[NSNumber numberWithFloat:0]  date:[NSDate date]];
			[chartEvents addObject:e];
			
			NSString * cacheKey = [NSString stringWithFormat:@"%@-%f-%f", identifier, startInterval, latestInterval];
			
			PresenceTimeline * timeline = [timelineCache valueForKey:cacheKey];

			if (timeline == nil)
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];

				unsigned int length = [chartEvents count];
				
				if (length > 0)
				{
					unsigned int i = 0;
					
					Event * thisEvent = [chartEvents objectAtIndex:0];
					Event * nextEvent = nil;
					
					NSTimeInterval thisTime = [[thisEvent date] timeIntervalSince1970];
					NSTimeInterval nextTime = 0;
					
					if (length > 1)
					{
						nextEvent = [chartEvents objectAtIndex:1];
						nextTime = [[nextEvent date] timeIntervalSince1970];
					}
					
					for (i = 0; i < length; i++)
					{
						if (thisTime > startInterval)
						{
							id value = [thisEvent value];
							
							float f = 255;
							
							if ([value respondsToSelector:@selector(floatValue)])
								f = [value floatValue];
							
							if (nextEvent != nil)
							{
								[timeline setValue:f atInterval:thisTime duration:10];
								[timeline setValue:0 atInterval:thisTime duration:(nextTime - thisTime + 10)];
							}
							else
								[timeline setValue:f atInterval:thisTime];
						}
						
						if (nextEvent != nil)
						{
							thisEvent = nextEvent;
							thisTime = nextTime;
						}
						
						if (i < (length - 1))
						{
							nextEvent = [chartEvents objectAtIndex:(i + 1)];
							nextTime = [[nextEvent date] timeIntervalSince1970];
						}
						else
							nextEvent = nil;
					}
				}

				[timelineCache setValue:timeline forKey:cacheKey];
				
				[timeline release];
			}
			
			NSString * desc = [snapshot name];
			
			NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:11] forKey:NSFontAttributeName];
			[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			NSSize descSize = [desc sizeWithAttributes:attributes];
			NSPoint point = NSMakePoint(timeRect.origin.x + timeRect.size.width - descSize.width, timeRect.origin.y - 20);
			[desc drawAtPoint:point withAttributes:attributes];
			
			[self drawTimeline:timeline start:(startInterval + daySeconds) end:latestInterval inRect:timeRect object:snapshot highlighted:highlight];
			
			*count += 1;
		}
	}
}

- (void) drawChartForTriggers:(NSArray *) triggers drawn:(unsigned int *) count;
{
	[self resetCursorRects];
	
	NSEnumerator * rectIter = [deviceAreas objectEnumerator];
	NSDictionary * dict = nil;
	while (dict = [rectIter nextObject])
	{
		int area = [[dict valueForKey:@"area_tag"] intValue];
		[self removeTrackingRect:area];
	}
	
	[deviceAreas removeAllObjects];
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	
	triggers = [triggers sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sort, nil]];
	
	float minWidth = 200;
	
	[sort release];
	
 	NSRect bounds = [self bounds];
	
	bounds.size.width -= 20;
	bounds.size.height -= 70;
	bounds.origin.x += 10;
	bounds.origin.y += 10;
	
	float daySeconds = 24 * 60 * 60;
	
	NSDate * today = [NSDate dateWithNaturalLanguageString:@"12:00:00 am"];
	
	NSTimeInterval latestInterval = floor([today timeIntervalSince1970]) + daySeconds;
	NSTimeInterval startInterval = latestInterval - (daySeconds * 2);
	
	*count = 0;
	
	unsigned int rows = bounds.size.height / 50; // Charts are 50px high at the moment.
	unsigned int columns = [triggers count] / rows;
	
	bounds.size.height -= 40;
	
	if ([triggers count] % rows != 0)
		columns += 1;
	
	while ((bounds.size.width + 10 < (minWidth + 10) * columns) && columns >= 1)
		columns -= 1;
	
	unsigned int currentColumn = 0;
	unsigned int currentRow = 0;
	
	float columnWidth = (bounds.size.width + 10) / columns;
	if (columns > 1)
		columnWidth -= 10;
	else
		columnWidth = bounds.size.width;
	
	NSEnumerator * trigIter = [triggers objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [trigIter nextObject])
	{
		float x = ceil(((columnWidth + 10) * currentColumn) + bounds.origin.x);
		
		float y = ceil(bounds.size.height - (50 * currentRow));
		
		NSRect timeRect = NSMakeRect(x, y + 20, columnWidth, 30);
		
		currentColumn += 1;
		if (currentColumn < columns)
		{
			
		}
		else
		{
			currentRow += 1;
			currentColumn = 0;
		}
		
		if (timeRect.origin.y - 20 > 0)
		{
			NSString * identifier = [trigger identifier];
			
			NSRect trackRect = NSMakeRect(timeRect.origin.x - 8, timeRect.origin.y - 8, timeRect.size.width + 15, timeRect.size.height + 5);
			
			NSMutableDictionary * mapDict = [NSMutableDictionary dictionary];
			[mapDict setValue:identifier forKey:@"identifier"];
			[mapDict setValue:[NSValue valueWithRect:trackRect] forKey:@"area"];
			
			NSTrackingRectTag tag = [self addTrackingRect:trackRect owner:self userData:identifier assumeInside:NO];
			
			[mapDict setValue:[NSNumber numberWithInt:tag] forKey:@"area_tag"];
			
			[deviceAreas addObject:mapDict];
			
			[self addCursorRect:trackRect cursor:[NSCursor pointingHandCursor]];
			
			BOOL highlight = NO;
			
			if (highlighted != nil && [identifier isEqual:highlighted])
			{
				[[NSColor darkGrayColor] setFill];
				
				[NSBezierPath fillRoundRectInRect:trackRect radius:5];
				
				highlight = YES;
			}
			
			NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:identifier event:@"trigger"];
			
			NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
			
			Event * e = [Event eventWithType:@"trigger" source:@"" initiator:@"" description:@"" value:[NSNumber numberWithFloat:0]  date:[NSDate date]];
			[chartEvents addObject:e];
			
			NSString * cacheKey = [NSString stringWithFormat:@"%@-%f-%f", identifier, startInterval, latestInterval];
			
			PresenceTimeline * timeline = [timelineCache valueForKey:cacheKey];

			if (timeline == nil)
			{
				timeline = [[PresenceTimeline alloc] initWithStart:startInterval
															   end:latestInterval
													  initialValue:0];

				unsigned int length = [chartEvents count];
				
				if (length > 0)
				{
					unsigned int i = 0;
					
					Event * thisEvent = [chartEvents objectAtIndex:0];
					Event * nextEvent = nil;
					
					NSTimeInterval thisTime = [[thisEvent date] timeIntervalSince1970];
					NSTimeInterval nextTime = 0;
					
					if (length > 1)
					{
						nextEvent = [chartEvents objectAtIndex:1];
						nextTime = [[nextEvent date] timeIntervalSince1970];
					}
					
					for (i = 0; i < length; i++)
					{
						if (thisTime > startInterval)
						{
							id value = [thisEvent value];

							float f = 255;
							
							if ([value respondsToSelector:@selector(floatValue)])
								f = [value floatValue];
							
							if (nextEvent != nil)
							{
								[timeline setValue:f atInterval:thisTime duration:10];
								[timeline setValue:0 atInterval:thisTime duration:(nextTime - thisTime + 10)];
							}
							else
								[timeline setValue:f atInterval:thisTime];
						}

						if (nextEvent != nil)
						{
							thisEvent = nextEvent;
							thisTime = nextTime;
						}
						
						if (i < (length - 1))
						{
							nextEvent = [chartEvents objectAtIndex:(i + 1)];
							nextTime = [[nextEvent date] timeIntervalSince1970];
						}
						else
							nextEvent = nil;
					}
				}
				
				[timelineCache setValue:timeline forKey:cacheKey];
				
				[timeline release];
			}
			
			NSString * desc = [trigger name];
			
			NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:11] forKey:NSFontAttributeName];
			[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			NSSize descSize = [desc sizeWithAttributes:attributes];
			NSPoint point = NSMakePoint(timeRect.origin.x + timeRect.size.width - descSize.width, timeRect.origin.y - 20);
			[desc drawAtPoint:point withAttributes:attributes];
			
			[self drawTimeline:timeline start:(startInterval + daySeconds) end:latestInterval inRect:timeRect object:trigger highlighted:highlight];
			
			*count += 1;
		}
	}
}

- (void) mouseUp:(NSEvent *) theEvent 
{
	NSPoint mouse = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	NSEnumerator * iter = [deviceAreas objectEnumerator];
	NSDictionary * areaDict = nil;
	while (areaDict = [iter nextObject])
	{
		NSString * identifier = [areaDict valueForKey:@"identifier"];
		NSRect area = [[areaDict valueForKey:@"area"] rectValue];
		
		if (NSPointInRect(mouse, area))
		{
			[[ConsoleManager sharedInstance] selectItemWithIdentifier:identifier];
		}
	}
}

- (void)mouseEntered:(NSEvent *)theEvent 
{
	NSPoint mouse = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	NSEnumerator * iter = [deviceAreas objectEnumerator];
	NSDictionary * areaDict = nil;
	while (areaDict = [iter nextObject])
	{
		NSString * identifier = [areaDict valueForKey:@"identifier"];
		NSRect area = [[areaDict valueForKey:@"area"] rectValue];

		area = NSMakeRect(area.origin.x - 2, area.origin.y - 2, area.size.width + 4, area.size.height + 4);
		
		if (NSPointInRect(mouse, area))
			highlighted = identifier;
	}

	highlighted = nil;

	[self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent 
{
	if (highlighted == nil)
		return;
	
	[NSCursor pop];
	
	highlighted = nil;
	
	[self setNeedsDisplay:YES];
}

- (void) awakeFromNib
{
	if (objectController != nil)
	{
		[objectController addObserver:self forKeyPath:@"selection" options:0 context:NULL];
		[objectController addObserver:self forKeyPath:@"content" options:0 context:NULL];
		[objectController addObserver:self forKeyPath:@"selection.last_update" options:0 context:NULL];
	}
	
	highlighted = nil;
	
	deviceAreas = [[NSMutableArray alloc] init];
}

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	NSDictionary * node = [[objectController selectedObjects] lastObject];
	
	if ([node isKindOfClass:[NSDictionary class]])
	{
		NSRect bounds = [self bounds];
		NSString * name = [node valueForKey:@"label"];

		NSArray * devices = [self devicesForNode:node];
		NSArray * snapshots = [self snapshotsForNode:node];
		NSArray * triggers = [self triggersForNode:node];
		
		NSString * desc = @"";
		
		if ([devices count] > 0 && [snapshots count] == 0 && [triggers count] == 0)
		{
			unsigned int count = 0;
		
			[self drawChartForDevices:devices drawn:&count];

			if ([devices count] == 1)
				desc = [NSString stringWithFormat:@"1 device (%d visible)", count]; 
			else
				desc = [NSString stringWithFormat:@"%d devices (%d visible)", [devices count], count]; 

			if (count == [devices count])
			{
				if (count == 1)
					desc = @"1 device";
				else
					desc = [NSString stringWithFormat:@"%d devices", [devices count]];
			}
		}
		else if ([devices count] == 0 && [snapshots count] > 0 && [triggers count] == 0)
		{
			unsigned int count = 0;
			
			[self drawChartForSnapshots:snapshots drawn:&count];

			if ([snapshots count] == 1)
				desc = [NSString stringWithFormat:@"1 snapshot (%d visible)", count]; 
			else
				desc = [NSString stringWithFormat:@"%d snapshots (%d visible)", [snapshots count], count]; 
			
			if (count == [snapshots count])
			{
				if (count == 1)
					desc = @"1 snapshot";
				else
					desc = [NSString stringWithFormat:@"%d snapshots", [snapshots count]];
			}
		}
		else if ([devices count] == 0 && [snapshots count] == 0 && [triggers count] > 0)
		{
			unsigned int count = 0;
			
			[self drawChartForTriggers:triggers drawn:&count];

			if ([triggers count] == 1)
				desc = [NSString stringWithFormat:@"1 trigger (%d visible)", count]; 
			else
				desc = [NSString stringWithFormat:@"%d triggers (%d visible)", [triggers count], count]; 
			
			if (count == [triggers count])
			{
				if (count == 1)
					desc = @"1 trigger";
				else
					desc = [NSString stringWithFormat:@"%d triggers", [triggers count]];
			}
		}
		else
		{
			unsigned int count = 0;
			
			[self drawChartForFavoriteDevices:devices snapshots:snapshots triggers:triggers drawn:&count];
			
			unsigned int itemCount = [devices count];
			itemCount += [snapshots count];
			itemCount += [triggers count];
			
			if (itemCount == 1)
				desc = [NSString stringWithFormat:@"1 favorite (%d visible)", count]; 
			else
				desc = [NSString stringWithFormat:@"%d favorites (%d visible)", itemCount, count]; 
			
			if (count == itemCount)
			{
				if (count == 1)
					desc = @"1 favorite";
				else
					desc = [NSString stringWithFormat:@"%d favorites", itemCount];
			}
		}
		
		
		NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
		[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:18] forKey:NSFontAttributeName];
		[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		NSSize titleSize = [name sizeWithAttributes:attributes];
		NSPoint point = NSMakePoint(bounds.size.width - titleSize.width - 10, bounds.size.height - titleSize.height - 5);
		[name drawAtPoint:point withAttributes:attributes];

		[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:12] forKey:NSFontAttributeName];
		
		NSSize descSize = [desc sizeWithAttributes:attributes];
		point = NSMakePoint(bounds.size.width - descSize.width - 10, bounds.size.height - titleSize.height - descSize.height - 5);
		[desc drawAtPoint:point withAttributes:attributes];
	}
}

@end
