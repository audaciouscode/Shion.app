//
//  UpdateDeviceCommand.m
//  Shion
//
//  Created by Chris Karr on 3/4/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "UpdateDeviceCommand.h"
#import "DeviceDictionary.h"

@implementation UpdateDeviceCommand

- (id) initWithFrom:(NSString *) from to:(NSString *) to type:(NSString *) type id:(NSString *) identifier query:(NSString *) query
{
	if (self = [super initWithFrom:from to:to type:type id:identifier query:query])
	{
		_devices = nil;
		_dictionary = nil;
	}
	
	return self;
}

- (void) setDevices:(NSArray *) devices
{
	if (_devices != nil)
		[_devices release];
	
	_devices = [devices retain];
}

- (void) dealloc
{
	if (_devices != nil)
		[_devices release];

	[super dealloc];
}

- (void) setDictionary:(NSDictionary *) dictionary
{
	if (_dictionary != nil)
		[_dictionary release];
	
	_dictionary = [dictionary retain];
}

- (NSXMLElement *) responseElement
{
	NSXMLElement * done = [NSXMLElement elementWithName:@"done"];

	NSLog(@"VALUES = %@", _dictionary);

	NSMutableArray * keys = [NSMutableArray arrayWithArray:[_dictionary allKeys]];
	[keys removeObject:@"name"];
	[keys removeObject:@"address"];

	NSEnumerator * iter = [_devices objectEnumerator];
	DeviceDictionary * device = nil;
	while (device = [iter nextObject])
	{
		if ([[device valueForKey:SHION_NAME] isEqual:[_dictionary valueForKey:@"name"]] && 
			[[device valueForKey:SHION_ADDRESS] isEqual:[_dictionary valueForKey:@"address"]])
		{
			NSEnumerator * keyIter = [keys objectEnumerator];
			NSString * key = nil;
			while (key = [keyIter nextObject])
			{
				id value = [_dictionary valueForKey:key];
				
				if ([key isEqual:@"level"])
					value = [NSNumber numberWithFloat:[value floatValue]];
				
				[device setValue:value forKey:key];
			}
		}
	}
	
	return done;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	


@end
