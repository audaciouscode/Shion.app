//
//  ASSmartLincWebController.m
//  Shion Framework
//
//  Created by Chris Karr on 2/4/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASSmartLincWebController.h"
#import "ASInsteonAddress.h"
#import "ASX10Address.h"
#import "ASX10Address.h"
#import "ASCommands.h"

#import "ASToggleDevice.h"
#import "ASContinuousDevice.h"
#import "ASThermostatDevice.h"

#define COMMAND_URL @"Command URL"

@implementation ASSmartLincWebController

- (ASSmartLincWebController *) initWithHost:(NSString *) host
{
	if (self = [super init])
	{
		_host = [host retain];
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(next:) userInfo:nil repeats:YES] retain];
		bufferTimer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkBuffer:) userInfo:nil repeats:YES] retain];
		bufferData = [[NSMutableData alloc] init];
		lastString = [[NSMutableString alloc] init];
	}
	
	return self;
}

- (void) checkBuffer:(NSTimer *) theTimer
{
	[bufferData setData:[NSData data]];
	
	NSURL * bufferUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/buffstatus.xml", _host]];
	
	ShionLog(@"Fetching URL %@ ...", bufferUrl);
	
	[[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:bufferUrl] delegate:self] retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[bufferData appendData:data];
}

- (NSData *) dataForString:(NSString *) string
{
	NSMutableData * data = [NSMutableData data];

	string = [string lowercaseString];
	
	for (unsigned int i = 0; i < ([string length] - 1); i += 2)
	{
		unsigned char byte = 0x00;
		
		unichar letter = [string characterAtIndex:i];
		
		if (letter == '1')
			byte = byte | 0x10;
		else if (letter == '2')
			byte = byte | 0x20;
		else if (letter == '3')
			byte = byte | 0x40;
		else if (letter == '4')
			byte = byte | 0x40;
		else if (letter == '5')
			byte = byte | 0x50;
		else if (letter == '6')
			byte = byte | 0x60;
		else if (letter == '7')
			byte = byte | 0x70;
		else if (letter == '8')
			byte = byte | 0x80;
		else if (letter == '9')
			byte = byte | 0x90;
		else if (letter == 'a')
			byte = byte | 0xa0;
		else if (letter == 'b')
			byte = byte | 0xb0;
		else if (letter == 'c')
			byte = byte | 0xc0;
		else if (letter == 'd')
			byte = byte | 0xd0;
		else if (letter == 'e')
			byte = byte | 0xe0;
		else if (letter == 'f')
			byte = byte | 0xf0;
		
		letter = [string characterAtIndex:(i + 1)];

		if (letter == '1')
			byte = byte | 0x01;
		else if (letter == '2')
			byte = byte | 0x02;
		else if (letter == '3')
			byte = byte | 0x03;
		else if (letter == '4')
			byte = byte | 0x04;
		else if (letter == '5')
			byte = byte | 0x05;
		else if (letter == '6')
			byte = byte | 0x06;
		else if (letter == '7')
			byte = byte | 0x07;
		else if (letter == '8')
			byte = byte | 0x08;
		else if (letter == '9')
			byte = byte | 0x09;
		else if (letter == 'a')
			byte = byte | 0x0a;
		else if (letter == 'b')
			byte = byte | 0x0b;
		else if (letter == 'c')
			byte = byte | 0x0c;
		else if (letter == 'd')
			byte = byte | 0x0d;
		else if (letter == 'e')
			byte = byte | 0x0e;
		else if (letter == 'f')
			byte = byte | 0x0f;
		
		[data appendBytes:&byte length:1];
	}
	
	return data;
}

- (ASDevice *) deviceWithAddress:(NSData *) addressBytes
{
	NSEnumerator * iter = [devices objectEnumerator];
	ASDevice * device = nil;
	while (device = [iter nextObject])
	{
		ASAddress * deviceAddress = [device getAddress];
		
		if ([deviceAddress isKindOfClass:[ASInsteonAddress class]])
		{
			if ([[((ASInsteonAddress *) deviceAddress) getAddress] isEqualToData:addressBytes])
				return device;
		}
	}
	
	return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[connection release];

	NSMutableString * bufferString = [[[NSMutableString alloc] initWithData:bufferData encoding:NSASCIIStringEncoding] autorelease];
	
	[bufferString replaceOccurrencesOfString:@"<response><BS>" withString:@"" options:0 range:NSMakeRange(0, [bufferString length])];
	[bufferString replaceOccurrencesOfString:@"</BS></response>" withString:@"" options:0 range:NSMakeRange(0, [bufferString length])];
	[bufferString replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [bufferString length])];
	[bufferString replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, [bufferString length])];
	
	if ([lastString isEqualToString:bufferString])
		return;
	else
		[lastString setString:bufferString];
	
	NSData * dataBytes = [self dataForString:bufferString];
	unsigned char * bytes = (unsigned char *) [dataBytes bytes];

	if ([dataBytes length] == 20) // INSTEON
	{
		ShionLog (@"** Processing standard message: %@", [self stringForData:dataBytes]);

		NSData * addressBytes = [dataBytes subdataWithRange:NSMakeRange(11, 3)];
			
		ASDevice * device = [self deviceWithAddress:addressBytes];
		
		if (device != nil) // One we know
		{
			if ([device isKindOfClass:[ASToggleDevice class]])
			{
				NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
				[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
							
				[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[11], bytes[12], bytes[13], nil] forKey:DEVICE_ADDRESS];
							
				if ([device isKindOfClass:[ASContinuousDevice class]])
				{
					unsigned int level = 0 + bytes[19];
					[((ASContinuousDevice *) device) setLevel:[NSNumber numberWithUnsignedInt:level]];
				}
				else
				{
					if (bytes[19] > 0x00)
						bytes[19] = 0xff;
				}
							
				if (bytes[19] > 0x00)
					[((ASToggleDevice *) device) setActive:YES];
				else
					[((ASToggleDevice *) device) setActive:NO];
								
				[userInfo setObject:[NSNumber numberWithUnsignedInt:(0 + bytes[19])] forKey:DEVICE_STATE];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
			}
			else 
			{
				ShionLog (@"** Unknown message for device %@: %@", device, [self stringForData:addressBytes]);
			}
		}
	}
	
	[bufferString release];
}

- (void) next:(NSTimer *) theTimer
{
	if ([commandQueue count] > 0)
	{
		ASCommand * command = [commandQueue objectAtIndex:0];
		
		if ([command isKindOfClass:[ASAggregateCommand class]])
		{
			NSMutableArray * cmds = [NSMutableArray arrayWithArray:[((ASAggregateCommand *) command) commands]];
			
			while ([cmds count] > 0)
			{
				ASCommand * aggCmd  = [cmds lastObject];
				
				if ([self acceptsCommand:aggCmd])
					[commandQueue insertObject:aggCmd atIndex:0];
				
				[cmds removeObject:aggCmd];
			}
		}
		else
		{
			NSURL * url = [command valueForKey:COMMAND_URL];

			if (url != nil)
			{
				NSError * error = nil;
				
				ShionLog(@"Sending command URL %@ ...", url);
				
				NSData * data = [NSData dataWithContentsOfURL:url options:0 error:&error];
				
				if (error != nil)
				{
					// TODO log error
				}
				else
				{
					// TODO log data contents?
					
					[data bytes];
				}
			}
		}
		
		[commandQueue removeObject:command];
	}
}

- (NSURL *) urlForX10Command:(NSData *) data
{
	NSMutableString * urlString = [NSMutableString stringWithFormat:@"http://%@/3?0263", _host, nil];
	
	unsigned char * bytes = (unsigned char *) [data bytes];
	
	for (int i = 0; i < [data length]; i++)
		[urlString appendFormat:@"%02x", bytes[i], nil];

	[urlString appendString:@"=I=3"];

	return [NSURL URLWithString:urlString];
}

- (NSURL *) urlForInsteonCommand:(NSData *) data
{
	// http://10.0.1.12:80/3?02620EBF030F11ff=I=3

	NSMutableString * urlString = [NSMutableString stringWithFormat:@"http://%@/3?0262", _host, nil];
	
	unsigned char * bytes = (unsigned char *) [data bytes];
	
	for (int i = 0; i < [data length]; i++)
		[urlString appendFormat:@"%02x", bytes[i], nil];
	
	[urlString appendString:@"=I=3"];

	return [NSURL URLWithString:urlString];
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value;
{
	ASCommand * command = [super commandForDevice:device kind:commandKind value:value];
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isKindOfClass:[ASInsteonAddress class]])
	{
		NSData * addressBytes = [((ASInsteonAddress *) deviceAddress) getAddress];

		if ([command isMemberOfClass:[ASSetLevelCommand class]])
		{	
			unsigned char level = [((NSNumber *) value) unsignedCharValue];
			
			unsigned char bytes[] = { 0x0F,0x11, level};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];

			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
		else if ([command isMemberOfClass:[ASSetThermostatModeCommand class]])
		{
			unsigned char newMode = 0x00;
			
			if ([device isKindOfClass:[ASThermostatDevice class]])
			{
				unsigned char mode = [((NSNumber *) value) unsignedCharValue];
				
				if (mode == MODE_OFF)
					newMode = 0x09;
				else if (mode == MODE_HEAT)
					newMode = 0x04;
				else if (mode == MODE_COOL)
					newMode = 0x05;
				else if (mode == MODE_AUTO)
					newMode = 0x06;
				else if (mode == MODE_FAN)
					newMode = 0x07;
				else if (mode == MODE_FAN_OFF)
					newMode = 0x08;
				else if (mode == MODE_PROGRAM)
					newMode = 0x0c;
				else if (mode == MODE_PROGRAM_HEAT)
					newMode = 0x0a;
				else if (mode == MODE_PROGRAM_COOL)
					newMode = 0x0c;
			}

			unsigned char bytes[] = { 0x0F,0x6b, newMode};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
			
		}	
		else if ([command isMemberOfClass:[ASSetCoolPointCommand class]])
		{
			unsigned char point = [((NSNumber *) value) unsignedCharValue] * 2;
			
			unsigned char bytes[] = { 0x0F,0x6c, point};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}	
		else if ([command isMemberOfClass:[ASSetHeatPointCommand class]])
		{
			unsigned char point = [((NSNumber *) value) unsignedCharValue] * 2;
			
			unsigned char bytes[] = { 0x0F,0x6d, point};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}	
		else if ([command isMemberOfClass:[ASSprinklerOnCommand class]])
		{	
			unsigned char unit = [((NSNumber *) value) unsignedCharValue];
			
			unsigned char bytes[] = { 0x0F,0x40, unit};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
		else if ([command isMemberOfClass:[ASSprinklerOffCommand class]])
		{	
			unsigned char unit = [((NSNumber *) value) unsignedCharValue];
			
			unsigned char bytes[] = { 0x0F,0x41, unit};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
		else if ([command isKindOfClass:[ASSprinklerSetConfigurationCommand class]])
		{
			ASSprinklerSetConfigurationCommand * sprinklerCommand = (ASSprinklerSetConfigurationCommand *) command;
			
			BOOL enabled = [sprinklerCommand enabled];
			
			unsigned char commandByte = 0x02;
			
			if ([sprinklerCommand isMemberOfClass:[ASSprinklerSetDiagnosticsConfiguration class]])
			{
				if (enabled)
					commandByte = 0xFE;
				else
					commandByte = 0xFF;
			}
			else if ([sprinklerCommand isMemberOfClass:[ASSprinklerSetPumpConfigurationCommand class]])
			{
				if (enabled)
					commandByte = 0x07;
				else
					commandByte = 0x08;
			}
			else if ([sprinklerCommand isMemberOfClass:[ASSprinklerSetRainSensorConfigurationCommand class]])
			{
				if (enabled)
					commandByte = 0x0b;
				else
					commandByte = 0x0c;
			}
			
			unsigned char bytes[] = { 0x0F,0x44, commandByte};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
	}
	
	// TODO: X10 Set Level Support
	
	return command;
}

- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind
{
	ASCommand * command = nil;
	
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASInsteonAddress class]])
	{
		NSData * addressBytes = [((ASInsteonAddress *) deviceAddress) getAddress];

		command = [super commandForDevice:device kind:commandKind];

		if (![self acceptsCommand:command])
			return nil;

		if ([command isMemberOfClass:[ASStatusCommand class]])
		{
			unsigned char bytes[] = { 0x0F,0x19, 0x00};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
		else if ([command isMemberOfClass:[ASActivateCommand class]])
		{
			unsigned char bytes[] = { 0x0F,0x11, 0xFF};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
		else if ([command isMemberOfClass:[ASDeactivateCommand class]])
		{
			unsigned char bytes[] = { 0x0F,0x13, 00};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
		else if ([command isMemberOfClass:[ASActivateFanCommand class]])
		{
			unsigned char bytes[] = { 0x0F,0x6B, 0x07};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
		else if ([command isMemberOfClass:[ASDeactivateFanCommand class]])
		{
			unsigned char bytes[] = { 0x0F,0x6B, 0x08};
			
			NSMutableData * data = [NSMutableData dataWithData:addressBytes];
			[data appendBytes:bytes length:3];
			
			[command setValue:[self urlForInsteonCommand:data] forKey:COMMAND_URL];
		}
	}
	else if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		command = [super commandForDevice:device kind:commandKind];

		if (![self acceptsCommand:command])
			return nil;

		ASAggregateCommand * aggCommand = [[[ASAggregateCommand alloc] init] autorelease];

		unsigned char code = [((ASX10Address *) [device getAddress]) getAddressByte];
		
		// Step 1: Address the target device.
		
		ASCommand * unitCodeCommand = [[ASCommand alloc] init];
		
		unsigned char bytes[] = {code, 0x00};

		[unitCodeCommand setValue:[self urlForX10Command:[NSData dataWithBytes:bytes length:2]] forKey:COMMAND_URL];
		
		[aggCommand addCommand:unitCodeCommand];
		[unitCodeCommand release];

		// Step 2: Send command.

		ASCommand * commandCodeCommand = [[ASCommand alloc] init];
		
		unsigned char commandBytes[] = {0x00, 0x00};
		
		if ([command isMemberOfClass:[ASAllOffCommand class]])
		{
			commandBytes[0] = (code & 0xf0);
			commandBytes[1] = 0x80;
		}
		else if ([command isMemberOfClass:[ASAllLightsOffCommand class]])
		{
			commandBytes[0] = ((code & 0xf0) | 0x06);
			commandBytes[1] = 0x80;
		}
		if ([command isMemberOfClass:[ASAllLightsOnCommand class]])
		{
			commandBytes[0] = ((code & 0xf0) | 0x01);
			commandBytes[1] = 0x80;
		}
		else if ([command isMemberOfClass:[ASChimeCommand class]])
		{
			commandBytes[0] = ((code & 0xf0) | 0x02);
			commandBytes[1] = 0x80;
		}
		else if ([command isMemberOfClass:[ASActivateCommand class]])
		{
			commandBytes[0] = ((code & 0xf0) | 0x02);
			commandBytes[1] = 0x80;
		}
		else if ([command isMemberOfClass:[ASDeactivateCommand class]])
		{
			commandBytes[0] = ((code & 0xf0) | 0x03);
			commandBytes[1] = 0x80;
		}
		else if ([command isMemberOfClass:[ASIncreaseCommand class]])
		{
			commandBytes[0] = ((code & 0xf0) | 0x05);
			commandBytes[1] = 0x80;
		}
		else if ([command isMemberOfClass:[ASDecreaseCommand class]])
		{
			commandBytes[0] = ((code & 0xf0) | 0x04);
			commandBytes[1] = 0x80;
		}

		[commandCodeCommand setValue:[self urlForX10Command:[NSData dataWithBytes:commandBytes length:2]] forKey:COMMAND_URL];

		[aggCommand addCommand:commandCodeCommand];
		[commandCodeCommand release];
		
		return aggCommand;
	}		
	
	return command;
}

- (BOOL) acceptsCommand: (ASCommand *) command;
{
	if ([command isMemberOfClass:[ASActivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDeactivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetLevelCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetThermostatModeCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetCoolPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetHeatPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAggregateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASStatusCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASIncreaseCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDecreaseCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASActivateFanCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDeactivateFanCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASChimeCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAllOffCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAllLightsOnCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAllLightsOffCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSprinklerOnCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSprinklerOffCommand class]])
		return YES;
	else if ([command isKindOfClass:[ASSprinklerSetConfigurationCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASCommand class]])
		return YES;
	
	return NO;
}

@end
