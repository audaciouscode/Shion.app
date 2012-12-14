//
//  ASPowerLinc1132Controller.m
//  Shion Framework
//
//  Created by Chris Karr on 4/2/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASPowerLinc1132Controller.h"
#import "ASCommands.h"
#import "ASX10Address.h"

#define VENDOR_ID 0x10bf
#define PRODUCT_ID 0x0001

#define X10_CONTROLLER @"X10 Controller"
#define BUFFER_SIZE 8

unsigned char buffer[BUFFER_SIZE];

BOOL process1132Response (NSMutableData * response)
{
	ASPowerLinc1132Controller * controller = [[[NSThread currentThread] threadDictionary] valueForKey:X10_CONTROLLER];

	if ([response length] == 4)
	{
		unsigned char * bytes = (unsigned char *) [response bytes];
	
		unsigned char houseCode = 0x00;
		
		switch (bytes[2]) 
		{
			case 0x41:
				houseCode = 0x60;
				break;
			case 0x42:
				houseCode = 0xe0;
				break;
			case 0x43:
				houseCode = 0x20;
				break;
			case 0x44:
				houseCode = 0xa0;
				break;
			case 0x45:
				houseCode = 0x10;
				break;
			case 0x46:
				houseCode = 0x90;
				break;
			case 0x47:
				houseCode = 0x50;
				break;
			case 0x48:
				houseCode = 0xd0;
				break;
			case 0x49:
				houseCode = 0x70;
				break;
			case 0x4a:
				houseCode = 0xf0;
				break;
			case 0x4b:
				houseCode = 0x30;
				break;
			case 0x4c:
				houseCode = 0xb0;
				break;
			case 0x4d:
				houseCode = 0x00;
				break;
			case 0x4e:
				houseCode = 0x80;
				break;
			case 0x4f:
				houseCode = 0x40;
				break;
			case 0x50:
				houseCode = 0xc0;
				break;
			default:
				break;
		}		

		BOOL isCmd = ((0x20 & bytes[3]) == 0x20);

		if (isCmd)
		{
			unsigned char cmdByte = 0x00;
			
			switch (bytes[3]) 
			{
				case 0x6d:
					cmdByte = 0x00;
					break;
				case 0x65:
					cmdByte = 0x01;
					break;
				case 0x63:
					cmdByte = 0x02;
					break;
				case 0x6b:
					cmdByte = 0x03;
					break;
				case 0x6f:
					cmdByte = 0x04;
					break;
				case 0x67:
					cmdByte = 0x05;
					break;
				case 0x61:
					cmdByte = 0x06;
					break;
				case 0x69:
					cmdByte = 0x07;
					break;
				case 0x6e:
					cmdByte = 0x08;
					break;
				case 0x6c:
					cmdByte = 0x0a;
					break;
				case 0x64:
					cmdByte = 0x0b;
					break;
				case 0x71:
					cmdByte = 0x0c;
					break;
				case 0x68:
					cmdByte = 0x0d;
					break;
				case 0x62:
					cmdByte = 0x0e;
					break;
				case 0x6a:
					cmdByte = 0x0f;
					break;
				case 0x66:
					cmdByte = 0x09;
					break;
				default:
					break;
			}
			
			unsigned char command = houseCode | cmdByte;
			
			unsigned char cmdBytes[] = {0x01, command};
			
			[controller processX10Message:[NSData dataWithBytes:cmdBytes length:2]];
		}
		else
		{
			unsigned char unitCode = 0x00;
			
			switch (bytes[3])
			{
				case 0x41:
					unitCode = 0x06;
					break;
				case 0x42:
					unitCode = 0x0e;
					break;
				case 0x43:
					unitCode = 0x02;
					break;
				case 0x44:
					unitCode = 0x0a;
					break;
				case 0x45:
					unitCode = 0x01;
					break;
				case 0x46:
					unitCode = 0x09;
					break;
				case 0x47:
					unitCode = 0x05;
					break;
				case 0x48:
					unitCode = 0x0d;
					break;
				case 0x49:
					unitCode = 0x07;
					break;
				case 0x4a:
					unitCode = 0x0f;
					break;
				case 0x4b:
					unitCode = 0x03;
					break;
				case 0x4c:
					unitCode = 0x0b;
					break;
				case 0x4d:
					unitCode = 0x00;
					break;
				case 0x4e:
					unitCode = 0x08;
					break;
				case 0x4f:
					unitCode = 0x04;
					break;
				case 0x50:
					unitCode = 0x0c;
					break;
				default:
					break;
			}
			
			unsigned char unit = houseCode | unitCode;

			unsigned char unitBytes[] = {0x00, unit};
			
			[controller processX10Message:[NSData dataWithBytes:unitBytes length:2]];
		}
		
		[response replaceBytesInRange:NSMakeRange(0, 4) withBytes:NULL length:0];
		
		return YES;
	}
	
	return NO;
}

static void callback (void * target, IOReturn result, void * o, void * p)
{
	NSMutableData * responseData = [[[NSThread currentThread] threadDictionary] valueForKey:@"Response"];
	
	if (responseData == nil)
	{
		[[[NSThread currentThread] threadDictionary] setValue:[NSMutableData data] forKey:@"Response"];
		return callback (target, result, o, p);
	}
	
	unsigned int i = 0;
	for (i = 0; i <= BUFFER_SIZE; i++)
	{
		if (*(buffer+i) != 0x00)
			[responseData appendBytes:(buffer+i) length:1];
	}

	ASPowerLinc1132Controller * controller = [[[NSThread currentThread] threadDictionary] valueForKey:X10_CONTROLLER];

	ShionLog (@"response buffer = %@", [controller stringForData:responseData]);
	
	/* BOOL complete = */ process1132Response (responseData);

	memset(buffer, 0, BUFFER_SIZE);
}

@implementation ASPowerLinc1132Controller

- (void) sendBytes:(NSData *) bytes
{
	@synchronized(self)
	{
		ShionLog(@"SEND: %@", [self stringForData:bytes]);
		
		kern_return_t result = (*controllerHID)->setReport (controllerHID, kIOHIDReportTypeOutput, 0, (void *) [bytes bytes], [bytes length], 5000, NULL, NULL, NULL);
		
		if (result != KERN_SUCCESS)
			ErrorLog(@"Error encountered sending data to controller.", result);
	}
}

+ (ASPowerLinc1132Controller *) findController
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
		
		ASPowerLinc1132Controller * controller = [[ASPowerLinc1132Controller alloc] initWithHID:hid];
		
		[[[NSThread currentThread] threadDictionary] setValue:controller forKey:X10_CONTROLLER];
		
		[controller refresh];
		
		return [controller autorelease];
	}
	else
	{
		ShionLog(@"Unable to find PowerLinc USB 1132 controller.");
		return nil;
	}
}

- (ASPowerLinc1132Controller *) initWithHID:(IOHIDDeviceInterface122**) hid
{
	memset(buffer, 0, BUFFER_SIZE);

	if (self = [super init])
	{
		address = nil;
		
		mach_port_t port;
		CFRunLoopSourceRef eventSource;
		
		(*hid)->createAsyncPort (hid, &port);
		(*hid)->createAsyncEventSource (hid, &eventSource);
		
		kern_return_t result = (*hid)->open(hid, 0);
		
		if (result != KERN_SUCCESS)
			ErrorLog(@"Error opening HID device.", result);
		
		result = (*hid)->setInterruptReportHandlerCallback (hid, buffer, sizeof(buffer), (IOHIDReportCallbackFunction) callback, NULL, NULL);
		
		if (result != KERN_SUCCESS)
			ErrorLog(@"Error setting device callback.", result);
		
		(*hid)->startAllQueues (hid);
		
		CFRunLoopAddSource (CFRunLoopGetCurrent(), eventSource, kCFRunLoopDefaultMode);
		
		controllerHID = hid;
		
		pending = [[NSMutableData alloc] init];
		
		wakeup = [[NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(checkQueue:) userInfo:nil repeats:YES] retain];
	}
	
	return self;
}

- (void) checkQueue:(NSTimer *) theTimer
{
	[self transmitBytes];
}

- (void) transmitBytes
{
	if ([pending length] > 0)
	{
		ShionLog(@"PENDING XMIT");
		NSMutableData * dataLine = [NSMutableData dataWithData:pending];

		unsigned char padding = 0x00;
		
		while ([dataLine length] < 8)
			[dataLine appendBytes:&padding length:1];
		
		[self sendBytes:dataLine];
		
		[pending setData:[NSData data]];
	}
	else
	{
		if ([commandQueue count] > 0)
		{
			ShionLog(@"PREPING CMD");

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
				NSData * commandData = (NSData *) [currentCommand valueForKey:COMMAND_BYTES];
				
				if (commandData != nil)
				{
					ShionLog (@"*** command to transmit: %@ %@", currentCommand, [self stringForData:commandData]);
					
					[pending appendData:commandData];
					
					[self transmitBytes];
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

- (void) resendCommand
{
	ShionLog (@"** resend command %@", currentCommand);
	
	if (currentCommand != nil)
	{
		if (![commandQueue containsObject:currentCommand])
			[commandQueue insertObject:currentCommand atIndex:0];
	}
}

- (void) codesForX10Address:(unsigned char) x10Address buffer:(unsigned char *) buf
{
	switch (x10Address & 0xf0) 
	{
		case 0x60:
			buf[0] = 0x41;
			break;
		case 0xe0:
			buf[0] = 0x42;
			break;
		case 0x20:
			buf[0] = 0x43;
			break;
		case 0xa0:
			buf[0] = 0x44;
			break;
		case 0x10:
			buf[0] = 0x45;
			break;
		case 0x90:
			buf[0] = 0x46;
			break;
		case 0x50:
			buf[0] = 0x47;
			break;
		case 0xd0:
			buf[0] = 0x48;
			break;
		case 0x70:
			buf[0] = 0x49;
			break;
		case 0xf0:
			buf[0] = 0x4a;
			break;
		case 0x30:
			buf[0] = 0x4b;
			break;
		case 0xb0:
			buf[0] = 0x4c;
			break;
		case 0x00:
			buf[0] = 0x4d;
			break;
		case 0x80:
			buf[0] = 0x4e;
			break;
		case 0x40:
			buf[0] = 0x4f;
			break;
		case 0xc0:
			buf[0] = 0x50;
			break;
		default:
			break;
	}		
	
	
	switch (x10Address & 0x0f)
	{
		case 0x06:
			buf[1] = 0x41;
			break;
		case 0x0e:
			buf[1] = 0x42;
			break;
		case 0x02:
			buf[1] = 0x43;
			break;
		case 0x0a:
			buf[1] = 0x44;
			break;
		case 0x01:
			buf[1] = 0x45;
			break;
		case 0x09:
			buf[1] = 0x46;
			break;
		case 0x05:
			buf[1] = 0x47;
			break;
		case 0x0d:
			buf[1] = 0x48;
			break;
		case 0x07:
			buf[1] = 0x49;
			break;
		case 0x0f:
			buf[1] = 0x4a;
			break;
		case 0x03:
			buf[1] = 0x4b;
			break;
		case 0x0b:
			buf[1] = 0x4c;
			break;
		case 0x00:
			buf[1] = 0x4d;
			break;
		case 0x08:
			buf[1] = 0x4e;
			break;
		case 0x04:
			buf[1] = 0x4f;
			break;
		case 0x0c:
			buf[1] = 0x50;
			break;
		default:
			break;
	}
}

- (unsigned char) codeForX10Command:(unsigned char) x10Command
{
	unsigned char cmdByte = 0x00;
	
	switch (x10Command) 
	{
		case 0x00:
			cmdByte = 0x6d;
			break;
		case 0x01:
			cmdByte = 0x65;
			break;
		case 0x02:
			cmdByte = 0x63;
			break;
		case 0x03:
			cmdByte = 0x6b;
			break;
		case 0x04:
			cmdByte = 0x6f;
			break;
		case 0x05:
			cmdByte = 0x67;
			break;
		case 0x06:
			cmdByte = 0x61;
			break;
		case 0x07:
			cmdByte = 0x69;
			break;
		case 0x08:
			cmdByte = 0x6e;
			break;
		case 0x0a:
			cmdByte = 0x6c;
			break;
		case 0x0b:
			cmdByte = 0x64;
			break;
		case 0x0c:
			cmdByte = 0x71;
			break;
		case 0x0d:
			cmdByte = 0x68;
			break;
		case 0x0e:
			cmdByte = 0x62;
			break;
		case 0x0f:
			cmdByte = 0x6a;
			break;
		case 0x09:
			cmdByte = 0x66;
			break;
		default:
			break;
	}
	
	return cmdByte;
}

- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind
{
	ASCommand * command = nil;
	
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		command = [super commandForDevice:device kind:commandKind];
		
		unsigned char commandByte = [self xtenCommandByteForDevice:device command:command];
		
		unsigned char code = [((ASX10Address *) [device getAddress]) getAddressByte];
		
		currentX10Address = code;
		
		unsigned char localAddress[2];
		[self codesForX10Address:code buffer:localAddress];
		
		unsigned char localCommand = [self codeForX10Command:commandByte];
		
		ASAggregateCommand * aggCommand = [[[ASAggregateCommand alloc] init] autorelease];
		
		// Step 1: Address the target device.
		
		ASCommand * unitCodeCommand = [[ASCommand alloc] init];
		
		unsigned char bytes[] = {0x00, localAddress[0], localAddress[1]};
		NSMutableData * data = [NSMutableData dataWithBytes:bytes length:3];
		[unitCodeCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:unitCodeCommand];
		[unitCodeCommand release];
		
		// Step 2: Send command.
		
		ASCommand * offCommand = [[ASCommand alloc] init];
		unsigned char cmdBytes[] = {0x01, localAddress[0], localCommand};
		data = [NSMutableData dataWithBytes:cmdBytes length:3];
		[offCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:offCommand];
		[offCommand release];
		
		command = aggCommand;
	}		
	
	return command;
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

@end
