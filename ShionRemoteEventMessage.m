//
//  ShionRemoteEventMessage.m
//  Shion
//
//  Created by Chris Karr on 10/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Shion/ASThermostatDevice.h>

#import "Shion.h"
#import "DeviceDictionary.h"

#import "ShionRemoteEventMessage.h"
#import "AppDelegate.h"

@implementation ShionRemoteEventMessage

- (id) initWithFrom:(NSString *) from to:(NSString *) to type:(NSString *) type id:(NSString *) identifier query:(NSString *) query eventDictionary:(NSDictionary *) dict
{
	if (self = [super initWithFrom:from to:to type:type id:identifier query:query])
		eventDict = [dict retain];
	
	return self;
	
}

- (void) dealloc
{
	if (eventDict != nil)
		[eventDict release];
	
	[super dealloc];
}

- (NSXMLElement *) responseElement
{
//	AppDelegate * delegate = [NSApp delegate];
	NSArray * devices = nil; // [delegate systemPropertyForName:@"devices"];
	
	NSXMLElement * devicesMessage = [NSXMLElement elementWithName:@"event"];
	[devicesMessage addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:remote-control"]];
	
	NSString * cmdAddress = [[eventDict valueForKey:DEVICE_ADDRESS] lowercaseString];
	
	NSEnumerator * iter = [devices objectEnumerator];
	DeviceDictionary * device = nil;
	
	while (device = [iter nextObject])
	{
		NSString * address = [[device valueForKey:SHION_ADDRESS] lowercaseString];
		
		if ([cmdAddress isEqual:address])
		{
			NSString * type = [device valueForKey:SHION_TYPE];
			NSString * name = [device valueForKey:SHION_NAME];
			NSString * address = [device valueForKey:SHION_ADDRESS];

			NSXMLElement * deviceElement = [NSXMLElement elementWithName:@"device"];
			[deviceElement addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:name]];
			[deviceElement addAttribute:[NSXMLNode attributeWithName:@"address" stringValue:address]];
			
			[devicesMessage addChild:deviceElement];
			 
			if ([type isEqual:SENSOR])
			{
				NSNumber * level = [eventDict valueForKey:DEVICE_STATE];

				if (level == nil)
					return nil;
				else 
				{
					NSString * model = [device valueForKey:SHION_MODEL];

					if (model != nil && [model rangeOfString:@"Door"].location != NSNotFound)
					{
						[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"aperture-sensor"]];
						
						if ([level unsignedCharValue] > 0)
						{
							NSXMLElement * open = [NSXMLElement elementWithName:@"open"];
							[deviceElement addChild:open];
						}
						else
						{
							NSXMLElement * closed = [NSXMLElement elementWithName:@"closed"];
							[deviceElement addChild:closed];
						}
					}
					else 
					{
						[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"motion-sensor"]];
						
						if ([level unsignedCharValue] > 0)
						{
							NSXMLElement * motion = [NSXMLElement elementWithName:@"motion"];
							[deviceElement addChild:motion];
						}
						else
						{
							NSXMLElement * noMotion = [NSXMLElement elementWithName:@"no-motion"];
							[deviceElement addChild:noMotion];
						}
					}
				}
			}
			else if ([type isEqual:TOGGLE_DEVICE])
			{
				NSNumber * level = [eventDict valueForKey:DEVICE_STATE];
				
				if (level == nil)
					return nil;
				else 
				{
					[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"toggle"]];

					if ([level unsignedCharValue] > 0)
						[deviceElement addChild:[NSXMLElement elementWithName:@"on"]];
					else
					{
						NSXMLElement * off = [NSXMLElement elementWithName:@"off"];
						[deviceElement addChild:off];
					}
				}
			}
			else if ([type isEqual:CONTINUOUS_DEVICE])
			{
				NSNumber * level = [eventDict valueForKey:DEVICE_STATE];
				
				if (level == nil)
					return nil;
				else 
				{
					[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"continuous"]];
					
					unsigned int normalizedLevel = ([level unsignedIntValue] + 1) / 32;
					NSXMLElement * levelElement = [NSXMLElement elementWithName:@"level"];
					[levelElement addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[NSString stringWithFormat:@"%d", normalizedLevel]]];
					[deviceElement addChild:levelElement];
				}
			}
			else if ([type isEqual:THERMOSTAT_DEVICE])
			{
				[deviceElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"thermostat"]];

				NSNumber * mode = [eventDict valueForKey:THERMOSTAT_MODE];
				
				if (mode != nil)
				{
					NSString * modeString = [NSString stringWithFormat:@"Unknown Mode (%d)", [mode intValue]];
					
					if ([mode intValue] == 0)
						modeString = @"Off";
					else if ([mode intValue] == 1)
						modeString = @"Heat";
					else if ([mode intValue] == 2)
						modeString = @"Cool";
					else if ([mode intValue] == 3)
						modeString = @"Auto";
					else if ([mode intValue] == 4)
						modeString = @"Fan";
					else if ([mode intValue] == 5)
						modeString = @"Program";
					else if ([mode intValue] == 6)
						modeString = @"Program Heat";
					else if ([mode intValue] == 7)
						modeString = @"Program Cool";
					
					NSXMLElement * modeElement = [NSXMLElement elementWithName:@"mode"];
					[modeElement addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:modeString]];
					[deviceElement addChild:modeElement];
				}

				NSNumber * temp = [eventDict valueForKey:THERMOSTAT_TEMPERATURE];

				if (temp != nil)
				{
					NSXMLElement * tempElement = [NSXMLElement elementWithName:@"temperature"];
					[tempElement addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[temp description]]];
					[deviceElement addChild:tempElement];
				}

				NSNumber * heat = [eventDict valueForKey:THERMOSTAT_HEAT_POINT];
				
				if (heat != nil)
				{
					if ([heat unsignedCharValue] != 0xff)
					{
						NSXMLElement * heatElement = [NSXMLElement elementWithName:@"heat-point"];
						[heatElement addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[heat description]]];
						[deviceElement addChild:heatElement];
					}
					else
					{
						NSXMLElement * heatElement = [NSXMLElement elementWithName:@"heat-point"];
						[heatElement addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:@"disabled"]];
						[deviceElement addChild:heatElement];
					}
				}

				NSNumber * cool = [eventDict valueForKey:THERMOSTAT_COOL_POINT];
				
				if (cool != nil)
				{
					if ([cool unsignedCharValue] != 0xff)
					{
						NSXMLElement * coolElement = [NSXMLElement elementWithName:@"cool-point"];
						[coolElement addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[cool description]]];
						[deviceElement addChild:coolElement];
					}
					else
					{
						NSXMLElement * coolElement = [NSXMLElement elementWithName:@"cool-point"];
						[coolElement addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:@"disabled"]];
						[deviceElement addChild:coolElement];
					}
				}
			}
		}
	}
	
	return devicesMessage;
}

- (NSXMLElement *) errorElement
{
	return nil;
}	

+ (NSXMLElement *) elementForDevice:(NSDictionary *) device
{
	NSXMLElement * deviceElement = [NSXMLElement elementWithName:@"device"];
	
	return deviceElement;
}

@end
