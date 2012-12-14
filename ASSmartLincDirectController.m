//
//  ASSmartLincDirectController.m
//  Shion Framework
//
//  Created by Chris Karr on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ASSmartLincDirectController.h"

#import "ASCommands.h"
#import "ASInsteonAddress.h"
#import "ASX10Address.h"
#import "ASInsteonDatabase.h"

@implementation ASSmartLincDirectController

- (void) resendCommand
{
	ShionLog (@"** resend command %@", currentCommand);
	
	[commandQueue insertObject:currentCommand atIndex:0];
	
//	[wakeup invalidate];
//	[wakeup release];
//	
//	wakeup = [[NSTimer scheduledTimerWithTimeInterval:5.00 target:self selector:@selector(next:) userInfo:nil repeats:YES] retain];
}

- (BOOL) processResponse:(NSMutableData *) response
{
	unsigned length = [response length];
	unsigned char * bytes = (unsigned char *) [response bytes];
	
	unsigned char responseLength = 0;
	
	BOOL realign = NO;
	
	if (length == 1 && bytes[0] == 0x15)
	{
		[self resendCommand];
		
		responseLength = 1;
	}
	if (length >= 2)
	{
		if (bytes[0] == 0x02)
		{	
			// PLM to computer...
			if (bytes[1] == 0x50 && length >= 11)		// INSTEON Standard Message Received
			{
				NSData * insteonMessage = [response subdataWithRange:NSMakeRange(2, 9)];
				
				[self processStandardInsteonMessage:insteonMessage];
				
				responseLength = 11;
			}
			else if (bytes[1] == 0x51 && length >= 25)	// INSTEON Extended Message Received
			{
				NSData * insteonMessage = [response subdataWithRange:NSMakeRange(2, 23)];
				
				[self processExtendedInsteonMessage:insteonMessage];
				
				responseLength = 25;
			}
			else if (bytes[1] == 0x52 && length >= 4)	// X-10 Received
			{
				unsigned char xTenBytes[] = {0x00, bytes[2]};
				
				if (bytes[3] == 0x80)
					xTenBytes[0] = 0x01;
				
				NSData * xTenMessage = [NSData dataWithBytes:xTenBytes length:2];
				
				[self processX10Message:xTenMessage];
				
				responseLength = 4;
			}
			else if (bytes[1] == 0x53 && length >= 10)	// ALL-Linking Completed
				responseLength = 10;
			else if (bytes[1] == 0x54 && length >= 3)	// Button Event Report
				responseLength = 3;
			else if (bytes[1] == 0x55 && length >= 2)	// User Reset Detected
				responseLength = 3;
			else if (bytes[1] == 0x56 && length >= 6)	// ALL-Link Cleanup Failure Report
				responseLength = 6;
			else if (bytes[1] == 0x57 && length >= 10)	// ALL-Link Record Response
				responseLength = 10;
			else if (bytes[1] == 0x58 && length >= 3)	// ALL-Link Cleanup Status Report
				responseLength = 3;
			
			// Computer to PLM responses...
			else if (bytes[1] == 0x60 && length >= 9)	// Get IM Info
			{
				[self setName:@"PowerLinc Modem"];
				[self setAddress:[NSString stringWithFormat:@"insteon:%02x.%02x.%02x", bytes[2], bytes[3], bytes[4], nil]];
				[self setType:[ASInsteonDatabase stringForDeviceType:[response subdataWithRange:NSMakeRange(5, 2)]]];
				
				NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
				[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
				[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[2], bytes[3], bytes[4], nil] forKey:DEVICE_ADDRESS];
				[userInfo setValue:CONTROLLER_DEVICE forKey:DEVICE_TYPE];
				[userInfo setValue:[self getType] forKey:DEVICE_MODEL];
				[userInfo setValue:[self getName] forKey:DEVICE_NAME];
				[userInfo setValue:[NSNumber numberWithInt:(0 + bytes[7])] forKey:DEVICE_FIRMWARE];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				
				responseLength = 9; 
			}
			else if (bytes[1] == 0x61 && length >= 6)	// Send ALL-Link Command
				responseLength = 6;
			else if (bytes[1] == 0x62 && length >= 9)	// Send INSTEON Standard or Extended Message
			{
				if ((bytes[5] & 0x10) == 0x10) // Extended Message ?
					responseLength = 23;
				else
					responseLength = 9;
			}
			else if (bytes[1] == 0x63 && length >= 5)	// Send X10
				responseLength = 5;
			else if (bytes[1] == 0x64 && length >= 5)	// Start ALL-Linking
				responseLength = 5;
			else if (bytes[1] == 0x65 && length >= 3)	// Cancel ALL-Linking
				responseLength = 3;
			else if (bytes[1] == 0x66 && length >= 5)	// Set Host Device Category
				responseLength = 5;
			else if (bytes[1] == 0x67 && length >= 3)	// Reset the IM
				responseLength = 3;
			else if (bytes[1] == 0x68 && length >= 4)	// Set INSTEON ACK Message Byte
				responseLength = 4;
			else if (bytes[1] == 0x69 && length >= 3)	// Get First ALL-LINK Record
				responseLength = 3;
			else if (bytes[1] == 0x6a && length >= 3)	// Set IM Configuration
				responseLength = 3;
			else if (bytes[1] == 0x6b && length >= 4)	// Get ALL-Link Record for Sender
				responseLength = 4;
			else if (bytes[1] == 0x6c && length >= 3)	// LED On
				responseLength = 3;
			else if (bytes[1] == 0x6d && length >= 3)	// LED Off
				responseLength = 3;
			else if (bytes[1] == 0x6f && length >= 12)	// Manage ALL-Link Record
				responseLength = 12;
			else if (bytes[1] == 0x70 && length >= 4)	// Set INSTEON NAK Message Byte
				responseLength = 4;
			else if (bytes[1] == 0x71 && length >= 5)	// Set INSTEON ACK Message Two Bytes
				responseLength = 5;
			else if (bytes[1] == 0x72 && length >= 3)	// RF Sleep
				responseLength = 3;
			else if (bytes[1] == 0x73 && length >= 6)	// Get IM Configuration
				responseLength = 6;
			else if (bytes[1] == 0x02)
				responseLength = 1;
			else
				realign = YES;
		}
		else if (bytes[0] == 0x15)
		{
			[self resendCommand];
			
			for (responseLength = 1; responseLength < length && bytes[responseLength] == 0x15; responseLength++)
			{
				
			}
		}
		else 
		{
			ShionLog (@"no 0x15 or 0x02");
			ShionLog (@"response buffer: %@", [self stringForData:response]);
			realign = YES;
		}
		
		if (realign)
		{
			// Something becomes misaligned
			
			unsigned int i = 0;
			
			for (i = 0; i < length - 1; i++)
			{
				if ((bytes[i] == 0x02 && (bytes[i+1] >= 0x50 && bytes[i+1] <= 0x73)) || (bytes[i] == 0x15))
				{
					ShionLog (@"Misaligned %d bytes", i);
					ShionLog (@"response buffer: %@", [self stringForData:response]);
					
					if (i == 0)
						i = 1;
					
					[response replaceBytesInRange:NSMakeRange(0, i) withBytes:NULL length:0];
					
					return [self processResponse:response];
				}
			}
			
			[response replaceBytesInRange:NSMakeRange(0, length) withBytes:NULL length:0];
			
			return YES;
		}
	}
	
	if (responseLength > 0)
	{
		[response replaceBytesInRange:NSMakeRange(0, responseLength) withBytes:NULL length:0];
		
		if ([response length] > 0)
			return [self processResponse:response];
		
		return YES;
	}
	
	return NO;
}

- (void) stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
	if (eventCode == NSStreamEventHasBytesAvailable)
	{
		if ([aStream isKindOfClass:[NSInputStream class]])
		{
			NSInputStream * _in = (NSInputStream *) aStream;
			
			unsigned char readBuffer[1024];
			int read = 0;
			
			while ([_in hasBytesAvailable])
			{
				read = [_input read:readBuffer maxLength:1024];
				
				if (read > 0)
				{
					[bufferData appendBytes:readBuffer length:read];

					ShionLog (@"Read[%d]: %@", read, bufferData);
				}
			}
			
			if ([bufferData length] > 0)
				ready = [self processResponse:bufferData];
			else
				ready = YES;
		}
	}
}

- (ASCommand *) commandForDevice:(ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value;
{
	ASCommand * command = [super commandForDevice:device kind:commandKind value:value];
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isKindOfClass:[ASInsteonAddress class]])
	{
		unsigned char bytes[] = {0x02,0x62};
		
		NSMutableData * commandBytes = [NSMutableData dataWithBytes:bytes length:2];
		
		[commandBytes appendData:[self insteonDataForDevice:device command:command value:value]];
		
		[command setValue:commandBytes forKey:COMMAND_BYTES];
	}
	
	return command;
}

- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind
{
	ASCommand * command = nil;
	
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASInsteonAddress class]])
	{
		unsigned char bytes[] = {0x02,0x62};
		
		command = [super commandForDevice:device kind:commandKind];
		
		NSMutableData * commandBytes = [NSMutableData dataWithBytes:bytes length:2];
		
		[commandBytes appendData:[self insteonDataForDevice:device command:command]];
		
		[command setValue:commandBytes forKey:COMMAND_BYTES];
	}
	else if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		command = [super commandForDevice:device kind:commandKind];
		
		unsigned char code = [((ASX10Address *) [device getAddress]) getAddressByte];
		
		currentX10Address = code;
		
		ASAggregateCommand * aggCommand = [[[ASAggregateCommand alloc] init] autorelease];
		
		// Step 1: Address the target device.
		
		ASCommand * unitCodeCommand = [[ASCommand alloc] init];
		unsigned char bytes[] = {0x02, 0x63, code, 0x00};
		NSMutableData * data = [NSMutableData dataWithBytes:bytes length:4];
		[unitCodeCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:unitCodeCommand];
		[unitCodeCommand release];
		
		unsigned char commandByte = [self xtenCommandByteForDevice:device command:command];
		
		// Step 2: Send command.
		
		ASCommand * cmdCommand = [[ASCommand alloc] init];
		unsigned char cmdBytes[] = {0x02, 0x63, ((code & 0xf0) | commandByte), 0x80};
		data = [NSMutableData dataWithBytes:cmdBytes length:4];
		[cmdCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:cmdCommand];
		[cmdCommand release];
		
		command = aggCommand;
	}		
	
	return command;
}

- (void) next:(NSTimer *) theTimer
{
	if (!ready)
		return;
	
	if ([commandQueue count] > 0)
	{
		currentCommand = [[commandQueue objectAtIndex:0] retain];
		[commandQueue removeObjectAtIndex:0];
		
		if ([currentCommand isKindOfClass:[ASAggregateCommand class]])
		{
			NSMutableArray * cmds = [NSMutableArray arrayWithArray:[((ASAggregateCommand *) currentCommand) commands]];
			
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
			NSData * data = [currentCommand valueForKey:COMMAND_BYTES];

			if (data != nil)
			{
				ShionLog(@"Sending: %@", [self stringForData:data]);
				
				if ([_output write:[data bytes] maxLength:[data length]] == -1)
					ShionLog(@"Error sending command '%@'.", [self stringForData:data]);
			}
		}
	}
}

- (void) setupController
{
	[NSStream getStreamsToHost:[NSHost hostWithAddress:_host] port:9761 inputStream:&_input outputStream:&_output];
	
	[_input retain];
	[_input setDelegate:self];
	[_input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_input open];
	
	[_output retain];
	[_output setDelegate:self];
	[_output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_output open];
	
	ready = YES;
}

- (void) closeController
{
	ShionLog(@"Closing %@...", [self className]);
	
	[_input close];
	_input = nil;
	
	[_output close];
	_output = nil;
	
	[self setupController];
}


- (ASSmartLincDirectController *) initWithHost:(NSString *) host
{
	if (self = [super init])
	{
		_input = nil;
		_output = nil;
		
		_host = [host retain];
		
		bufferData = [[NSMutableData alloc] init];

		wakeup = [[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(next:) userInfo:nil repeats:YES] retain];
		
		[self setupController];
	}
	
	return self;
}

@end
