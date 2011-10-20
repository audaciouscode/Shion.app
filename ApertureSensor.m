//
//  ApertureSensor.m
//  Shion
//
//  Created by Chris Karr on 4/6/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ApertureSensor.h"
#import "EventManager.h"

@implementation ApertureSensor

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Aperture Sensor" forKey:TYPE];
	}
	
	return self;
}

- (BOOL) open
{
	Event * e = [[EventManager sharedInstance] lastUpdateForIdentifier:[self identifier] event:@"device"];
	
	if (e != nil)
	{
		if ([[e value] intValue] > 0)
			return YES;
	}
	
	return NO;
}


@end
