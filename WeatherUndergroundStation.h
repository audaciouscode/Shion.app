//
//  WeatherUndergroundStation.h
//  Shion
//
//  Created by Chris Karr on 7/30/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WU_STATION @"Weather Underground Station"
#define IS_INDOORS @"is_indoors"

#import "Device.h"

@interface WeatherUndergroundStation : Device
{
	NSMutableData * buffer;
}

- (NSNumber *) temperature;

@end
