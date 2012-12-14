//
//  ASPowerLincModemController.m
//  Shion Framework
//
//  Created by Chris Karr on 2/19/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASPowerLinc2412Controller.h"
#include <termios.h>
#include <sys/ioctl.h>

#import "ASCommands.h"
#import "ASInsteonTransmitCommand.h"
#import "ASX10Address.h"
#import "ASInsteonDatabase.h"
#import "ASInsteonAddress.h"
#import "ASThermostatDevice.h"
#import "ASSprinklerDevice.h"
#import "ASContinuousDevice.h"

#define NEEDS_TRANSMIT @"Needs Transmit"
#define GET_VERSION 0x0001
#define RESET_PLC 0x0002
#define FETCH_X10_BYTE 0x003

unsigned char setpoints[2];

@implementation ASPowerLinc2412Controller

- (void) write:(NSData *) data
{
	ShionLog (@"Writing: %@", data);
	
	[serialPort writeData:data];
	[serialPort readInBackgroundAndNotify];
}

- (void) resendCommand
{
	ShionLog (@"** resend command %@", currentCommand);
	
	if ([currentCommand isKindOfClass:[ASInsteonTransmitCommand class]])
	{
		ASInsteonTransmitCommand * transmit = (ASInsteonTransmitCommand *) currentCommand;
		
		ASCommand * lastCommand = [transmit lastCommand];
		
		if (lastCommand != nil)
		{
			[lastCommand setValue:[NSNumber numberWithBool:YES] forKey:NEEDS_TRANSMIT];
			[commandQueue insertObject:lastCommand atIndex:0];
		}
	}
	else if (currentCommand != nil)
		[commandQueue insertObject:currentCommand atIndex:0];
	
	[wakeup invalidate];
	[wakeup release];
	
	wakeup = [[NSTimer scheduledTimerWithTimeInterval:5.00 target:self selector:@selector(checkQueue:) userInfo:nil repeats:YES] retain];
}

- (void) fetchInfo
{
	ASStatusCommand * command = [[ASStatusCommand alloc] init];
	
	unsigned char bytes[] = {0x02,0x60};
	
	NSMutableData * data = [NSMutableData dataWithBytes:bytes length:2];
	
	[command setValue:data forKey:COMMAND_BYTES];
	
	[self queueCommand:command];
	
	[command release];
}

- (void) startAllLink
{
	ASStatusCommand * command = [[ASStatusCommand alloc] init];
	
	unsigned char bytes[] = {0x02,0x64, 0x03, 0x01};
	
	NSMutableData * data = [NSMutableData dataWithBytes:bytes length:4];
	
	[command setValue:data forKey:COMMAND_BYTES];
	
	[self queueCommand:command];
	
	[command release];
}

- (void) cancelAllLink
{
	ASStatusCommand * command = [[ASStatusCommand alloc] init];
	
	unsigned char bytes[] = {0x02,0x65};
	
	NSMutableData * data = [NSMutableData dataWithBytes:bytes length:2];
	
	[command setValue:data forKey:COMMAND_BYTES];
	
	[self queueCommand:command];
	
	[command release];
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
				
				ShionLog(@"INSTEON MSG: %@", insteonMessage);
				
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
			else if (bytes[1] > 0x73)
			{
				// Ignore what we have - bad data...
				responseLength = length;
			}
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
				if ((bytes[i] == 0x02 && (bytes[i+1] >= 0x40)) || (bytes[i+1] == 0x15))
				{
					ShionLog (@"Misaligned %d bytes", i);
					ShionLog (@"response buffer: %@", [self stringForData:response]);
					
					if (bytes[i+1] == 0x15)
						[response replaceBytesInRange:NSMakeRange(0, i + 1) withBytes:NULL length:0];
					else
						[response replaceBytesInRange:NSMakeRange(0, i) withBytes:NULL length:0];
					
					return [self processResponse:response];
				}
			}
		}
	}
	
	if (responseLength == [response length])
	{
		[response setData:[NSData data]];
		return YES;
	}
	else if (responseLength > 0)
	{
		[response replaceBytesInRange:NSMakeRange(0, responseLength) withBytes:NULL length:0];
		return YES;
	}
	
	return NO;
}

- (void) closeController
{
	ShionLog(@"%@: Closing %@...", [self className], bsdPath);

 	if (serialPort != nil)
	{
		[serialPort closeFile];
		[serialPort release];
		
		serialPort = nil;
	}
}

- (void) resetController
{
	ShionLog(@"%@: Connecting to %@...", [self className], bsdPath);
	
	const char * deviceFilePath = [bsdPath cStringUsingEncoding:NSASCIIStringEncoding];
	
	int fd = open (deviceFilePath, O_RDWR | O_NONBLOCK); /// O_NOCTTY?
	
	if (fd != -1)
	{
		struct termios options;
		tcgetattr(fd, &options);
		
		memset(&options, 0, sizeof(struct termios));
		cfmakeraw(&options);
		cfsetspeed(&options, 19200);
		options.c_cflag = CREAD |  CLOCAL | CS8;
		
		tcsetattr(fd, TCSANOW, &options);
		
		int modem = 0;
		
		ioctl(fd, TIOCMGET, &modem);
		modem |= TIOCM_DTR;
		ioctl(fd, TIOCMSET, &modem);        

		ready = YES;
		[buffer setData:[NSData data]];

		serialPort = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(read:) name:NSFileHandleReadCompletionNotification object:serialPort];
		
		[serialPort readInBackgroundAndNotify];
	}
	else
		serialPort = nil;
		
}

- (void) resumeRead:(NSTimer *) theTimer
{
	[readTimer invalidate];

	readTimer = nil;

	[serialPort readInBackgroundAndNotify];
}

- (void) read:(NSNotification *) theNote
{
	if ([theNote object] == serialPort)
	{
		NSData * data = [[theNote userInfo] valueForKey:NSFileHandleNotificationDataItem];
	
		if ([data length] > 0)
		{
			ShionLog (@"Read: %@", data);

			[buffer appendData:data];
			
			ready = [self processResponse:buffer];
		}

		if (readTimer == nil)
			readTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(resumeRead:) userInfo:nil repeats:NO];
	}
}

- (ASPowerLinc2412Controller *) initWithPath:(NSString *) path
{
	if (self = [super init])
	{
		bsdPath = [path retain];
		
		wakeup = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkQueue:) userInfo:nil repeats:YES] retain];
		readTimer = nil;
		
		ready = YES;
		inited = NO;
			
		buffer = [[NSMutableData alloc] init];
		
		serialPort = nil;
		[self resetController];
			
		return self;
	}
	
	return nil;
}

- (void) close
{
	[serialPort closeFile];
}

- (void) dealloc
{
	[serialPort release];
	[wakeup invalidate];
	[buffer release];
	
	[super dealloc];
}

+ (ASPowerLinc2412Controller *) controllerWithPath:(NSString *) path
{
	ASPowerLinc2412Controller * controller = nil;
	
	controller = [[ASPowerLinc2412Controller alloc] initWithPath:path];

	return [controller autorelease];
}

- (void) transmitBytes
{
	if ([commandQueue count] > 0 && serialPort != nil)
	{
		currentCommand = [[commandQueue objectAtIndex:0] retain];
		[commandQueue removeObjectAtIndex:0];
		
		NSDate * commandDate = (NSDate *) [currentCommand valueForKey:COMMAND_DATE];
		
		if (commandDate != nil && [commandDate compare:[NSDate date]] == NSOrderedDescending)
		{
			[commandQueue addObject:currentCommand];
			
			[self transmitBytes];
		}
		else if ([currentCommand isMemberOfClass:[ASAggregateCommand class]])
		{
			NSArray * commands = [((ASAggregateCommand *) currentCommand) commands];
			
			[commandQueue addObjectsFromArray:commands];
			
			[self transmitBytes];
		}
		else
		{
			ASDevice * device = [currentCommand getDevice];
			
			if ([currentCommand isKindOfClass:[ASGetInfoCommand class]] && [[device getAddress] isKindOfClass:[ASInsteonAddress class]])
				[infoDevices addObject:device];

			NSData * commandData = (NSData *) [currentCommand valueForKey:COMMAND_BYTES];
			
			if (commandData != nil)
			{
				ShionLog (@"*** PowerLinc Modem: command to transmit: %@", [self stringForData:commandData]);

				[self write:commandData];
				
				ready = NO;
			}
		}
	}
	else if (serialPort == nil)
		ShionLog(@"Nil serial port");
}

- (void) checkQueue:(NSTimer *) theTimer
{
	if (!ready)
		return; // TODO monitor controller responsiveness here...
	
	[self transmitBytes];
	
	if ([wakeup timeInterval] > 1.0)
	{
		[wakeup invalidate];
		[wakeup release];
		
		wakeup = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkQueue:) userInfo:nil repeats:YES] retain];
	}
	
	if (!inited)
	{
		[self fetchInfo];
		inited = YES;
	}
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value;
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
	else if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		if (commandKind == AS_SET_LEVEL)
		{
			if ([((NSNumber *) value) intValue] == 0)
				return [self commandForDevice:device kind:AS_DEACTIVATE];
			else
				return [self commandForDevice:device kind:AS_ACTIVATE];
		}
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


@end
