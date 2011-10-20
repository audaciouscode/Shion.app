//
//  Sensor.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Sensor.h"


@implementation Sensor

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Generic Sensor" forKey:TYPE];
	}
	
	return self;
}

- (BOOL) checksStatus
{
	return NO;
}

@end
