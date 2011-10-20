//
//  SystemStatusCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "SystemStatusCommand.h"
#import "AppDelegate.h"

#import "EventManager.h"

@implementation SystemStatusCommand

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];

	NSString * string = @"Network status is unknown.";

	NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:@"Controller"];
	
	Event * lastEvent = nil;
	
	if ([events count] > 0)
		lastEvent = [events lastObject];
	
	NSNumber * lastLevel = [lastEvent value];
	
	if (lastLevel != nil)
	{		
		float f = [lastLevel floatValue];
		
		string = [NSString stringWithFormat:@"Network status: %0.0f%%.", ((f * 100) / 255)];
	}
	
	[result setValue:string forKey:CMD_RESULT_DESC];
	[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
	
	return result;
}

@end
