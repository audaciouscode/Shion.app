//
//  ApplianceView.m
//  Shion
//
//  Created by Chris Karr on 4/12/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ApplianceView.h"

#import "Appliance.h"
#import "EventManager.h"


@implementation ApplianceView

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	Appliance * appliance = [objectController content];
	
	if ([appliance isKindOfClass:[Appliance class]])
	{
		NSRect bounds = [self bounds];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:[appliance identifier]];
		
		NSString * name = [appliance name];
		
		[self drawChartForEvents:events];
		
		NSManagedObject * lastEvent = nil;
		
		if ([events count] > 0)
			lastEvent = [events lastObject];
		
		NSString * desc = @"Unknown Status";
		NSColor * color = [NSColor whiteColor];
		
		NSString * lastLevel = [lastEvent valueForKey:@"value"];
		
		if (lastLevel != nil)
		{		
			if ([lastLevel intValue] == 0)
				desc = @"Off";
			else
			{
				color = [self primaryColorForObject:appliance];
				desc = @"On";
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
