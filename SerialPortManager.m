//
//  SerialPortManager.m
//  Shion
//
//  Created by Chris Karr on 1/2/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "SerialPortManager.h"
#import "AMSerialPortList.h"
#import "AMSerialPort.h"

#import <Shion/ASCM11AController.h>
#import <Shion/ASPowerLinc2412Controller.h>

#define SAVED_PORT_NAME @"saved_port"
#define SAVED_MODEL @"saved_model"

#define USE_COMM_PORT @"use_comm_port"

#define SERIAL_PROPERTIES @"serial_properties"

#define CM11A_STRING @"CM11A (and compatible)"
#define PLM_STRING @"PowerLinc Modem (2412U/S)"

@implementation SerialPortManager

- (void) loadProperties
{
	NSDictionary * serialProperties = [[NSUserDefaults standardUserDefaults] valueForKey:SERIAL_PROPERTIES];
	
	if (serialProperties != nil)
		properties = [[NSMutableDictionary dictionaryWithDictionary:serialProperties] retain];
	else
		properties = [[NSMutableDictionary dictionary] retain];
}

- (void) save
{
	[properties setValue:[[[self valueForKey:MODELS] selectedObjects] lastObject] forKey:SAVED_MODEL];
	[properties setValue:[[[[self valueForKey:PORTS] selectedObjects] lastObject] name] forKey:SAVED_PORT_NAME];

	NSMutableDictionary * saveDictionary = [NSMutableDictionary dictionaryWithDictionary:properties];

	[saveDictionary removeObjectForKey:MODELS];
	[saveDictionary removeObjectForKey:PORTS];
	
	[[NSUserDefaults standardUserDefaults] setValue:saveDictionary forKey:SERIAL_PROPERTIES];
}

- (ASDeviceController *) getController
{
	if ([[[[self valueForKey:MODELS] selectedObjects] lastObject] isEqual:NSLocalizedString(CM11A_STRING, nil)])
		{
			AMSerialPort * port = [[[self valueForKey:PORTS] selectedObjects] lastObject];
			
			ASCM11AController * controller = [ASCM11AController controllerWithPath:[port bsdPath]];
			
			if (controller != nil)
				return controller;
		}
		else if ([[[[self valueForKey:MODELS] selectedObjects] lastObject] isEqual:NSLocalizedString(PLM_STRING, nil)])
		{
			NSLog(@"PLM");
			
			AMSerialPort * port = [[[self valueForKey:PORTS] selectedObjects] lastObject];
			
			ASPowerLinc2412Controller * controller = [ASPowerLinc2412Controller controllerWithPath:[port bsdPath]];

			NSLog(@"PLM controller = %@", controller);
			
			if (controller != nil)
				return controller;
		}

	return nil;
}

- (id) valueForKey:(NSString *) key
{
	if (properties == nil)
		[self loadProperties];

	NSObject * value = [properties valueForKey:key];
	
	if (value == nil)
	{
		if ([key isEqual:MODELS])
		{
			NSArrayController * controller = [[NSArrayController alloc] init];
			[controller addObjects:[NSArray arrayWithObjects:NSLocalizedString(CM11A_STRING, nil), nil]];
			[controller addObjects:[NSArray arrayWithObjects:NSLocalizedString(PLM_STRING, nil), nil]];
			[controller setAutomaticallyPreparesContent:YES];

			if ([properties valueForKey:SAVED_MODEL] != nil)
				[controller setSelectedObjects:[NSArray arrayWithObject:[properties valueForKey:SAVED_MODEL]]];

			value = [controller autorelease];
		}
		else if ([key isEqual:PORTS])
		{
			NSArrayController * controller = [[NSArrayController alloc] init];
			NSArray * ports = [[AMSerialPortList sharedPortList] serialPorts];
			[controller addObjects:ports];
			[controller setAutomaticallyPreparesContent:YES];

			if ([properties valueForKey:SAVED_PORT_NAME] != nil)
			{
				NSEnumerator * iter = [ports objectEnumerator];
				AMSerialPort * port = nil;

				while (port = [iter nextObject])
				{	
					if ([[port name] isEqual:[self valueForKey:SAVED_PORT_NAME]])
						[controller setSelectedObjects:[NSArray arrayWithObject:port]];
				}	
			}
			
			value = [controller autorelease];
		}
		
		if (value != nil)
			[properties setValue:value forKey:key];
	}
	
	return value;
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	if (properties == nil)
		[self loadProperties];

	[self willChangeValueForKey:key];
	
	if (value != nil)
		[properties setValue:value forKey:key];
	else
		[properties removeObjectForKey:key];

	[self didChangeValueForKey:key];
}

@end
