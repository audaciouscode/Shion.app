//
//  LampView.m
//  Shion
//
//  Created by Chris Karr on 4/12/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "LampView.h"

#import "Lamp.h"
#import "EventManager.h"

@implementation LampView

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	Lamp * lamp = [objectController content];
	
	if ([lamp isKindOfClass:[Lamp class]])
	{
		NSRect bounds = [self bounds];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:[lamp identifier]];
		
		NSString * name = [lamp name];
		
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
				desc = @"Off: 0%";
			else if ([lastLevel intValue] == 255)
			{
				color = [self primaryColorForObject:lamp];
				desc = @"Full Strength: 100%";
			}
			else
			{
				float percentage = (([lastLevel floatValue] + 1) / 256) * 100;
				
				color = [self primaryColorForObject:lamp];
				desc = [NSString stringWithFormat:@"Partial Strength: %0.0f%%", percentage];
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
