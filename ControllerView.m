//
//  ControllerView.m
//  Shion
//
//  Created by Chris Karr on 4/13/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ControllerView.h"

#import "Controller.h"
#import "EventManager.h"

@implementation ControllerView

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	Controller * controller = [objectController content];
	
	if ([controller isKindOfClass:[Controller class]])
	{
		NSRect bounds = [self bounds];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:@"Controller"];
		
		NSString * name = [controller name];
		
		[self drawChartForEvents:events];
		
		Event * lastEvent = nil;
		
		if ([events count] > 0)
			lastEvent = [events lastObject];
		
		NSString * desc = @"Network status: Unknown";
		
		NSColor * color = [NSColor whiteColor];
		
		NSNumber * lastLevel = [lastEvent value];
		
		if (lastLevel != nil)
		{		
			float f = [lastLevel floatValue];
			
			if (f >= 0)
				desc = [NSString stringWithFormat:@"Network status: %0.0f%%", ((f * 100) / 255)];
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
