//
//  ApertureSensorView.m
//  Shion
//
//  Created by Chris Karr on 5/22/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ApertureSensorView.h"

#import "ApertureSensor.h"
#import "EventManager.h"
#import "Event.h"

@implementation ApertureSensorView

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	ApertureSensor * sensor = [objectController content];
	
	if ([sensor isKindOfClass:[ApertureSensor class]])
	{
		NSRect bounds = [self bounds];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:[sensor identifier]];
		
		NSString * name = [sensor name];
		
		[self drawChartForEvents:events];
		
		Event * lastEvent = nil;
		
		if ([events count] > 0)
			lastEvent = [events lastObject];
		
		NSString * desc = @"Unknown Status";
		NSColor * color = [NSColor whiteColor];
		
		NSNumber * lastLevel = [lastEvent value];
		
		if (lastLevel != nil)
		{		
			if ([lastLevel intValue] == 0)
				desc = @"Aperture Closed";
			else
			{
				color = [self primaryColorForObject:sensor];
				desc = @"Aperture Open";
			}
		}
		
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

@end
