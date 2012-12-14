//
//  ASCM17AController.m
//  Shion Framework
//
//  Created by Chris Karr on 10/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASCM17AController.h"
#import "ASCommands.h"
#import "ASX10Address.h"

#include <termios.h>
#include <sys/ioctl.h>
#include <unistd.h>

@implementation ASCM17AController

- (BOOL) acceptsCommand: (ASCommand *) command;
{
	if ([command isMemberOfClass:[ASActivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDeactivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASIncreaseCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDecreaseCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASChimeCommand class]])
		return YES;
	
	return NO;
}

- (NSData *) xtenDataForDevice:(ASDevice *)device command:(ASCommand *) command
{
	unsigned char byte = 0x00;
	
	ASX10Address * xten = (ASX10Address *) [device getAddress];
	
	NSString * lowerAddress = [[ASX10Address stringForAddress:[xten getAddressByte]] lowercaseString];
	
	char house = [lowerAddress characterAtIndex:0];
	int code = [[lowerAddress substringFromIndex:1] intValue];
	
	if (house == 'e' || house == 'l')
		byte = 0x80;
	
	if ((house >= 'a' && house <= 'd') || (house >= 'i' && house <= 'l'))
		byte = byte | 0x40;
	
	if (house == 'a' || house == 'b' || house == 'g' || house == 'h' || house == 'i' || house == 'j' || house == 'o' || house == 'p')
		byte = byte | 0x20;

	if (house == 'b' || house == 'd' || house == 'f' || house == 'h' || house == 'j' || house == 'l' || house == 'n' || house == 'p')
		byte = byte | 0x10;
	
	if (code >= 9)
		byte = byte | 0x04;
	
	unsigned char cmdByte = 0x00;
	
	if ([command isMemberOfClass:[ASDeactivateCommand class]] || [command isMemberOfClass:[ASDeactivateCommand class]])
		cmdByte = 0x80;

	if ((code >= 5 && code <= 8) || (code >= 13 && code <= 16))
		cmdByte = cmdByte | 0x40;
	
	if ([command isKindOfClass:[ASDeactivateCommand class]])
		cmdByte = cmdByte | 0x20;
	
	if ([command isMemberOfClass:[ASDecreaseCommand class]] && (code % 2 == 0))
		cmdByte = cmdByte | 0x10;
	
	if (([command isMemberOfClass:[ASDeactivateCommand class]] || [command isMemberOfClass:[ASActivateCommand class]]) &&
		((code == 3) || (code == 4) || (code == 7) || (code == 8) || (code == 11) || (code == 12) || (code == 15) || (code == 16)))
		cmdByte = cmdByte | 0x08;

	unsigned char header[2];
	header[0] = 0xd5;
	header[1] = 0xaa;

	unsigned char footer = 0xad;
	
	NSMutableData * data = [NSMutableData data];
	[data appendBytes:header length:2];
	[data appendBytes:&byte length:1];
	[data appendBytes:&cmdByte length:1];
	[data appendBytes:&footer length:1];
	
	return data;
}

- (void) write:(NSData *) data
{
	ShionLog (@"Writing: %@", data);

	unsigned int standby = (TIOCM_RTS | TIOCM_DTR);
	unsigned int reset = ~(TIOCM_RTS | TIOCM_DTR);
	
	unsigned char * buffer = (unsigned char * ) [data bytes];

	unsigned int status = 0x0;
	
	ioctl([handle fileDescriptor], TIOCMGET, &status);

	status = status | reset; // Standby
	ioctl([handle fileDescriptor], TIOCMSET, &status);

	usleep(1000);

	status = status | standby; // Standby
	ioctl([handle fileDescriptor], TIOCMSET, &status);
	
	usleep(1000);
	
	for (int j = 0; j < 5; j++) 
	{
		unsigned char data = buffer[j];
		unsigned char mask = 0x80;

		for (int k = 0; k < 8; k++) 
		{
			usleep(1000);

            int signal = (data & mask) ? TIOCM_RTS : TIOCM_DTR ;

			status = (status & ~standby) | signal;
			ioctl([handle fileDescriptor], TIOCMSET, &status);

			usleep(1000);
			
            status = (status & ~standby) | standby;
			ioctl([handle fileDescriptor], TIOCMSET, &status);

			mask = mask >> 1;
		}
	}

	ShionLog (@"Done writing: %@", data);
}

- (ASCM17AController *) initWithPath:(NSString *) path
{
	if (self = [super init])
	{
		const char * deviceFilePath = [path cStringUsingEncoding:NSASCIIStringEncoding];
		
		int fd = open (deviceFilePath, O_WRONLY | O_NONBLOCK);
		
		if (fd != -1)
		{
			struct termios options;
			tcgetattr(fd, &options);
			
			memset(&options, 0, sizeof(struct termios));
			cfmakeraw(&options);
			cfsetspeed(&options, 1200);
			options.c_cflag = CREAD |  CLOCAL | CS8 | CRTSCTS | CRTS_IFLOW;
			
			tcsetattr(fd, TCSANOW, &options);
			
			int modem = 0;
			
			ioctl(fd, TIOCMGET, &modem);
			modem |= TIOCM_DTR;
			ioctl(fd, TIOCMSET, &modem);        
			
			handle = [[NSFileHandle alloc] initWithFileDescriptor:fd];
			[handle readInBackgroundAndNotify];
			
			wakeup = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkQueue:) userInfo:nil repeats:YES] retain];
			
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
	[wakeup release];
	
	[super dealloc];
}

+ (ASCM17AController *) controllerWithPath:(NSString *) path
{
	ASCM17AController * controller = nil;
	
	controller = [[ASCM17AController alloc] initWithPath:path];
	
	return [controller autorelease];
}


- (void) transmitBytes
{
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
			
			if (commandData != nil)
			{
				ShionLog (@"*** CM17A: command to transmit: %@", [self stringForData:commandData]);
				[self write:commandData];
			}
		}
		
		[currentCommand release];
	}
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value
{
	return nil;
}


- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind
{
	ASCommand * command = nil;
	
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		command = [super commandForDevice:device kind:commandKind];
		
		NSData * data = [self xtenDataForDevice:device command:command];
		
		[command setValue:data forKey:COMMAND_BYTES];
	}		
	
	return command;
}

- (void) checkQueue:(NSTimer *) theTimer
{
	[self transmitBytes];
}



@end
