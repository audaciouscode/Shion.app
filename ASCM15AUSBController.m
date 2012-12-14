//
// ASCM15AUSBController.m
// Shion Framework
//
// Created by Chris Karr on 1/1/09.
// Copyright 2009 Audacious Software. 
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

#import "ASCM15AUSBController.h"
#import "ASCommands.h"
#import "ASX10Address.h"
#import "ASToggleDevice.h"

#include <time.h>

#define VENDOR_ID 0x0bc7
#define PRODUCT_ID 0x0001

#define WRITE_ENDPOINT 0x02
#define READ_ENDPOINT 0x81

#define READ_BUFFER_SIZE 128

static IONotificationPortRef gNotifyPort;
static io_iterator_t gRawAddedIter;

static unsigned char read_buffer[READ_BUFFER_SIZE];

static ASCM15AUSBController * controllerInstance = nil;

// --? static unsigned char lastUnit;
// --? static unsigned char lastCommand;
// --? Ready?

static BOOL fifteenReady = YES;

void ReadCompletion(void *refCon, IOReturn result, void *arg0)
{
	ASCM15AUSBController * controller = (ASCM15AUSBController *) refCon;

	IOUSBInterfaceInterface** usb = [controller getUSB];

	int length = (int) arg0;

	NSMutableString * string = [NSMutableString string];
	
	for (int i = 0; i < length; i++)
		[string appendFormat:@"0x%02x ", read_buffer[i]];
	
	if (length == 1)
	{
		if (read_buffer[0] == 0x55)
			[controller transmitBytes];
		else if (read_buffer[0] == 0xa5)
		{
			// Adapted from http://home.comcast.net/~ncherry/common/cm15d/cm15a.html
			
			NSMutableData * setTime = [NSMutableData data];
			
			time_t t;
			time(&t);
			struct tm * lt = localtime(&t);
			
			unsigned char b[8];
			
			b[0]= 0x9b;
			b[1] = lt->tm_sec;
			b[2] = lt->tm_min + 60 * (lt->tm_hour & 1);
			b[3] = lt->tm_hour >> 1;
			b[4] = lt->tm_yday;
			b[5] = 1 << lt->tm_wday;

			if(lt->tm_yday & 0x100) 			
				b[5] |= 0x80;

			b[6] = 0x60;
			b[7] = 0x00;
			
			[setTime appendBytes:b length:8];

			[controller sendBytes:setTime];

			return;
		}
	}
	else if (length > 1)
	{
		if (read_buffer[0] == 0x5a)
		{
			unsigned char size = read_buffer[1];
				
			if (size == 2)
			{
				if (read_buffer[2] < 0x02)
				{
					unsigned char bytes[] = {read_buffer[2], read_buffer[3]};
				
					[controller processX10Message:[NSData dataWithBytes:bytes length:2]];
				}
			}
		}
		else if (read_buffer[0] == 0x5d)
		{
			// Ignore radio?
		}
	}
	
	(*usb)->ReadPipeAsync(usb, 1, read_buffer, READ_BUFFER_SIZE, ReadCompletion, controller);
}

void WriteCompletion(void *refCon, IOReturn result, void *arg0)
{
	ASCM15AUSBController * controller = (ASCM15AUSBController *) refCon;
	IOUSBInterfaceInterface** usb = [controller getUSB];
	
	(*usb)->ReadPipeAsync(usb, 1, read_buffer, READ_BUFFER_SIZE, ReadCompletion, controller);
	
	fifteenReady = YES;
}

IOReturn FindInterfaces (IOUSBDeviceInterface **device)
{
    IOReturn kr;
    IOUSBFindInterfaceRequest request;
    io_iterator_t iterator;
    io_service_t usbInterface;
    IOCFPlugInInterface **plugInInterface = NULL;
    IOUSBInterfaceInterface **interface = NULL;
    HRESULT result;
    SInt32 score;
    UInt8 interfaceClass;
    UInt8 interfaceSubClass;
    UInt8 interfaceNumEndpoints;
    // int pipeRef;
	
	CFRunLoopSourceRef runLoopSource;
	
    request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting = kIOUSBFindInterfaceDontCare;

    kr = (*device)->CreateInterfaceIterator(device, &request, &iterator);
    while (usbInterface = IOIteratorNext(iterator))
    {
        IOCreatePlugInInterfaceForService(usbInterface, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);

        kr = IOObjectRelease(usbInterface);

        if ((kr != kIOReturnSuccess) || !plugInInterface)
        {
            ShionLog (@"Unable to create a plug-in (%08x)", kr);
            break;
        }
		
        result = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), (LPVOID *) &interface);
        (*plugInInterface)->Release(plugInInterface);
		
        if (result || !interface)
        {
            ShionLog (@"Couldn’t create a device interface for the interface (%08x)", (int) result);
            break;
        }

        (*interface)->GetInterfaceClass(interface, &interfaceClass);
        (*interface)->GetInterfaceSubClass(interface, &interfaceSubClass);
		
        ShionLog (@"Interface class %d, subclass %d", interfaceClass, interfaceSubClass);
		
        kr = (*interface)->USBInterfaceOpen(interface);
        if (kr != kIOReturnSuccess)
        {
            ShionLog (@"Unable to open interface (%08x)", kr);
            (void) (*interface)->Release(interface);
            break;
        }
		
        kr = (*interface)->GetNumEndpoints(interface, &interfaceNumEndpoints);
        if (kr != kIOReturnSuccess)
        {
            ShionLog (@"Unable to get number of endpoints (%08x)", kr);
            (void) (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            break;
        }
		
        ShionLog (@"Interface has %d endpoints", interfaceNumEndpoints);
		
		
		//As with service matching notifications, to receive asynchronous
        //I/O completion notifications, you must create an event source and
        //add it to the run loop

        kr = (*interface)->CreateInterfaceAsyncEventSource(interface, &runLoopSource);

        if (kr != kIOReturnSuccess)
        {
            ShionLog (@"Unable to create asynchronous event source (%08x)", kr);
            (void) (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            break;
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
        ShionLog (@"Asynchronous event source added to run loop");
		
		if (controllerInstance == nil)
		{
			ShionLog (@"Initing new controller");
			controllerInstance = [[ASCM15AUSBController alloc] initWithUSB:interface];
		}
		else
		{
			ShionLog (@"Setting USB interface on existing controller");
			[controllerInstance setUSB:interface];
		}

        break;
    }
	
    return kr;
}

void DeviceAdded (void *refCon, io_iterator_t iterator)
{
	kern_return_t kr;
	io_service_t usbDevice;
	IOUSBDeviceInterface **device = NULL;
	IOCFPlugInInterface **plugInInterface = NULL;
	HRESULT result;
    SInt32 score;
	
	while (usbDevice = IOIteratorNext(iterator))
	{
        IOCreatePlugInInterfaceForService(usbDevice, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
        kr = IOObjectRelease(usbDevice);
        
		if ((kIOReturnSuccess != kr) || !plugInInterface)
		{
            ShionLog (@"Unable to create a plug-in (%08x)", kr);
            continue;
        }

        result = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID *) &device);
        (*plugInInterface)->Release(plugInInterface);
		
        if (result || !device)
        {
            ShionLog (@"Couldn’t create a device interface (%08x)", (int) result);
            continue;
        }
		
		(*device)->USBDeviceOpen(device);

		ShionLog(@"CM15a: Finding interfaces...");

		kr = FindInterfaces(device);

		if (kr != kIOReturnSuccess)
		{
			ShionLog (@"Unable to find interfaces on device: %08x", kr);
			(*device)->USBDeviceClose(device);
			(*device)->Release(device);
			continue;
		}
	}
}

@implementation ASCM15AUSBController


- (void) setUSB: (IOUSBInterfaceInterface**) usb
{
	controllerUSB = usb;
}

- (void) closeController
{
	ShionLog(@"%@: Closing controller..", [self className]);
	
	[self close];
}

- (void) resetController
{
	ShionLog(@"%@: Connecting...", [self className]);
	
	[ASCM15AUSBController findController];
}

- (void) sendBytes:(NSData *) bytes
{
	fifteenReady = NO;
	
	ShionLog(@"Write: %@", bytes);
	
	(*controllerUSB)->WritePipeAsync(controllerUSB, 2, (void *) [bytes bytes], (int) [bytes length], WriteCompletion, self);
}	

+ (ASCM15AUSBController *) findController
{
	CFMutableDictionaryRef matchingDict = NULL;
	
	matchingDict = IOServiceMatching (kIOUSBDeviceClassName);
	
	if (matchingDict)
	{
		mach_port_t masterPort;
		CFRunLoopSourceRef runLoopSource;
		kern_return_t kr;
		
		kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
			
		if (kr || !masterPort)
			ShionLog (@"ERR: Couldn’t create a master I/O Kit port(%08x)", kr);
		else
		{
			ShionLog(@"%@: Got master port...", [self className]);

			int val = VENDOR_ID;
			CFNumberRef valRef = CFNumberCreate (kCFAllocatorDefault, kCFNumberSInt32Type, &val);
			CFDictionarySetValue (matchingDict, CFSTR(kUSBVendorID), valRef);
			CFRelease (valRef);
				
			val = PRODUCT_ID;
			valRef = CFNumberCreate (kCFAllocatorDefault, kCFNumberSInt32Type, &val);
			CFDictionarySetValue (matchingDict, CFSTR(kUSBProductID), valRef);
			CFRelease (valRef);
				
			gNotifyPort = IONotificationPortCreate(masterPort);
			runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
			CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
			
			matchingDict = (CFMutableDictionaryRef) CFRetain(matchingDict);

			ShionLog(@"%@: DeviceAdded...", [self className]);

			IOServiceAddMatchingNotification(gNotifyPort, kIOFirstMatchNotification, matchingDict, DeviceAdded, NULL, &gRawAddedIter);
			DeviceAdded(NULL, gRawAddedIter);
		}
	}
	
	return controllerInstance;
}

- (IOUSBInterfaceInterface**) getUSB
{
	return controllerUSB;
}

- (ASCM15AUSBController *) initWithUSB:(IOUSBInterfaceInterface**) usb
{
 	if (self = [super init])
	{
		controllerUSB = usb;

		fifteenReady = YES;
		
		wakeup = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkQueue:) userInfo:nil repeats:YES] retain];
		
		(*usb)->ReadPipeAsync(usb, 1, read_buffer, READ_BUFFER_SIZE, ReadCompletion, self);
	}

	return self;
}

- (void) close
{
	if (controllerUSB != nil)
	{
		(void) (*controllerUSB)->USBInterfaceClose(controllerUSB);
		(void) (*controllerUSB)->Release(controllerUSB);

		controllerUSB = nil;
	}
}

- (void) transmitBytes
{
	if (!fifteenReady || controllerUSB == nil)
		return;
	
	if ([commandQueue count] > 0)
	{
		ASCommand * currentCommand = [[commandQueue objectAtIndex:0] retain];
		[commandQueue removeObjectAtIndex:0];
			
		if ([currentCommand isMemberOfClass:[ASAggregateCommand class]])
		{
			NSArray * commands = [((ASAggregateCommand *) currentCommand) commands];
			
			[commandQueue addObjectsFromArray:commands];

			[self transmitBytes];
		}
		else
		{
			NSData * commandData = (NSData *) [currentCommand valueForKey:COMMAND_BYTES];

			unsigned char * bytes = (unsigned char *) [commandData bytes];

			if (bytes[0] == 0x04)
				currentX10Address = bytes[1];

			if (commandData != nil)
				[self sendBytes:commandData];
		}
		
		// [currentCommand release];
	}
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value
{
	ASCommand * command = nil;
	
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		command = [super commandForDevice:device kind:commandKind value:value];
		
		unsigned char code = [((ASX10Address *) [device getAddress]) getAddressByte];
		
		currentX10Address = code;
		
		ASAggregateCommand * aggCommand = [[[ASAggregateCommand alloc] init] autorelease];
		
		// Step 1: Address the target device.
		
		ASCommand * unitCodeCommand = [[ASCommand alloc] init];
		unsigned char bytes[] = {0x04, code};
		NSMutableData * data = [NSMutableData dataWithBytes:bytes length:2];
		[unitCodeCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:unitCodeCommand];
		[unitCodeCommand release];
		
		unsigned char commandByte = [self xtenCommandByteForDevice:device command:command];
		
		// Step 2: Send command.
		
		ASCommand * cmdCommand = [[ASCommand alloc] init];
		unsigned char cmdBytes[] = {0x26, ((code & 0xf0) | commandByte)};
		data = [NSMutableData dataWithBytes:cmdBytes length:2];
		[cmdCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:cmdCommand];
		[cmdCommand release];
		
		command = aggCommand;
	}		
	
	return command;
}

- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind
{
	ASCommand * command = nil;
	
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		command = [super commandForDevice:device kind:commandKind];
		
		unsigned char code = [((ASX10Address *) [device getAddress]) getAddressByte];
		
		currentX10Address = code;
		
		ASAggregateCommand * aggCommand = [[[ASAggregateCommand alloc] init] autorelease];
		
		// Step 1: Address the target device.
		
		ASCommand * unitCodeCommand = [[ASCommand alloc] init];
		unsigned char bytes[] = {0x04, code};
		NSMutableData * data = [NSMutableData dataWithBytes:bytes length:2];
		[unitCodeCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:unitCodeCommand];
		[unitCodeCommand release];
		
		unsigned char commandByte = [self xtenCommandByteForDevice:device command:command];
		
		// Step 2: Send command.
		
		ASCommand * cmdCommand = [[ASCommand alloc] init];
		unsigned char cmdBytes[] = {0x26, ((code & 0xf0) | commandByte)};
		data = [NSMutableData dataWithBytes:cmdBytes length:2];
		[cmdCommand setValue:data forKey:COMMAND_BYTES];
		[aggCommand addCommand:cmdCommand];
		[cmdCommand release];
		
		command = aggCommand;
	}		
	
	return command;
}

- (void) checkQueue:(NSTimer *) theTimer
{
	[self transmitBytes];
}

@end
