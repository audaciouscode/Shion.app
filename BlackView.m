//
//  BlackView.m
//  Shion
//
//  Created by Chris Karr on 3/10/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "BlackView.h"

#import "EventManager.h"

#import "Lamp.h"
#import "Appliance.h"
#import "MotionSensor.h"
#import "PowerSensor.h"
#import "Thermostat.h"
#import "Lock.h"
#import "PowerMeterSensor.h"
#import "WeatherUndergroundStation.h"
#import "GarageHawk.h"

#import "GroupView.h"

@implementation BlackView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
	
    if (self) 
	{
        objectController = nil;
	}
	
    return self;
}

- (void) dealloc
{
	[refreshTimer release];
	
	[super dealloc];
}

- (void) awakeFromNib
{
	if (objectController != nil)
	{
		[objectController addObserver:self forKeyPath:@"selection" options:0 context:NULL];
		[objectController addObserver:self forKeyPath:@"content" options:0 context:NULL];
		[objectController addObserver:self forKeyPath:@"selection.last_update" options:0 context:NULL];
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self setNeedsDisplay:YES];

	if ([self isKindOfClass:[GroupView class]])
	{
		
	}
}
		
- (void)drawRect:(NSRect)dirtyRect 
{
	[[NSColor blackColor] setFill];
	
	NSBezierPath * path = [NSBezierPath bezierPathWithRect:[self bounds]];
	[path fill];
}

- (NSColor *) primaryColorForObject:(id) object
{
	if ([object isKindOfClass:[Lamp class]])
		return [NSColor colorWithCalibratedRed:1.000 green:0.678 blue:0.000 alpha:1.0];
	else if ([object isKindOfClass:[Appliance class]])
		return [NSColor colorWithCalibratedRed:0.000 green:0.314 blue:0.961 alpha:1.0];
	else if ([object isKindOfClass:[PowerSensor class]])
		return [NSColor colorWithCalibratedRed:0.000 green:0.314 blue:0.961 alpha:1.0];
	else if ([object isKindOfClass:[MotionSensor class]])
		return [NSColor colorWithCalibratedRed:0.725 green:0.961 blue:0.094 alpha:1.0];
	else if ([object isKindOfClass:[Thermostat class]] || [object isKindOfClass:[WeatherUndergroundStation class]])
		return [NSColor colorWithCalibratedRed:0.910 green:0.173 blue:0.047 alpha:1.0];
	else if ([object isKindOfClass:[PowerMeterSensor class]])
		return [NSColor colorWithCalibratedRed:0.996 green:0.678 blue:0.0 alpha:1.0];
	else if ([object isKindOfClass:[Lock class]])
		return [NSColor colorWithCalibratedRed:0.910 green:0.173 blue:0.047 alpha:1.0];
	else if ([object isKindOfClass:[GarageHawk class]])
		return [NSColor colorWithCalibratedRed:0.910 green:0.173 blue:0.047 alpha:1.0];
	else
		return [NSColor grayColor];
}

- (void) drawTimeline:(PresenceTimeline *) timeline start:(NSTimeInterval) start end:(NSTimeInterval) end inRect:(NSRect) rect object:(id) object
{
	[self drawTimeline:timeline start:start end:end inRect:rect object:object highlighted:NO];
}

- (void) drawTimeline:(PresenceTimeline *) timeline start:(NSTimeInterval) start end:(NSTimeInterval) end inRect:(NSRect) rect object:(id) object highlighted:(BOOL) highlight
{
	float height = rect.size.height - 10;
	
	if (highlight)
		[[NSColor blackColor] setStroke];
	else
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

- (void) drawTimeline:(PresenceTimeline *) timeline start:(NSTimeInterval) start end:(NSTimeInterval) end inRect:(NSRect) rect
{
	[self drawTimeline:timeline start:start end:end inRect:rect object:[objectController content]];
}
	 
- (void) drawChartForEvents:(NSArray *) events
{
	[self drawChartForEvents:events days:0];
}

- (void) drawChartForEvents:(NSArray *) events days:(int) days
{
	NSManagedObjectContext * context = [[EventManager sharedInstance] managedObjectContext];
	
	NSMutableArray * chartEvents = [NSMutableArray arrayWithArray:events];
	
	NSManagedObject * e = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:context];
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
					if (nextEvent != nil)
						[timeline setValue:[[thisEvent valueForKey:@"value"] floatValue] atInterval:thisTime duration:(nextTime - thisTime)];
					else
						[timeline setValue:[[thisEvent valueForKey:@"value"] floatValue] atInterval:thisTime];
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
		
/*		NSEnumerator * eventIter = [chartEvents objectEnumerator];
		Event * event = nil;
		while ((event = [eventIter nextObject]))
		{
			if ([[event date] timeIntervalSince1970] > startInterval)
				[timeline setValue:[[event value] floatValue] atInterval:[[event date] timeIntervalSince1970]];
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
			
		NSDate * date = [NSDate dateWithTimeIntervalSince1970:(startInterval - (60 * 60 * 24))];
			
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

@end
