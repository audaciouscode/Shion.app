//
//  ThermostatView.m
//  Shion
//
//  Created by Chris Karr on 4/15/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ThermostatView.h"
#import "EventManager.h"
#import "Thermostat.h"

@implementation ThermostatView

- (void) drawChartForEvents:(NSArray *) events days:(int) days
{
	if ([events count] > 1)
	{
		NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
		
		NSManagedObjectContext * context = [[EventManager sharedInstance] managedObjectContext];
		
		NSManagedObject * e = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
															inManagedObjectContext:context];
		[e setValue:@"device" forKey:@"type"];
		[e setValue:@"" forKey:@"source"];
		[e setValue:@"" forKey:@"initiator"];
		[e setValue:@"" forKey:@"event_description"];
		[e setValue:@"0" forKey:@"value"];
		[e setValue:[NSDate date] forKey:@"date"];
		
		[chartEvents addObject:e];

		NSRect bounds = [self bounds];
		
		bounds.size.width -= 20;
		bounds.size.height -= 70;
		bounds.origin.x += 10;
		bounds.origin.y += 10;
		
		if (days == 0)
			days = (int) (bounds.size.height / 30);
		
		float daySeconds = 24 * 60 * 60;
		
		NSDate * today = [NSDate dateWithNaturalLanguageString:@"12:00:00 am"];
		
		NSTimeInterval latestInterval = floor([today timeIntervalSince1970]) + daySeconds;
		
		NSTimeInterval startInterval = latestInterval - (days * daySeconds);
		
		NSString * cacheKey = [NSString stringWithFormat:@"%@-%f-%f", [[events lastObject] source], startInterval, latestInterval];
		
		PresenceTimeline * timeline = [[[EventManager sharedInstance] timelineCache] valueForKey:cacheKey];

		if (timeline == nil)
		{
			timeline = [[PresenceTimeline alloc] initWithStart:startInterval
														   end:latestInterval
												  initialValue:0];

			float averageTemp = 0;
			int invalidTemps = 0;
			
			NSEnumerator * eventIter = [chartEvents objectEnumerator];
			NSManagedObject * event = nil;
			while ((event = [eventIter nextObject]))
			{
				float temp = [[event valueForKey:@"value"] floatValue];

				if (temp == 0)
					invalidTemps += 1;
				
				averageTemp += temp;
			}
			
			averageTemp = averageTemp / ([chartEvents count] - invalidTemps);

			minTemp = 9999;
			maxTemp = -9999;

			eventIter = [chartEvents objectEnumerator];
			event = nil;
			while ((event = [eventIter nextObject]))
			{
				float temp = [[event valueForKey:@"value"] floatValue];

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

				NSManagedObject * thisEvent = [chartEvents objectAtIndex:0];
				NSManagedObject * nextEvent = nil;

				NSTimeInterval thisTime = [[thisEvent valueForKey:@"date"] timeIntervalSince1970];
				NSTimeInterval nextTime = 0;

				if (length > 1)
				{
					nextEvent = [chartEvents objectAtIndex:1];
					nextTime = [[nextEvent valueForKey:@"date"] timeIntervalSince1970];
				}

				for (i = 0; i < length; i++)
				{
					if (thisTime > startInterval)
					{
						float normalizedTemp = ([[thisEvent valueForKey:@"value"] floatValue] - minTemp) / diff;
						
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
						nextTime = [[nextEvent valueForKey:@"date"] timeIntervalSince1970];
					}
					else
						nextEvent = nil;
				}
			}
			
/*			eventIter = [chartEvents objectEnumerator];
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
*/			
			[[[EventManager sharedInstance] timelineCache] setValue:timeline forKey:cacheKey];
			[timeline release];
		}
		
		NSMutableArray * labels = [NSMutableArray array];
		
		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"MMM d"];
		
		for (int day = 0; day < days; day++)
		{
			NSTimeInterval startInterval = latestInterval - (daySeconds * day);
			
			NSDate * date = [NSDate dateWithTimeIntervalSince1970:startInterval - (60 * 60 * 24)];
			
			[labels addObject:[formatter stringFromDate:date]];
		}
		
		[formatter release];
		
		NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
		[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:10] forKey:NSFontAttributeName];
		[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		float labelWidth = 0;
		NSEnumerator * labelIter = [labels objectEnumerator];
		NSString * label = nil;
		while (label = [labelIter nextObject])
		{
			NSSize labelSize = [label sizeWithAttributes:attributes];
			
			if (labelSize.width > labelWidth)
				labelWidth = labelSize.width;
		}			
		
		for (int day = 0; day < days; day++)
		{
			NSString * label = [labels objectAtIndex:day];
			
			NSSize labelSize = [label sizeWithAttributes:attributes];
			
			float offset = labelWidth - labelSize.width;
			
			[label drawAtPoint:NSMakePoint(bounds.origin.x + offset, bounds.origin.y + bounds.size.height - 3 - (30 * (day + 1))) withAttributes:attributes];
		}
		
		labelWidth += 5;
		
		for (int day = 0; day < days; day++)
		{
			NSTimeInterval startInterval = latestInterval - daySeconds;
			
			NSRect timeRect = NSMakeRect(bounds.origin.x, bounds.origin.y + bounds.size.height - (30 * (day + 1)), bounds.size.width, 30);
			timeRect.origin.x += ceil(labelWidth);
			timeRect.size.width -= ceil(labelWidth);
			
			[self drawTimeline:timeline start:startInterval end:latestInterval inRect:timeRect];
			
			latestInterval -= daySeconds;
		}
		
		[context deleteObject:e];
	}
}

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	Thermostat * thermostat = [objectController content];
	
	if ([thermostat isKindOfClass:[Thermostat class]])
	{
		NSRect bounds = [self bounds];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:[thermostat identifier] event:@"device"];
		
		NSString * name = [thermostat name];
		
		[self drawChartForEvents:events];
		
		NSManagedObject * lastEvent = nil;
		
		if ([events count] > 0)
		{
			NSString * state = @"Inactive";
			
			if ([thermostat isRunning])
				state = @"Active";
			
			name = [NSString stringWithFormat:@"%@ (Range: %0.0f° - %0.0f°, %@)", name, minTemp, maxTemp, state];

			lastEvent = [events lastObject];

			NSNumber * lastLevel = [lastEvent valueForKey:@"value"];

			NSString * desc = [NSString stringWithFormat:@"Current Temperature: %@°", lastLevel];;
			NSColor * color = [NSColor whiteColor];
		
			NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:18] forKey:NSFontAttributeName];
			[attributes setValue:color forKey:NSForegroundColorAttributeName];
		
			NSSize descSize = [desc sizeWithAttributes:attributes];
			NSPoint point = NSMakePoint(bounds.size.width - descSize.width - 10, bounds.size.height - descSize.height - 5);
			[desc drawAtPoint:point withAttributes:attributes];
		
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:12] forKey:NSFontAttributeName];
			[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
			NSSize titleSize = [name sizeWithAttributes:attributes];
			point = NSMakePoint(bounds.size.width - titleSize.width - 10, bounds.size.height - descSize.height - titleSize.height - 5);
			[name drawAtPoint:point withAttributes:attributes];
		}
		
	}
}

- (void) drawTimeline:(PresenceTimeline *) timeline start:(NSTimeInterval) start end:(NSTimeInterval) end inRect:(NSRect) rect object:(id) object
{
	float height = rect.size.height - 10;
	
	[[self primaryColorForObject:object] setStroke];
	
	float daySeconds = 24 * 60 * 60;
	float secondsPerPixel = daySeconds / rect.size.width;
	
	for (unsigned int i = 0; i < rect.size.width; i++)
	{
		float value = [timeline averageForStart:(start + (secondsPerPixel * i)) end:(start + (secondsPerPixel * (i + 1)))];
		
		if (value > 0)
		{
			if (value > 255)
				value = 255;
			
			NSBezierPath * path = [NSBezierPath bezierPath];
			
			float x = rect.origin.x + i - 0.5;
			float y = rect.origin.y;
			
			[path moveToPoint:NSMakePoint(x, y)];
			[path lineToPoint:NSMakePoint(x, y + ceil(height * (value / 255)))];
			
			[path stroke];
		}
	}
	
	[[NSColor whiteColor] setStroke];
	
	NSBezierPath * axes = [NSBezierPath bezierPath];
	[axes moveToPoint:NSMakePoint(rect.origin.x - 0.5, rect.origin.y + height)];
	[axes lineToPoint:NSMakePoint(rect.origin.x - 0.5, rect.origin.y - 0.5)];
	[axes lineToPoint:NSMakePoint(rect.origin.x + rect.size.width - 1, rect.origin.y - 0.5)];
	[axes stroke];
	
	float hourWidth = rect.size.width / 24;
	
	for (int i = 1; i < 24; i++)
	{
		NSPoint tick = NSMakePoint(rect.origin.x - 0.5 + ceil(i * hourWidth), rect.origin.y - 0.5);
		
		float tickLength = 2;
		
		if (i % 6 == 0)
			tickLength = 6;
		else if (i % 3 == 0)
			tickLength = 4;
		
		NSBezierPath * tickPath = [NSBezierPath bezierPath];
		[tickPath moveToPoint:NSMakePoint(tick.x, tick.y)];
		[tickPath lineToPoint:NSMakePoint(tick.x, tick.y - tickLength - 0.5)];
		[tickPath stroke];
	}
}

@end
