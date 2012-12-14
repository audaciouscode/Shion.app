//
//  ASSerialPortModemDevice.m
//  Shion Framework
//
//  Created by Chris Karr on 2/5/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASSerialPortModemDevice.h"
#import "ShionLog.h"

#include <termios.h>
#include <sys/ioctl.h>

@implementation ASSerialPortModemDevice

- (void) process:(NSString *) string
{
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
	[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
	[userInfo setValue:[[self getAddress] getAddress] forKey:DEVICE_ADDRESS];
	
	BOOL notify = NO;
	
	NSMutableString * mutableString = [NSMutableString stringWithString:string];
	[mutableString replaceOccurrencesOfString:@"\n" withString:@"\r" options:0 range:NSMakeRange(0, [mutableString length])];
	
	NSEnumerator * lines = [[mutableString componentsSeparatedByString:@"\r"] objectEnumerator];
	NSString * line = nil;
	while (line = [lines nextObject])
	{
		NSMutableString * mutableLine = [NSMutableString stringWithString:line];

		if ([mutableLine isEqual:@"RING"])
		{
			[userInfo setObject:RINGING forKey:DEVICE_STATE];
			notify = YES;
		}
		else if ([line hasPrefix:@"NMBR = "])
		{
			[mutableLine replaceOccurrencesOfString:@"NMBR =" withString:@"" options:0 range:NSMakeRange(0, [mutableLine length])];
			
			[userInfo setObject:[mutableLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:CID_NUMBER];
			notify = YES;
		}
		else if ([line hasPrefix:@"NAME = "])
		{
			[mutableLine replaceOccurrencesOfString:@"NAME =" withString:@"" options:0 range:NSMakeRange(0, [mutableLine length])];
			[userInfo setObject:[mutableLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:CID_NAME];
			notify = YES;
		}
	}
	
	if (notify)
		[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
}

- (void) read:(NSNotification *) theNote
{
	if ([theNote object] == handle)
	{
		NSData * data = [[theNote userInfo] valueForKey:NSFileHandleNotificationDataItem];

		NSMutableString * line = [[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
		[line setString:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	
		ShionLog(@"Modem Read: %@", line);
	
		[self process:line];
	
		[line release];
	
		[handle readInBackgroundAndNotify];
	}
}

- (void) write:(NSData *) data
{
	NSMutableString * line = [[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
	[line setString:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	
	ShionLog(@"Modem Write: %@", line);

	[line release];
	
	[handle writeData:data];
	
	[handle readInBackgroundAndNotify];
}

- (id) init
{
	if (self = [super init])
		handle = nil;
	
	return self;
}

- (void) dealloc
{
	[handle closeFile];
	[handle release];
	
	[_model release];

	[super dealloc];
}

- (void) setModel:(NSString *) model
{
	if (_model != nil)
		[_model release];

	_model = [model retain];
}

- (void) go
{
	if (handle != nil);
	{
		[handle closeFile];
		[handle release];
	}
	
	ASAddress * address = [self getAddress];
	
	if (address != nil)
	{
		const char * deviceFilePath = [[[address getAddress] description] cStringUsingEncoding:NSASCIIStringEncoding];
		
		int fd = open (deviceFilePath, O_RDWR | O_NOCTTY);
		
		if (fd != -1)
		{
			handle = [[NSFileHandle alloc] initWithFileDescriptor:fd];

			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(read:) name:NSFileHandleReadCompletionNotification object:handle];

			[self write:[@"AT+VCID=1\r" dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
}
			
@end
