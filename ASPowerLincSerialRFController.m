//
//  ASPowerLincSerialRFController.m
//  Shion Framework
//
//  Created by Chris Karr on 10/20/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "ASPowerLincSerialRFController.h"

#import "ASX10Address.h"

@implementation ASPowerLincSerialRFController

+ (ASPowerLincSerialRFController *) controllerWithPath:(NSString *) path;
{
	ASPowerLincSerialRFController * controller = nil;
	
	controller = [[ASPowerLincSerialRFController alloc] initWithPath:path];
	
	return [controller autorelease];
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value;
{
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isKindOfClass:[ASX10Address class]])
		return nil;
	
	return [super commandForDevice:device kind:commandKind value:value];
}

- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind
{
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASX10Address class]])
		return nil;

	return [super commandForDevice:device kind:commandKind];
}
		
@end
