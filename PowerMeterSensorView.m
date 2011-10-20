//
//  PowerMeterSensorView.m
//  Shion
//
//  Created by Chris Karr on 7/4/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "PowerMeterSensorView.h"

#import "PowerMeterSensor.h"
#import "EventManager.h"
#import "Event.h"


@implementation PowerMeterSensorView

- (void) drawChartForEvents:(NSArray *) events days:(int) days
{
	if ([events count] > 1)
	{
		NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
		
		Event * e = [Event eventWithType:@"device" source:@"" initiator:@"" description:@"" value:[NSNumber numberWithFloat:0]  date:[NSDate date]];
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
		
		PresenceTimeline * timeline = [timelineCache valueForKey:cacheKey];
		
		if (timeline == nil)
		{
			timeline = [[PresenceTimeline alloc] initWithStart:startInterval
														   end:latestInterval
												  initialValue:0];
			
			minPower = 9999;
			maxPower = -9999;
			
			NSEnumerator * eventIter = [chartEvents objectEnumerator];
			Event * event = nil;
			while ((event = [eventIter nextObject]))
			{
				float power = [[event value] floatValue];
				
				if (power >= 0 && power < 10000)
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
						
						if (normalizedPower > 1.0)
							normalizedPower = 1.0;
						else if (normalizedPower < 0.0)
							normalizedPower = 0.0;
						
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
	}
}

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	PowerMeterSensor * sensor = [objectController content];
	
	if ([sensor isKindOfClass:[PowerMeterSensor class]])
	{
		NSRect bounds = [self bounds];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:[sensor identifier] event:@"device"];
		
		NSString * name = [sensor name];

		[self drawChartForEvents:events];
		
		Event * lastEvent = nil;
		
		if ([events count] > 0)
		{
			name = [NSString stringWithFormat:@"%@ (Range: %0.0fW - %0.0fW)", name, minPower, maxPower];
			
			lastEvent = [events lastObject];
			
			NSNumber * lastLevel = [lastEvent value];
			
			NSString * desc = [NSString stringWithFormat:@"Current Power Draw: %@W", lastLevel];;
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
