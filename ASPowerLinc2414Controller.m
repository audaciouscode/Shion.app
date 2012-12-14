//
//  ASPowerLincUSBController.m
//  Shion Framework
//
//  Created by Chris Karr on 12/9/08.
//  Copyright 2008 Audacious Software. 
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#import "ASPowerLinc2414Controller.h"
#import "ASInsteonAddress.h"
#import "ASX10Address.h"
#import "ASCommands.h"
#import "ASInsteonTransmitCommand.h"

#import "ASToggleDevice.h"
#import "ASMotionDetector.h"

#import "ASInsteonDatabase.h"

#define VENDOR_ID 0x10bf
#define PRODUCT_ID 0x0004

#define LINE_SIZE 8
#define SEGMENT_SIZE 8

#define NEEDS_TRANSMIT @"Needs Transmit"
#define INSTEON_CONTROLLER @"Insteon Thread Controller"

// Native commands

#define GET_VERSION 0x0001
#define RESET_PLC 0x0002
#define FETCH_X10_BYTE 0x0003

#define BUFFER_SIZE 16

BOOL processAck = YES;

unsigned char buffer[BUFFER_SIZE];
unsigned long transmitCount = 0;
unsigned long receiveCount = 0;

void ErrorLog (NSString * error, kern_return_t code)
{
	NSMutableString * errorString = [NSMutableString stringWithString:error];
	
	if (code == 0xe00002d9)
		[errorString appendString:@" The device is not attached."];
	else
		[errorString appendFormat:@" Error 0x%08x.", code, nil];

	NSDictionary * errorDict = [NSDictionary dictionaryWithObject:errorString forKey:HARDWARE_ERROR_MSG];
	[[NSNotificationCenter defaultCenter] postNotificationName:HARDWARE_ERROR object:nil userInfo:errorDict];

	ShionLog([NSString stringWithFormat:@"Hardware Error: %@", errorString, nil]);
}

BOOL processResponse (NSMutableData * response)
{
	/*
	 * See the Insteon developer's guide, Ch. 9, pp. 198-199.
	 */

	NSMutableDictionary * threadDict = [[NSThread currentThread] threadDictionary];		
	ASPowerLinc2414Controller * controller = [threadDict valueForKey:INSTEON_CONTROLLER];

	unsigned length = [response length];
	unsigned char * bytes = (unsigned char *) [response bytes];
	
	unsigned char responseLength = 0;
	
	BOOL realign = NO;
	
	if (length == 1 && bytes[0] == 0x15)
	{
		[controller resendCommand];
			
		responseLength = 1;
	}
	if (length >= 2)
	{
		if (bytes[0] == 0x02)
		{	
			if (bytes[1] == 0x15)
			{
				// Controller not ready.
				
				[controller resendCommand];
				
				responseLength = 2;
			}
			else if ((bytes[1] >= 0x40) && (bytes[1] <= 0x4f))
			{
				if (bytes[1] == 0x40)
				{
					// Download response from controller
					
					if (length >= 7)
					{
						if (bytes[6] == 0x15)
						{
							// Documentation is unclear?
							// [controller resendCommand];
						}
						else
						{
							// TODO - verify response?
						}
						
						responseLength = 7;
					}
				}
				else if (bytes[1] == 0x41)
				{
					// Fixed-length message
					
					if (length > 2)
					{
						unsigned char messageLength = bytes[2];
						
						if (length > 3 + messageLength)
						{
							responseLength = 3 + messageLength;
							
							// Fixed length message;
						}
					}
				}
				else if (bytes[1] == 0x42)
				{
					// Upload data from controller
					
					if (length > 9)
					{
						unsigned char lengthHigh = bytes[4];
						unsigned char lengthLow = bytes[5];
						
						unsigned short uploadLength = lengthHigh;
						uploadLength << 8;
						uploadLength += lengthLow;
						
						if (length >= 9 + uploadLength)
						{
							responseLength = 9 + uploadLength;
							
							if (uploadLength > 0)
								[controller processUploadMessage:[response subdataWithRange:NSMakeRange(6, uploadLength)] high:bytes[2] low:bytes[3]];
						}
					}
					else if (bytes[2] == 0x01 && bytes[3] == 0x15)
						responseLength = 4;
				}
				else if (bytes[1] == 0x43)
				{
					// Variable Length Text Message
					
					if (length >= 3)
					{
						unsigned char textLength = 0;
						
						unsigned char i;
						
						for (i = 2; i < length && textLength == 0; i++)
						{
							if (bytes[i] == 0x03)
							{
								textLength = i - 2;
								responseLength = i + 1;
							}
						}
						
						// Variable length text message.
					}
				}
				else if (bytes[1] == 0x44)
				{
					// Get checksum
					
					if (length >= 9)
					{
						// TODO: process checksums
						
						responseLength = 9;
					}
				}
				else if (bytes[1] == 0x45)
				{
					// Event report
					
					if (length >= 3)
					{
						responseLength = 3;
						[controller processEvent:bytes[2]];
					}				
				}
				else if (bytes[1] == 0x46)
				{
					// Mask
					
					if (length >= 7)
					{
						// TODO: process masks
						
						if (bytes[6] == 0x02)
							responseLength = 6;
						else
							responseLength = 7;
					}
				}
				else if (bytes[1] == 0x47)
				{
					// Simulated event
					
					if (length >= 5)
					{
						// TODO: process simulated events
						
						responseLength = 5;
					}
				}
				else if (bytes[1] == 0x48)
				{
					// Get version
					
					if (length >= 9)
					{
						responseLength = 9;
						
						[controller processGetVersion:[response subdataWithRange:NSMakeRange (2, 6)]];
					}
				}
				else if (bytes[1] == 0x49)
				{
					// Debug report
					
					if (length >= 4)
					{
						// TODO: process debug reports
						
						responseLength = 4;
					}
				}
				else if (bytes[1] == 0x4a)
				{
					// X10 byte received
					
					if (length >= 4)
					{
						responseLength = 4;
						
						[controller processX10Message:[response subdataWithRange:NSMakeRange(2, 2)]];
					}
				}
				else if (bytes[1] == 0x4f)
				{
					// Insteon message received
					
					if (length >= 3)
					{
						if (bytes[2] == 0x05)
						{
							[controller resendCommand];
							
							responseLength = 3;
						}
						else if (bytes[2] > 0x08)
						{
							// FIX
							
							responseLength = 3;
						}
						else if (length >= 12)
						{
							BOOL extended = ((bytes[9] & 0x10) == 0x10) && (bytes[12] != 0x02) && ((bytes[13] & 0x40) != 0x40);
							
							if (extended && length >= 26)
							{
								[controller processExtendedInsteonMessage:[response subdataWithRange:NSMakeRange(3, 23)]];
								
								responseLength = 26;
							}
							else if (!extended)
							{
								[controller processStandardInsteonMessage:[response subdataWithRange:NSMakeRange(3, 9)]];
								
								responseLength = 12;
							}
						}
					}
				}
			}
			else
			{
				ShionLog (@"no 0x40 or 0x15 => 0x%02x", (bytes[1] & 0x40));
				ShionLog (@"response buffer: %@", [controller stringForData:response]);
				
				realign = YES;
			}
		}
		else if (bytes[0] == 0x15)
		{
			[controller resendCommand];
		
			for (responseLength = 1; responseLength < length && bytes[responseLength] == 0x15; responseLength++)
			{
				
			}
		}
		else if (bytes[0] == 0xff && bytes[1] == 0xff)
		{
			// Kludgy fix for odd behavior in newer PLC controllers. Assuming variable length message?
			
			bytes[0] = 0x02;
			bytes[1] = 0x4f;
		}
		else 
		{
			ShionLog (@"no 0x15 or 0x02");
			ShionLog (@"response buffer: %@", [controller stringForData:response]);
			realign = YES;
		}
		
		if (realign)
		{
			// Something becomes misaligned
			
			unsigned int i = 0;
			
			for (i = 0; i < length - 1; i++)
			{
				if (bytes[i] == 0x02 && (((bytes[i+1] >= 0x40) && (bytes[i+1] <= 0x4f)) || (bytes[i+1] == 0x15)))
				{
					ShionLog (@"Misaligned %d bytes", i);
					ShionLog (@"response buffer: %@", [controller stringForData:response]);
					
					if (bytes[i+1] == 0x15)
						[response replaceBytesInRange:NSMakeRange(0, i + 1) withBytes:NULL length:0];
					else
						[response replaceBytesInRange:NSMakeRange(0, i) withBytes:NULL length:0];
					
					return processResponse(response);
				}
			}
		}
	}
	
	if (responseLength > 0 && responseLength <= [response length])
	{
		[response replaceBytesInRange:NSMakeRange(0, responseLength) withBytes:NULL length:0];
		return YES;
	}
	
	return NO;
}

static void callback2414 (void * target, IOReturn result, void * o, void * p)
{
	ASPowerLinc2414Controller * controller = [[[NSThread currentThread] threadDictionary] valueForKey:INSTEON_CONTROLLER];
	
	NSMutableData * responseData = [[[NSThread currentThread] threadDictionary] valueForKey:@"Response"];
	
	if (responseData == nil)
	{
		[[[NSThread currentThread] threadDictionary] setValue:[NSMutableData data] forKey:@"Response"];
		return callback2414 (target, result, o, p);
	}
	
	unsigned char index = buffer[0];

	if (index >= 0x80)
		index -= 0x80;


	if (index == 0x15)
	{
		[responseData setData:[NSData data]];
		[controller setReady:YES];
		return;
	}
	
	
	unsigned int i = 0;
	for (i = 1; i <= index; i++)
		[responseData appendBytes:(buffer+i) length:1];
	
	ShionLog (@"response buffer = %@", [controller stringForData:responseData]);
	
	BOOL complete = processResponse (responseData);
	
	if ([controller isFinished] == NO && buffer[0] >= 0x80)
		[controller setReady:YES];
	else if (complete)
		[controller setReady:YES];
	
	[controller updated];
}

@implementation ASPowerLinc2414Controller

- (void) updated
{
	[lastUpdate release];
	
	lastUpdate = [[NSDate date] retain];
}

- (void) sendBytes:(NSData *) bytes
{
	[self setReady:NO];

	@synchronized(self)
	{
		kern_return_t result = (*controllerHID)->setReport (controllerHID, kIOHIDReportTypeOutput, 0, (void *) [bytes bytes], [bytes length], 5000, NULL, NULL, NULL);
		
		if (result != KERN_SUCCESS)
			ErrorLog(@"Error encountered sending data to controller.", result);
	}
}

+ (ASPowerLinc2414Controller *) findController
{
	IOHIDDeviceInterface122** hid;
	
	CFMutableDictionaryRef matchingDict = NULL;
	
	matchingDict = IOServiceMatching (kIOHIDDeviceKey);
	
	if (matchingDict)
	{
		int val = VENDOR_ID;
		CFNumberRef valRef;

		valRef = CFNumberCreate (kCFAllocatorDefault, kCFNumberSInt32Type, &val);
		CFDictionarySetValue (matchingDict, CFSTR(kIOHIDVendorIDKey), valRef);
		CFRelease (valRef);
		
		val = PRODUCT_ID;
		valRef = CFNumberCreate (kCFAllocatorDefault, kCFNumberSInt32Type, &val);
		CFDictionarySetValue (matchingDict, CFSTR(kIOHIDProductIDKey), valRef);
		CFRelease (valRef);
	}
	
	io_service_t ioService = IOServiceGetMatchingService (kIOMasterPortDefault, matchingDict);
	
	IOCFPlugInInterface** iodev = NULL;
	SInt32 score;
	
	kern_return_t result = IOCreatePlugInInterfaceForService (ioService, kIOHIDDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &iodev, &score);
	
	if (result == KERN_SUCCESS && iodev)
	{
		result = (*iodev)->QueryInterface (iodev, CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID), (LPVOID) &hid);
		if (result != KERN_SUCCESS)
			ErrorLog(@"Error querying plugin interface.", result);
		
		(*iodev)->Release (iodev);
		
		ASPowerLinc2414Controller * controller = [[ASPowerLinc2414Controller alloc] initWithHID:hid];
		
		[[[NSThread currentThread] threadDictionary] setValue:controller forKey:INSTEON_CONTROLLER];
		
		[controller refresh];
		
		return [controller autorelease];
	}
	else
	{
		ShionLog(@"Unable to find PowerLinc 2414 controller.");
		return nil;
	}
}

- (ASPowerLinc2414Controller *) initWithHID:(IOHIDDeviceInterface122**) hid
{
	if (self = [super init])
	{
		address = nil;
		
		transmitCount = 0;
		receiveCount = 0;
		
		mach_port_t port;
		CFRunLoopSourceRef eventSource;
		
		(*hid)->createAsyncPort (hid, &port);
		(*hid)->createAsyncEventSource (hid, &eventSource);
		
		kern_return_t result = (*hid)->open(hid, 0);
		
		if (result != KERN_SUCCESS)
			ErrorLog(@"Error opening HID device.", result);
		
		result = (*hid)->setInterruptReportHandlerCallback (hid, buffer, sizeof(buffer), (IOHIDReportCallbackFunction) callback2414, NULL, NULL);
		
		if (result != KERN_SUCCESS)
			ErrorLog(@"Error setting device callback.", result);
		
		(*hid)->startAllQueues (hid);
		
		CFRunLoopAddSource (CFRunLoopGetCurrent(), eventSource, kCFRunLoopDefaultMode);
		
		controllerHID = hid;
		
		pending = [[NSMutableData alloc] init];
		
		[self setReady:YES];

		wakeup = [[NSTimer scheduledTimerWithTimeInterval:0.50 target:self selector:@selector(checkQueue:) userInfo:nil repeats:YES] retain];
	}
	
	return self;
}

- (void) checkQueue:(NSTimer *) theTimer
{
	if ([lastUpdate timeIntervalSinceNow] < -30)
		ready = YES;
	
	[self transmitBytes];
}

- (void) transmitBytes
{
	if (!ready) // TODO: Reset ready on freezes...
		return;

	if ([pending length] > 0)
	{
		unsigned char size = 3;
		
		if (size > [pending length])
			size = [pending length];
		
		NSRange range = NSMakeRange (0, size);
		
		NSMutableData * dataLine = [NSMutableData data];
		
		[dataLine appendBytes:&size length:1];
		[dataLine appendData:[pending subdataWithRange:range]];
		[pending replaceBytesInRange:range withBytes:NULL length:0];
		
		[self sendBytes:dataLine];
	}
	else
	{
		if ([commandQueue count] > 0)
		{
			if (currentCommand != nil)
			{
				[currentCommand release];
				currentCommand = nil;
			}
			
			currentCommand = [[commandQueue objectAtIndex:0] retain];
			[commandQueue removeObjectAtIndex:0];

			if ([currentCommand isMemberOfClass:[ASAggregateCommand class]])
			{
				NSArray * commands = [((ASAggregateCommand *) currentCommand) commands];
				
				for (unsigned int i = [commands count]; i > 0; i--)
					[commandQueue insertObject:[commands objectAtIndex:(i - 1)] atIndex:0];
				
				[currentCommand release];
				currentCommand = nil;
			}
			else
			{
				NSNumber * transmit = (NSNumber *) [currentCommand valueForKey:NEEDS_TRANSMIT];
				
				if (transmit != nil && [transmit boolValue])
				{
					ASInsteonTransmitCommand * transmitCommand = [[ASInsteonTransmitCommand alloc] init];
					[transmitCommand setLastCommand:currentCommand];
					[commandQueue insertObject:transmitCommand atIndex:0];
					[transmitCommand release];
					
					[currentCommand setValue:[NSNumber numberWithBool:NO] forKey:NEEDS_TRANSMIT];
				}
				
				ASDevice * device = [currentCommand getDevice];
				
				if ([currentCommand isKindOfClass:[ASGetInfoCommand class]] && [[device getAddress] isKindOfClass:[ASInsteonAddress class]])
					[infoDevices addObject:device];
				
				NSData * commandData = (NSData *) [currentCommand valueForKey:COMMAND_BYTES];
				
				ShionLog(@"commandData = %@", commandData);

				if (commandData != nil)
				{
					unsigned char * bytes = (unsigned char *) [commandData bytes];

					ShionLog (@"*** command to transmit: %@ %@", currentCommand, [self stringForData:commandData]);

					if (![currentCommand isKindOfClass:[ASInsteonTransmitCommand class]])
						lastSubcommand = bytes[[commandData length] - 1];

					[pending appendData:commandData];
				}
			}
		}
	}
}

- (void) setReady:(BOOL) isReady
{
	ready = isReady;
}

- (BOOL) isFinished
{
	return ([pending length] == 0);
}

- (void) refresh
{
	[self sendNativeCommand:GET_VERSION];
}

- (void) resendCommand
{
	ShionLog (@"** resend command %@", currentCommand);
	
	if ([currentCommand isKindOfClass:[ASInsteonTransmitCommand class]])
	{
		ASInsteonTransmitCommand * transmit = (ASInsteonTransmitCommand *) currentCommand;
		
		ASCommand * lastCommand = [transmit lastCommand];
		
		if (lastCommand != nil && ![lastCommand isKindOfClass:[ASStatusCommand class]])
		{
			[lastCommand setValue:[NSNumber numberWithBool:YES] forKey:NEEDS_TRANSMIT];
			
			if (![commandQueue containsObject:lastCommand])
				[commandQueue insertObject:lastCommand atIndex:0];
		}
	}
	else if (currentCommand != nil)
	{
		if (![commandQueue containsObject:currentCommand])
			[commandQueue insertObject:currentCommand atIndex:0];
	}
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value;
{
	ASCommand * command = [super commandForDevice:device kind:commandKind value:value];
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isKindOfClass:[ASInsteonAddress class]])
	{
		unsigned char bytes[] = {0x02,0x40, 0x01,0xA4, 0x00,0x06, 0x00,0x00};
		
		NSMutableData * commandBytes = [NSMutableData dataWithBytes:bytes length:8];
		
		[commandBytes appendData:[self insteonDataForDevice:device command:command value:value]];
		
		[command setValue:commandBytes forKey:COMMAND_BYTES];
		[command setValue:[NSNumber numberWithBool:YES] forKey:NEEDS_TRANSMIT];
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
	ASAddress * deviceAddress = [device getAddress];

	ASCommand * command = nil;
	
	if ([deviceAddress isMemberOfClass:[ASInsteonAddress class]])
	{
		command = [super commandForDevice:device kind:commandKind];
		
		unsigned char bytes[] = {0x02,0x40, 0x01,0xA4, 0x00,0x06, 0x00,0x00};
		
		NSMutableData * commandBytes = [NSMutableData dataWithBytes:bytes length:8];
			
		[commandBytes appendData:[self insteonDataForDevice:device command:command]];
		
		[command setValue:commandBytes forKey:COMMAND_BYTES];
		[command setValue:[NSNumber numberWithBool:YES] forKey:NEEDS_TRANSMIT];
	}
	else if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		command = [super commandForDevice:device kind:commandKind];

		unsigned char commandByte = [self xtenCommandByteForDevice:device command:command];
		
		unsigned char code = [((ASX10Address *) [device getAddress]) getAddressByte];

		currentX10Address = code;
		
		ASAggregateCommand * aggCommand = [[[ASAggregateCommand alloc] init] autorelease];
		
		// Step 1: Address the target device.
		
		ASCommand * unitCodeCommand = [[ASCommand alloc] init];
		
		unsigned char bytes[] = {0x02, 0x40, 0x01, 0x65, 0x00, 0x01, 0xff, 0x33, code};
		NSMutableData * data = [NSMutableData dataWithBytes:bytes length:9];
		[unitCodeCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:unitCodeCommand];
		[unitCodeCommand release];
		
		ASCommand * unitCodeMaskCommand = [[ASCommand alloc] init];
		unsigned char ucmBytes[] = {0x02, 0x46, 0x01, 0x66, 0x80, 0xf7};
		data = [NSMutableData dataWithBytes:ucmBytes length:6];
		[unitCodeMaskCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:unitCodeMaskCommand];
		[unitCodeMaskCommand release];
		
		// Step 2: Send command.
		
		ASCommand * offCommand = [[ASCommand alloc] init];
		unsigned char cmdBytes[] = {0x02, 0x40, 0x01, 0x65, 0x00, 0x01, 0xff, 0x37, ((code & 0xf0) | commandByte)};
		data = [NSMutableData dataWithBytes:cmdBytes length:9];
		[offCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:offCommand];
		[offCommand release];
		
		ASCommand * maskCommand = [[ASCommand alloc] init];
		unsigned char maskBytes[] = {0x02, 0x46, 0x01, 0x66, 0x88, 0xff};
		data = [NSMutableData dataWithBytes:maskBytes length:6];
		[maskCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:maskCommand];
		[maskCommand release];
		
		command = aggCommand;
	}		
	
	return command;
}

- (void) processUploadMessage:(NSData *) message high:(unsigned char) high low:(unsigned char) low
{
	if (high == 0x01 && low == 0x64)
	{
		if ([message length] == 3)
		{
			unsigned char * bytes = (unsigned char *) [message bytes];
			
			unsigned char rbyte = bytes[0];
			unsigned char flags = bytes[2];
			
			unsigned char message[2];
			
			if ((flags & 0x04) == 0x04)
				message[0] = 0xff;
			else
				message[0] = 0x00;
			
			message[1] = rbyte;
			
			[self processX10Message:[NSData dataWithBytes:message length:2]];
		}
	}
	
	ShionLog (@"** process upload from 0x%02x%02x: %@", high, low, [self stringForData:message]);
}

- (void) processEvent:(unsigned char) event;
{
	if (event == 0x03)
	{
		
	}
	else if (event == 0x04)
	{
		
	}
	else
	{
		if (event == 0x08)
		{
			[self sendNativeCommand:FETCH_X10_BYTE];
		}
		
		ShionLog (@"** process event: 0x%02x", event);
	}
}

- (void) processGetVersion:(NSData *) message;
{
	unsigned char * bytes = (unsigned char *) [message bytes];
	
	[self setControllerAddress:[NSData dataWithBytes:bytes length:3]];
	[self setType:[ASInsteonDatabase stringForDeviceType:[NSData dataWithBytes:(bytes + 3) length:2]]];
	[self setControllerVersion:[[NSNumber alloc] initWithUnsignedChar:bytes[5]]];
}

- (void) close
{
	(*controllerHID)->close(controllerHID);
}

- (void) dealloc
{
	[pending release];
	[wakeup invalidate];
	
	[super dealloc];
}

- (void) sendNativeCommand:(unsigned int) commandKind
{
	ASStatusCommand * command = [[ASStatusCommand alloc] init];
	
	if (commandKind == GET_VERSION)
	{
		unsigned char bytes[]  = {0x02,0x48};
		NSMutableData * data = [NSMutableData dataWithBytes:bytes length:2];
		
		[command setValue:data forKey:COMMAND_BYTES];
		[command setValue:[NSNumber numberWithBool:NO] forKey:NEEDS_TRANSMIT];
	}
	else if (commandKind == RESET_PLC)
	{
		unsigned char bytes[]  = {0x02,0x40, 0x01,0x6c, 0x00,0x01, 0x00,0x00, 0x80};
		NSMutableData * data = [NSMutableData dataWithBytes:bytes length:9];
		
		[command setValue:data forKey:COMMAND_BYTES];
		[command setValue:[NSNumber numberWithBool:NO] forKey:NEEDS_TRANSMIT];
	}
	else if (commandKind == FETCH_X10_BYTE)
	{
		unsigned char bytes[]  = {0x02, 0x42, 0x01, 0x64, 0x00, 0x03};
		NSMutableData * data = [NSMutableData dataWithBytes:bytes length:6];
		
		[command setValue:data forKey:COMMAND_BYTES];
		[command setValue:[NSNumber numberWithBool:NO] forKey:NEEDS_TRANSMIT];
	}
	
	[self queueCommand:command];
	
	[command release];
}

@end
