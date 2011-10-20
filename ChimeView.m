//
//  ChimeView.m
//  Shion
//
//  Created by Chris Karr on 4/15/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ChimeView.h"
#import "Chime.h"
#import "EventManager.h"

@implementation ChimeView

- (void)drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	Chime * chime = [objectController content];
	
	if ([chime isKindOfClass:[Chime class]])
	{
		NSRect bounds = [self bounds];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:[chime identifier]];
		
		NSString * name = [chime name];
		
		[self drawChartForEvents:events];
		
		Event * lastEvent = nil;
		
		if ([events count] > 0)
			lastEvent = [events lastObject];
		
		NSString * desc = @"Never Rang";
		NSColor * color = [NSColor whiteColor];
		
		NSDate * date = [lastEvent date];
		
		if (date != nil)
		{		
			[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
			NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
			[formatter setTimeStyle:kCFDateFormatterMediumStyle];
			[formatter setDateStyle:kCFDateFormatterMediumStyle];

			desc = [NSString stringWithFormat:@"Last rang at %@", [formatter stringFromDate:date]];
			color = [self primaryColorForObject:chime];
			
			[formatter release];
		}
		
		NSMutableDictionary * attributes = [NSMutableDictionary dictionary];
		[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:18] forKey:NSFontAttributeName];
		[attributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];

		NSSize titleSize = [name sizeWithAttributes:attributes];
		NSPoint point = NSMakePoint(bounds.size.width - titleSize.width - 10, bounds.size.height - titleSize.height - 5);
		[name drawAtPoint:point withAttributes:attributes];
		
		[attributes setValue:[NSFont fontWithName:@"Lucida Grande" size:12] forKey:NSFontAttributeName];
		[attributes setValue:color forKey:NSForegroundColorAttributeName];

		NSSize descSize = [desc sizeWithAttributes:attributes];
		point = NSMakePoint(bounds.size.width - descSize.width - 10, bounds.size.height - descSize.height - titleSize.height - 5);
		[desc drawAtPoint:point withAttributes:attributes];
		
		
	}
}

@end
