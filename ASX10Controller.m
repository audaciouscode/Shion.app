//
//  ASX10Controller.m
//  Shion Framework
//
//  Created by Chris Karr on 3/31/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASX10Controller.h"
#import "ASX10Address.h"
#import "ASCommands.h"

@implementation ASX10Controller

- (BOOL) acceptsCommand: (ASCommand *) command;
{
	if ([command isMemberOfClass:[ASStatusCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASActivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDeactivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAggregateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASIncreaseCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDecreaseCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASChimeCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetLevelCommand class]])
		return YES;
	
	return NO;
}

- (void) processX10Message:(NSData *) message
{
	unsigned char * bytes = (unsigned char *) [message bytes];
	
	ShionLog (@"** Processing X10 message: %@", [self stringForData:message]);

	if ((bytes[0] & 0x01) == 0x01)
		currentX10Command = bytes[1];
	else
		currentX10Address = bytes[1];

	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	NSString * x10Address = [ASX10Address stringForAddress:currentX10Address];

	if ((currentX10Command & 0x0f) ==  X10_STATUS_ON_CODE)
	{
		[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
		[userInfo setValue:x10Address forKey:DEVICE_ADDRESS];
		[userInfo setObject:[NSNumber numberWithUnsignedInt:255] forKey:DEVICE_STATE];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
	}
	else if ((currentX10Command & 0x0f) == X10_STATUS_OFF_CODE)
	{
		[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
		[userInfo setValue:x10Address forKey:DEVICE_ADDRESS];
		[userInfo setObject:[NSNumber numberWithUnsignedInt:0] forKey:DEVICE_STATE];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
	}
	else 
	{
		NSString * command = [ASX10Address stringForCommand:currentX10Command];
		
		[userInfo setValue:x10Address forKey:X10_ADDRESS];
		[userInfo setValue:command forKey:X10_COMMAND];
		
		ShionLog (@"** Decoded X10 message: %@ %@", x10Address, command);

		[[NSNotificationCenter defaultCenter] postNotificationName:X10_COMMAND_NOTIFICATION object:nil userInfo:userInfo];
	}
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value
{
	if (commandKind == AS_SET_LEVEL)
	{
		ASSetLevelCommand * command = [[ASSetLevelCommand alloc] init];
		[command setLevel:((NSNumber *) value)];
		
		return [command autorelease];
	}
	
	return nil;
}
		 
- (unsigned char) xtenCommandByteForDevice:(ASDevice *)device command:(ASCommand *) command
{
	if ([command isMemberOfClass:[ASAllOffCommand class]])
		return 0x00;
	else if ([command isMemberOfClass:[ASAllLightsOffCommand class]])
		return 0x06;
	if ([command isMemberOfClass:[ASAllLightsOnCommand class]])
		return 0x01;
	else if ([command isMemberOfClass:[ASChimeCommand class]])
		return 0x02;
	else if ([command isMemberOfClass:[ASActivateCommand class]])
		return 0x02;
	else if ([command isMemberOfClass:[ASDeactivateCommand class]])
		return 0x03;
	else if ([command isMemberOfClass:[ASIncreaseCommand class]])
		return 0x05;
	else if ([command isMemberOfClass:[ASDecreaseCommand class]])
		return 0x04;
	else if ([command isMemberOfClass:[ASEnableStatusCommand class]])
		return 0x0d;
	else if ([command isMemberOfClass:[ASDisableStatusCommand class]])
		return 0x0e;
	else if ([command isMemberOfClass:[ASSetLevelCommand class]])
	{
		ASSetLevelCommand * setCommand = (ASSetLevelCommand	*) command;
		
		if ([[setCommand level] intValue] > 0)
			return 0x02;
		else
			return 0x03;
	}
	else // ASStatusCommand
		return 0x0f;
}

@end
