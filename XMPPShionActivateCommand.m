//
//  XMPPShionActivateCommand.m
//  Shion
//
//  Created by Chris Karr on 8/11/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "XMPPShionActivateCommand.h"
#import "AppDelegate.h"
#import "Shion.h"
#import "DeviceDictionary.h"

@implementation XMPPShionActivateCommand

- (NSXMLElement *) responseElement
{
	NSXMLElement * command = [NSXMLElement elementWithName:@"command"];
	[command addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/commands"]];
	
	if (session == nil)
		session = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSinceReferenceDate]];
	 
	NSString * deviceId = [self valueForKey:@"device_id"];

	//AppDelegate * delegate = [NSApp delegate];
	
	NSArray * devices = nil; // [delegate systemPropertyForName:@"devices"];
	
	NSString * status = @"executing";

	if (deviceId != nil)
	{
		NSString * title = @"No matching devices found for activation.";
		
		NSEnumerator * deviceIter = [devices objectEnumerator];
		DeviceDictionary * device = nil;
		while (device = [deviceIter nextObject])
		{
			NSString * deviceString = [NSString stringWithFormat:@"%@.%@", [device valueForKey:SHION_NAME], [device valueForKey:SHION_ADDRESS]];
			
			if ([deviceId isEqual:deviceString])
			{
				[device activate:nil];
				
				NSXMLElement * note = [NSXMLElement elementWithName:@"note"];
				[note setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"info" forKey:@"type"]];
				
				title = [NSString stringWithFormat:@"%@ activated.", [device valueForKey:SHION_NAME]];
				
				[note setStringValue:title];
				
				[command addChild:note];
			}
		}
		
		status = @"completed";

		NSXMLElement * x = [NSXMLElement elementWithName:@"x"];
		[x addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"jabber:x:data"]];
		[x setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"form" forKey:@"type"]];
		
		NSXMLElement * field = [NSXMLElement elementWithName:@"field"];
		[field setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"fixed", @"type", nil]];
		
		NSXMLElement * value = [NSXMLElement elementWithName:@"value"];
		[value setStringValue:title];
		
		[field addChild:value];
		[x addChild:field];
		[command addChild:x];
	}
	else
	{	
		NSXMLElement * actions = [NSXMLElement elementWithName:@"actions"];
		[actions setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"complete" forKey:@"execute"]];
		
		NSXMLElement * next = [NSXMLElement elementWithName:@"complete"];
		[actions addChild:next];

		[command addChild:actions];
		
		NSXMLElement * x = [NSXMLElement elementWithName:@"x"];
		[x addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"jabber:x:data"]];
		[x setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"form" forKey:@"type"]];
		
		NSXMLElement * title = [NSXMLElement elementWithName:@"title"];
		[title setStringValue:@"Activate Device"];
		[x addChild:title];

		NSXMLElement * instructions = [NSXMLElement elementWithName:@"instructions"];
		[instructions setStringValue:@"Please select a device from list below to activate."];
		[x addChild:instructions];
		
		NSXMLElement * field = [NSXMLElement elementWithName:@"field"];
		[field setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"device_id", @"var", @"Devices", @"label", @"list-single", @"type", nil]];
		
		NSEnumerator * deviceIter = [devices objectEnumerator];
		DeviceDictionary * device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([[device valueForKey:SHION_TYPE] isEqual:CONTINUOUS_DEVICE] || [[device valueForKey:SHION_TYPE] isEqual:TOGGLE_DEVICE])
			{
				NSXMLElement * option = [NSXMLElement elementWithName:@"option"];
				[option setAttributesAsDictionary:[NSDictionary dictionaryWithObject:[device valueForKey:SHION_NAME] forKey:@"label"]];
				
				NSXMLElement * value = [NSXMLElement elementWithName:@"value"];
				[value setStringValue:[NSString stringWithFormat:@"%@.%@", [device valueForKey:SHION_NAME], [device valueForKey:SHION_ADDRESS]]];
				
				[option addChild:value];
				[field addChild:option];
			}
		}
		
		[x addChild:field];
		[command addChild:x];
	}
	
	[command setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:session, @"sessionid", @"activate", @"node", status, @"status", nil]];
		
	return command;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
