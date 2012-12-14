//
//  ASCM11AController.m
//  Shion Framework
//
//  Created by Chris Karr on 1/2/09.
//  Copyright 2009 Audacious Software. 
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

#import "ASCM11AController.h"
#import "ASX10Address.h"

#include <termios.h>
#include <sys/ioctl.h>

#define WAITING 0x00
#define AWAITING_TRANSMISSION 0x01
#define AWAITING_CHECKSUM 0x02
#define AWAITING_ACK 0x03

@implementation ASCM11AController

- (void) processIncomingX10:(NSData *) data
{
	unsigned char * bytes = (unsigned char *) [data bytes];
	
	if ((bytes[1] & 0x01) == 0x01 && ((bytes[2] & 0x0f) == 0x0e) || ((bytes[2] & 0x0d) == 0x0d))
	{
		unsigned char function = bytes[2];
		
		unsigned char bytes[] = {0x01, function};
		
		NSData * x10Data = [NSData dataWithBytes:bytes length:2];

		[self processX10Message:x10Data];
	}
	else if ((bytes[1] & 0x02) == 0x02)
	{
		currentX10Address = bytes[2];
		unsigned char function = bytes[3];

		unsigned char bytes[] = {0x01, function};
		
		NSData * x10Data = [NSData dataWithBytes:bytes length:2];
		
		[self processX10Message:x10Data];
	}
	else
		ShionLog (@"Unknown Upload = %@", data);
}

- (void) read:(NSNotification *) theNote
{
	NSData * data = [[theNote userInfo] valueForKey:NSFileHandleNotificationDataItem];

	ShionLog (@"Read: %@", data);
	
	if ([data length] > 0)
	{
		unsigned char * bytes = (unsigned char *) [data bytes];
		unsigned int length = [data length];
		
		if (state == WAITING)
		{
			if (length == 1)
			{
				if (bytes[0] == 0x5a)
				{
					unsigned char reply[] = {0xc3};
					
					NSData * replyData = [[NSData alloc] initWithBytes:reply length:1];
					[self write:replyData];
					[replyData release];
					
					state = AWAITING_TRANSMISSION;
					
					[buffer setData:[NSData data]];
				}
				if (bytes[0] == 0xa5)
				{
/*					unsigned char reply[] = {0x9b};
					
					NSData * replyData = [[NSData alloc] initWithBytes:reply length:1];
					[self write:replyData];
					[replyData release]; 
					
					state = WAITING;
					
					[buffer setData:[NSData data]]; */
					
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
					
					[self write:setTime];
					
					return;
				}
			}
		}
		else if (state == AWAITING_TRANSMISSION)
		{
			unsigned char expected = 0;

			[buffer appendBytes:bytes length:length];
			
			if ([buffer length] >= 2)
			{
				unsigned char * bufBytes = (unsigned char *) [buffer bytes];
				expected = bufBytes[0] + 1;
			}
			
			if (expected > 0 && [buffer length] >= expected)
			{
				[self processIncomingX10:[buffer subdataWithRange:NSMakeRange(0, expected)]];
				// TODO: Do process upload.
				// NSData * upload = [buffer subdataWithRange:NSMakeRange(0, expected)];
				
				[buffer replaceBytesInRange:NSMakeRange(0, expected) withBytes:NULL length:0];
				
				if ([buffer length] == 0)
					state = WAITING;
			}
		}
		else if (state == AWAITING_CHECKSUM)
		{
			if (bytes[0] == checksum)
			{
				unsigned char reply[] = {0x00};
				
				NSData * replyData = [[NSData alloc] initWithBytes:reply length:1];
				[self write:replyData];
				[replyData release];
				
				state = AWAITING_ACK;
			}
			else if (bytes[0] == 0x5a)
			{
				unsigned char reply[] = {0xc3};
				
				NSData * replyData = [[NSData alloc] initWithBytes:reply length:1];
				[self write:replyData];
				[replyData release];
				
				state = AWAITING_TRANSMISSION;
				
				[buffer setData:[NSData data]];
			}
			else
			{
				[commandQueue insertObject:currentCommand atIndex:0];
				
				state = WAITING;
			}
		}
		else if (state == AWAITING_ACK)
		{
			if (bytes[0] == 0x55)
				state = WAITING;
			else if (bytes[0] == 0x5a)
			{
				unsigned char reply[] = {0xc3};
				
				NSData * replyData = [[NSData alloc] initWithBytes:reply length:1];
				[self write:replyData];
				[replyData release];
					
				state = AWAITING_TRANSMISSION;
					
				[buffer setData:[NSData data]];
			}
		}
	}
	
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	
	[handle readInBackgroundAndNotify];
}

- (void) write:(NSData *) data
{
	ShionLog (@"Writing: %@", data);
	
	[handle writeData:data];
	[handle readInBackgroundAndNotify];
}

- (ASCM11AController *) initWithPath:(NSString *) path
{
	if (self = [super init])
	{
		const char * deviceFilePath = [path cStringUsingEncoding:NSASCIIStringEncoding];
		
		int fd = open (deviceFilePath, O_RDWR | O_NONBLOCK);
		
		if (fd != -1)
		{
			struct termios options;
			tcgetattr(fd, &options);
		
			memset(&options, 0, sizeof(struct termios));
			cfmakeraw(&options);
			cfsetspeed(&options, 4800);
			options.c_cflag = CREAD |  CLOCAL | CS8;

			tcsetattr(fd, TCSANOW, &options);
		
			int modem = 0;
		
			ioctl(fd, TIOCMGET, &modem);
			modem |= TIOCM_DTR;
			ioctl(fd, TIOCMSET, &modem);        
		
			handle = [[NSFileHandle alloc] initWithFileDescriptor:fd];
			[handle readInBackgroundAndNotify];
		
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(read:) name:NSFileHandleReadCompletionNotification object:handle];
			wakeup = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkQueue:) userInfo:nil repeats:YES] retain];
			
			state = WAITING;
			
			buffer = [[NSMutableData alloc] init];
			
			return self;
		}
	}
	
	return nil;
}

- (void) close
{
	[handle closeFile];
}

- (void) dealloc
{
	[handle release];
	[wakeup invalidate];
	[buffer release];
	
	[super dealloc];
}

+ (ASCM11AController *) controllerWithPath:(NSString *) path
{
	ASCM11AController * controller = nil;

	controller = [[ASCM11AController alloc] initWithPath:path];
	
	return [controller autorelease];
}


- (void) transmitBytes
{
	if (state != WAITING)
		return;
	
	if ([commandQueue count] > 0)
	{
		currentCommand = [[commandQueue objectAtIndex:0] retain];
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
			
			if (commandData != nil)
			{
				unsigned char * bytes = (unsigned char *) [commandData bytes];
				unsigned int length = [commandData length];
				
				if (bytes[0] == 0x04)
					currentX10Address = bytes[1];
				
				checksum = 0x00;
				
				int i = 0;
				for (i = 0; i < length; i++)
					checksum += bytes[i];
				
				checksum = checksum & 0xff;
				
				ShionLog (@"*** CM11A: command to transmit: %@ (checksum: 0x%x)", [self stringForData:commandData], checksum);
				[self write:commandData];
				
				state = AWAITING_CHECKSUM;
			}
		}
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