//
//  GarageHawkView.m
//  Shion
//
//  Created by Chris Karr on 10/8/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "GarageHawkView.h"

#import "EventManager.h"
#import "GarageHawk.h"


@implementation GarageHawkView

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	GarageHawk * hawk = [objectController content];
	
	if ([hawk isKindOfClass:[GarageHawk class]])
	{
		NSRect bounds = [self bounds];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:[hawk identifier]];
		
		NSString * name = [hawk name];
		
		[self drawChartForEvents:events];
		
		NSManagedObject * lastEvent = nil;
		
		if ([events count] > 0)
			lastEvent = [events lastObject];
		
		NSString * desc = @"Unknown Status";
		NSColor * color = [self primaryColorForObject:hawk];

		NSString * lastLevel = [lastEvent valueForKey:@"value"];
		
		if (lastLevel != nil)
		{		
			if ([lastLevel intValue] == 0)
			{
				desc = @"Closed";
				color = [NSColor whiteColor];
			}
			else if ([lastLevel intValue] < 128)
				desc = @"Closing";
			else if ([lastLevel intValue] < 192)
				desc = @"Open";
			else if ([lastLevel intValue] < 255)
				desc = @"Unknown";
			else
				desc = @"Experiencing Errors";
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


