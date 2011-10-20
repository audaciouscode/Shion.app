//
//  ShionRemoteDevicesMessage.m
//  Shion
//
//  Created by Chris Karr on 10/14/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "Shion.h"

#import "DeviceDictionary.h"

#import "ShionRemoteDevicesMessage.h"
#import "AppDelegate.h"

@implementation ShionRemoteDevicesMessage

- (NSXMLElement *) responseElement
{
	// AppDelegate * delegate = [NSApp delegate];
	NSArray * devices = nil; // [delegate systemPropertyForName:@"devices"];
	
	NSXMLElement * devicesMessage = [NSXMLElement elementWithName:@"devices"];
	[devicesMessage addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:remote-control"]];
	
	NSEnumerator * iter = [devices objectEnumerator];
	NSDictionary * dict = nil;
		
	while (dict = [iter nextObject])
		[devicesMessage addChild:[ShionRemoteDevicesMessage elementForDevice:dict]];
	
	return devicesMessage;
}

- (NSXMLElement *) errorElement
{
	return nil;
}	

+ (NSXMLElement *) elementForDevice:(NSDictionary *) device
{
	NSXMLElement * deviceElement = [NSXMLElement elementWithName:@"device"];
	
	NSEnumerator * keyIter = [[NSArray arrayWithObjects:@"model", @"name", @"address", nil] objectEnumerator];
	NSString * key = nil;
	
	while (key = [keyIter nextObject])
	{
		id value = [device valueForKey:key];
		
		if (value != nil)
			[deviceElement addAttribute:[NSXMLNode attributeWithName:key stringValue:[value description]]];
	}
	
	NSString * type = [device valueForKey:SHION_TYPE];
	
	if ([type isEqual:TOGGLE_DEVICE])
	{
		[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"toggle"]];

		NSNumber * state = [device valueForKey:TOGGLE_STATE];
		
		if (state != nil)
		{
			if ([state unsignedIntValue] > 0)
				[deviceElement addChild:[NSXMLElement elementWithName:@"on"]];
			else
				[deviceElement addChild:[NSXMLElement elementWithName:@"off"]];
		}
	}
	else if ([type isEqual:CONTINUOUS_DEVICE])
	{
		[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"continuous"]];
		
		NSNumber * level = [device valueForKey:TOGGLE_STATE];
		
		if (level != nil)
		{
			unsigned int normalizedLevel = ([level unsignedIntValue] + 1) / 32;
			NSXMLElement * levelElement = [NSXMLElement elementWithName:@"level"];
			[levelElement addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[NSString stringWithFormat:@"%d", normalizedLevel]]];
			[deviceElement addChild:levelElement];
		}
	}
	else if ([type isEqual:SENSOR])
	{
		NSString * model = [device valueForKey:SHION_MODEL];
		
		if (model != nil && [model rangeOfString:@"Door"].location != NSNotFound)
		{
			[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"aperture-sensor"]];
			
			[deviceElement addChild:[NSXMLElement elementWithName:@"todo-last-states"]];
		}
		else 
		{
			[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"motion-sensor"]];
			
			[deviceElement addChild:[NSXMLElement elementWithName:@"todo-last-states"]];
		}
	}
	else
	{
		[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"unsupported"]];
	}

	return deviceElement;
}

@end
