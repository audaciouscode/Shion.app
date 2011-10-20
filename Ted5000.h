//
//  Ted5000.h
//  Shion
//
//  Created by Chris Karr on 7/9/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Device.h"
#import "PowerMeterSensor.h"

#define TED_5000 @"TED 5000"

@interface Ted5000 : PowerMeterSensor
{
	NSMutableData * buffer;
	
	float lastUsage;
	float lastTotal;
}

@end
