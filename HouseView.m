//
//  HouseView.m
//  Shion
//
//  Created by Chris Karr on 4/15/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "HouseView.h"

#import "House.h"
#import "EventManager.h"

@implementation HouseView

- (void) drawChartForDevices:(NSArray *) devices drawn:(unsigned int *) count;
{
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
			
			NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:identifier];
			
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
			
			NSString * cacheKey = [NSString stringWithFormat:@"%@-%f-%f", identifier, startInterval, latestInterval];
			
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
				
				
/*				NSEnumerator * eventIter = [chartEvents objectEnumerator];
				Event * event = nil;
				while ((event = [eventIter nextObject]))
				{
					if ([[event date] timeIntervalSince1970] > startInterval)
						[timeline setValue:[[event value] floatValue] atInterval:[[event date] timeIntervalSince1970]];
				} */
				
				[[[EventManager sharedInstance] timelineCache] setValue:timeline forKey:cacheKey];
				
				[timeline release];
			}
			
			NSString * desc = [device name];
			
			NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
			[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:11] forKey:NSFontAttributeName];
			[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			
			NSSize descSize = [desc sizeWithAttributes:attributes];
			NSPoint point = NSMakePoint(timeRect.origin.x + timeRect.size.width - descSize.width, timeRect.origin.y - 20);
			[desc drawAtPoint:point withAttributes:attributes];
			
			[self drawTimeline:timeline start:(startInterval + daySeconds) end:latestInterval inRect:timeRect object:device];
			
			*count += 1;
			
			[context deleteObject:e];
		}
	}
}

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	House * house = [[objectController selectedObjects] lastObject];
	
	if ([house isKindOfClass:[House class]])
	{
		NSRect bounds = [self bounds];
		NSString * name = [house name];
		
		NSArray * devices = [house devices];
		
		unsigned int count = 0;
		
		[self drawChartForDevices:devices drawn:&count];
		
		NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
		[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:18] forKey:NSFontAttributeName];
		[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		NSSize titleSize = [name sizeWithAttributes:attributes];
		NSPoint point = NSMakePoint(bounds.size.width - titleSize.width - 10, bounds.size.height - titleSize.height - 5);
		[name drawAtPoint:point withAttributes:attributes];
		
		[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:12] forKey:NSFontAttributeName];
		
		NSString * desc = [NSString stringWithFormat:@"%d devices (%d visible)", [devices count], count]; 
		
		if (count == [devices count])
			desc = [NSString stringWithFormat:@"%d devices", [devices count]];
		
		NSSize descSize = [desc sizeWithAttributes:attributes];
		point = NSMakePoint(bounds.size.width - descSize.width - 10, bounds.size.height - titleSize.height - descSize.height - 5);
		[desc drawAtPoint:point withAttributes:attributes];
	}
}

@end
