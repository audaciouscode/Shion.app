//
//  ASSetRampRateCommand.m
//  Shion Framework
//
//  Created by Chris Karr on 8/19/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "ASSetRampRateCommand.h"


@implementation ASSetRampRateCommand

- (void) setRate:(NSNumber *) newRate
{
	if (rate != nil)
		[rate release];
	
	rate = [newRate retain];
}

- (NSNumber *) rate
{
	return rate;
}

- (void) dealloc
{
	if (rate != nil)
		[rate release];
	
	[super dealloc];
}


@end
