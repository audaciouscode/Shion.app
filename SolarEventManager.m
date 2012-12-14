//
//  SolarEventManager.m
//  Shion
//
//  Created by Chris Karr on 5/15/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "SolarEventManager.h"


@implementation SolarEventManager

+ (float) fractionalYear
{
	NSCalendarDate * now = [NSCalendarDate date];
	
	return ((2 * M_PI) / 365) * (((float) [now dayOfYear]) - 1 + ((((float) [now hourOfDay]) - 12) / 24));
}

+ (float) eqTime
{
	float fractYear = [SolarEventManager fractionalYear];
	
	float et = 229.18 * (0.000075 + (0.001868 * cos (fractYear)) - (0.032077 * sin (fractYear)) - 
						   (0.014615 * cos (2 * fractYear)) - (0.040849 * sin (2 * fractYear)));
	
	return et;
}

+ (float) solarDeclination
{
	float fractYear = [SolarEventManager fractionalYear];
	
	float decl = 0.006918 - (0.399912 * cos (fractYear)) + (0.070257 * sin (fractYear)) - (0.006758 * cos (2 * fractYear)) +
	(0.000907 * sin (2 * fractYear)) - (0.002697 * cos (3 * fractYear)) + (0.00148 * sin (3 * fractYear));
	
	return decl;
}

+ (float) radiansForDegrees:(float) degrees
{
	return (M_PI / 180.0) * degrees;
}

+ (float) degreesForRadians:(float) rads
{
	return (180 / M_PI) * rads;
}

+ (float) hourAngleForLatitude:(float) lat longitude:(float) lon
{
	float decl = [SolarEventManager solarDeclination];
	
	float ha =  acos ((cos ([SolarEventManager radiansForDegrees:90.833]) / (cos ([SolarEventManager radiansForDegrees:lat]) * cos (decl))) - 
						(tan ([SolarEventManager radiansForDegrees:lat]) * tan (decl)));
	
	return ha;
}

+ (float) sunriseForLatitude:(float) lat longitude:(float) lon
{
	return 720 + (4 * (lon - [SolarEventManager degreesForRadians:[SolarEventManager hourAngleForLatitude:lat longitude:lon]])) - [SolarEventManager eqTime];
}

+ (float) sunsetForLatitude:(float) lat longitude:(float) lon
{
	return 720 + (4 * (lon + [SolarEventManager degreesForRadians:[SolarEventManager hourAngleForLatitude:lat longitude:lon]])) - [SolarEventManager eqTime];
}

+ (float) solarNoonForLatitude:(float) lat longitude:(float) lon
{
	return 720 + (4 * lon) - [SolarEventManager eqTime];
}

+ (int) sunrise
{
	MachineLocation * location =  malloc (sizeof (MachineLocation));
	
	ReadLocation (location);
	
	[NSTimeZone resetSystemTimeZone];
	NSTimeZone * myTimeZone = [NSTimeZone systemTimeZone];
	
	float latitude = 90 * FractToFloat (location->latitude);
	float longitude = -90 * FractToFloat (location->longitude);

	free(location);

	return ((int) [SolarEventManager sunriseForLatitude:latitude longitude:longitude] + ([myTimeZone secondsFromGMT] / 60));
}

+ (int) sunset
{
	MachineLocation * location =  malloc (sizeof (MachineLocation));
	
	ReadLocation (location);
	
	[NSTimeZone resetSystemTimeZone];
	NSTimeZone * myTimeZone = [NSTimeZone systemTimeZone];
	
	float latitude = 90 * FractToFloat (location->latitude);
	float longitude = -90 * FractToFloat (location->longitude);
	
	free(location);
	
	return ((int) [SolarEventManager sunsetForLatitude:latitude longitude:longitude] + ([myTimeZone secondsFromGMT] / 60));
}

@end
