//
//  ASEzSrveWebController.m
//  Shion Framework
//
//  Created by Chris Karr on 2/15/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASEzSrveWebController.h"
#import "ASInsteonAddress.h"
#import "ASX10Address.h"
#import "ASCommands.h"
#import "ASInsteonDatabase.h"

#import "ASThermostatDevice.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
 #include <netdb.h>

#define COMMAND_XML @"Command XML"

@implementation ASEzSrveWebController

+ (NSString *) findController
{
	NSString * controllerAddress = nil;
	
	// Send ping...
	
	// Adapted from http://www.abc.se/~m6695/udp.html
	
	int	sd;
	struct	sockaddr_in server;
	struct  hostent *hp, *gethostbyname();
	
	sd = socket (AF_INET,SOCK_DGRAM,0);
	
	server.sin_family = AF_INET;
	hp = gethostbyname("224.0.5.128");
	
	bcopy(hp->h_addr, &(server.sin_addr.s_addr), hp->h_length);

	server.sin_port = htons(2362);

	unsigned char buf[] = { 0x44, 0x56, 0x4b, 0x54, 0x00, 0x01,
							0x00, 0x1c, 0xff, 0xff, 0xff, 0xff,
							0xff, 0xff, 0x14, 0x02, 0x02, 0x00,
							0x15, 0x10, 0xbf, 0x6d, 0xb4, 0x09, 
							0xc8, 0x3d, 0x44, 0xa3, 0xa3, 0x6d,
							0x21, 0x79, 0x7d, 0x2f, 0x73, 0xf9 };
	
	unsigned char recvBuf[1024];

	if (sendto(sd, buf, 36, 0, (struct sockaddr *) &server, sizeof(server)) != -1)
	{
		socklen_t length = 0;
		
		struct timeval timeout;
		timeout.tv_sec = 3;
		timeout.tv_usec = 0;
		
		fd_set rfds;
		FD_ZERO(&rfds);
		FD_SET(sd, &rfds);
		
		if (select(1 + sd, &rfds, NULL, NULL, &timeout) > 0)
		{			
			if (recvfrom(sd, recvBuf, 1024, 0, (struct sockaddr *) &server, &length) != -1)
				controllerAddress = [NSString stringWithFormat:@"%d.%d.%d.%d", recvBuf[38], recvBuf[39], recvBuf[40], recvBuf[41]];
			
			ShionLog([NSString stringWithFormat:@"Found EZServe at %@", controllerAddress]);
		}
		else
		{
			ShionLog(@"No EZSrve controllers found");
		}

		close(sd);
	}

	return controllerAddress;
}

- (void) processDeviceElement:(NSXMLElement *) deviceElement
{
	NSString * devCat = [[deviceElement attributeForName:@"DevCat"] stringValue];
	
	if ([devCat isEqual:@"0x0305"]) // EZSrve
	{
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
		[userInfo setValue:CONTROLLER_DEVICE forKey:DEVICE_TYPE];
		[userInfo setValue:[[deviceElement attributeForName:@"Name"] stringValue] forKey:DEVICE_NAME];

		NSMutableString * deviceAddress = [NSMutableString stringWithString:[[deviceElement attributeForName:@"ID"] stringValue]];
		[deviceAddress replaceOccurrencesOfString:@"." withString:@"" options:0 range:NSMakeRange(0, [deviceAddress length])];
		[userInfo setValue:deviceAddress forKey:DEVICE_ADDRESS];

		[userInfo setValue:@"SimpleHomeNet EZServe 2.0" forKey:DEVICE_MODEL];

		NSArray * firmwareNodes = [deviceElement nodesForXPath:@"Clusters/Cluster" error:NULL];
		
		NSEnumerator * iter = [firmwareNodes objectEnumerator];
		NSXMLElement * node = nil;
		
		while (node = [iter nextObject])
		{
			NSString * firmware = [[node attributeForName:@"PLMVersion"] stringValue];
			
			if (firmware != nil)
				[userInfo setValue:[NSNumber numberWithInt:[firmware doubleValue]] forKey:DEVICE_FIRMWARE];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
	}
	else
	{
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];

		[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
		
		NSMutableString * deviceAddress = [NSMutableString stringWithString:[[deviceElement attributeForName:@"ID"] stringValue]];
		[deviceAddress replaceOccurrencesOfString:@"." withString:@"" options:0 range:NSMakeRange(0, [deviceAddress length])];
		[userInfo setValue:deviceAddress forKey:DEVICE_ADDRESS];
		
		[userInfo setValue:[ASInsteonDatabase stringForDeviceTypeString:[[deviceElement attributeForName:@"DevCat"] stringValue]] forKey:DEVICE_MODEL];
		
		NSArray * clusterNodes = [deviceElement nodesForXPath:@"Clusters/Cluster" error:NULL];

		NSEnumerator * iter = [clusterNodes objectEnumerator];
		NSXMLElement * cluster = nil;
		
		while (cluster = [iter nextObject])
		{
			NSString * status = [[cluster attributeForName:@"Status"] stringValue];
			
			if (status != nil)
			{
				NSScanner * scanner = [NSScanner scannerWithString:status];
				unsigned value = 0;
				
				if ([scanner scanHexInt:&value])
					[userInfo setValue:[NSNumber numberWithUnsignedInt:value] forKey:DEVICE_STATE];
			}

			NSString * temperature = [[cluster attributeForName:@"Temp"] stringValue];
			
			if (temperature != nil)
			{
				NSScanner * scanner = [NSScanner scannerWithString:temperature];
				unsigned value = 0;
				
				if ([scanner scanHexInt:&value])
					[userInfo setValue:[NSNumber numberWithUnsignedInt:(value / 2)] forKey:THERMOSTAT_TEMPERATURE];
			}

			NSString * coolPoint = [[cluster attributeForName:@"CoolSetPoint"] stringValue];
			
			if (coolPoint != nil)
			{
				NSScanner * scanner = [NSScanner scannerWithString:coolPoint];
				unsigned value = 0;
				
				if ([scanner scanHexInt:&value] && value > 0)
					[userInfo setValue:[NSNumber numberWithUnsignedInt:(value / 2)] forKey:THERMOSTAT_COOL_POINT];
			}

			NSString * heatPoint = [[cluster attributeForName:@"HeatSetPoint"] stringValue];
			
			if (heatPoint != nil)
			{
				NSScanner * scanner = [NSScanner scannerWithString:heatPoint];
				unsigned value = 0;
				
				if ([scanner scanHexInt:&value] && value > 0)
					[userInfo setValue:[NSNumber numberWithUnsignedInt:(value / 2)] forKey:THERMOSTAT_HEAT_POINT];
			}

			NSString * mode = [[cluster attributeForName:@"Mode"] stringValue];
			
			if (mode != nil)
			{
				NSScanner * scanner = [NSScanner scannerWithString:mode];
				unsigned value = 0;
				
				if ([scanner scanHexInt:&value])
					[userInfo setValue:[NSNumber numberWithUnsignedInt:value] forKey:THERMOSTAT_MODE];
			}
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
	}
}

- (void) processXmlDocument:(NSXMLDocument *) document
{
	ShionLog(@"Received XML: %@", document);
	
	NSXMLElement * element = [document rootElement];
	
	if ([[[element attributeForName:@"Status"] stringValue] hasPrefix:@"In Progress"])
		return;
	
	NSArray * devicesElements = [element elementsForName:@"Devices"];
	
	if ([devicesElements count] > 0)
	{
		NSArray * deviceElements = [[devicesElements lastObject] elementsForName:@"Device"];
		
		NSEnumerator * iter = [deviceElements objectEnumerator];
		NSXMLElement * deviceElement = nil;
		while (deviceElement = [iter nextObject])
			[self processDeviceElement:deviceElement];
	}
	
	ready = YES;
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
					[readData appendBytes:readBuffer length:read];
			}
			
			NSString * xmlString = [[[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding] autorelease];
			
			// xmlString = [xmlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

			NSRange range = [xmlString rangeOfString:@"</Response>"];
			
			if (range.location != NSNotFound)
			{
				xmlString = [xmlString substringToIndex:(range.location + range.length)];

				NSError * error = nil;

				NSXMLDocument * document = [[NSXMLDocument alloc] initWithXMLString:xmlString options:0 error:&error]; // initWithData:[xmlString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
			
				if (document != nil)
				{
					[self processXmlDocument:document];
					[readData setData:[NSData data]];
				}
				
				[document release];
			}
		}
	}
}

- (NSString *) insteonCommandForAddress:(NSData *) addressBytes cmdOne:(unsigned char) one cmdTwo:(unsigned char) two
{
	NSMutableString * command = [NSMutableString string];
	
	if ([addressBytes length] > 2)
	{
		unsigned char * insteonAddress = (unsigned char *) [addressBytes bytes];
	
		[command appendFormat:@"<Command Name=\"SendInsteon\" ID=\"%02X.%02X.%02X\">", insteonAddress[0], insteonAddress[1], insteonAddress[2]];
		[command appendFormat:@"<CommandDetail Cmd1=\"0x%02X\" Cmd2=\"0x%02X\"/>", one, two];
		[command appendString:@"</Command>\n"];	
	}
	
	return command;
}

- (NSString *) insteonStatusCommandForAddress:(NSData *) addressBytes productCode:(NSString *) code;
{
	NSMutableString * command = [NSMutableString string];
	
	if ([addressBytes length] > 2)
	{
		unsigned char * insteonAddress = (unsigned char *) [addressBytes bytes];

		NSString * deviceId = [NSString stringWithFormat:@"%02X.%02X.%02X", insteonAddress[0], insteonAddress[1], insteonAddress[2]];
		
		if ([knownDevices containsObject:deviceId])
			return @"<Command Name=\"Read\" File=\"Devices\" />";
		else 
		{
			[command appendString:@"<Command Name=\"Write\" File=\"Devices\">"];
			[command appendFormat:@"<Device Name=\"%@\" ID=\"%@\" />", deviceId, deviceId];
			[command appendString:@"</Command>\n"];	
			
			[knownDevices addObject:deviceId];
		}
	}
	
	return command;
}

- (NSString *) xTenCommandForAddress:(NSString *) xTenAddress command:(NSString *) command
{
	NSMutableString * xml = [NSMutableString string];
	
	if ([xTenAddress length] > 1)
	{
		[xml appendFormat:@"<Command Name=\"SendX10\" House=\"%@\" Unit=\"%@\" Cmd=\"%@\"/>\n",
		 [xTenAddress substringWithRange:NSMakeRange(0, 1)], [xTenAddress substringFromIndex:1], command];
	}
	
	return xml;
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

			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x11 cmdTwo:level] forKey:COMMAND_XML];
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

			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x6b cmdTwo:newMode] forKey:COMMAND_XML];
		}	
		else if ([command isMemberOfClass:[ASSetCoolPointCommand class]])
		{
			unsigned char point = [((NSNumber *) value) unsignedCharValue] * 2;
			
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x6c cmdTwo:point] forKey:COMMAND_XML];
		}	
		else if ([command isMemberOfClass:[ASSetHeatPointCommand class]])
		{
			unsigned char point = [((NSNumber *) value) unsignedCharValue] * 2;
			
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x6d cmdTwo:point] forKey:COMMAND_XML];
		}	
		else if ([command isMemberOfClass:[ASSprinklerOnCommand class]])
		{	
			unsigned char unit = [((NSNumber *) value) unsignedCharValue];
			
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x40 cmdTwo:unit] forKey:COMMAND_XML];
		}
		else if ([command isMemberOfClass:[ASSprinklerOffCommand class]])
		{	
			unsigned int unit = [((NSNumber *) value) unsignedCharValue];
			
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x41 cmdTwo:unit] forKey:COMMAND_XML];
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
			
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x44 cmdTwo:commandByte] forKey:COMMAND_XML];
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
		
		if ([command isKindOfClass:[ASStatusCommand class]])
			[command setValue:[self insteonStatusCommandForAddress:addressBytes productCode:[device productCode]] forKey:COMMAND_XML];
		if ([command isMemberOfClass:[ASActivateCommand class]])
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x11 cmdTwo:0xff] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASDeactivateCommand class]])
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x13 cmdTwo:0x00] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASActivateFanCommand class]])
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x6b cmdTwo:0x07] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASDeactivateFanCommand class]])
			[command setValue:[self insteonCommandForAddress:addressBytes cmdOne:0x6b cmdTwo:0x08] forKey:COMMAND_XML];
	}
	else if ([deviceAddress isMemberOfClass:[ASX10Address class]])
	{
		command = [super commandForDevice:device kind:commandKind];
		
		if (![self acceptsCommand:command])
			return nil;
		
		NSString * unit = [((ASX10Address *) [device getAddress]) getAddress];
		
		if ([command isMemberOfClass:[ASAllOffCommand class]])
			[command setValue:[self xTenCommandForAddress:unit command:@"All-Units-OFF"] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASAllLightsOffCommand class]])
			[command setValue:[self xTenCommandForAddress:unit command:@"All-Lights-OFF"] forKey:COMMAND_XML];
		if ([command isMemberOfClass:[ASAllLightsOnCommand class]])
			[command setValue:[self xTenCommandForAddress:unit command:@"All-Lights-ON"] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASChimeCommand class]])
			[command setValue:[self xTenCommandForAddress:unit command:@"ON"] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASActivateCommand class]])
			[command setValue:[self xTenCommandForAddress:unit command:@"ON"] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASDeactivateCommand class]])
			[command setValue:[self xTenCommandForAddress:unit command:@"OFF"] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASIncreaseCommand class]])
			[command setValue:[self xTenCommandForAddress:unit command:@"Bright"] forKey:COMMAND_XML];
		else if ([command isMemberOfClass:[ASDecreaseCommand class]])
			[command setValue:[self xTenCommandForAddress:unit command:@"Dim"] forKey:COMMAND_XML];
	}		
	
	return command;
}

- (void) next:(NSTimer *) theTimer
{
	if (!ready)
		return;
	
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
			NSString * xml = [command valueForKey:COMMAND_XML];
			
			if (xml != nil)
			{
				ShionLog(@"Sending: %@", xml);
				
				NSData * data = [xml dataUsingEncoding:NSASCIIStringEncoding];
				
				if ([_output write:[data bytes] maxLength:[data length]] == -1)
					ShionLog(@"Error sending command '%@'.", xml);

				ready = NO;
			}
		}
		
		[commandQueue removeObject:command];
	}
}

- (void) fetchDevices
{
	NSString * xml = @"<Command Name=\"Read\" File=\"Devices\" />";
	
	NSData * data = [xml dataUsingEncoding:NSASCIIStringEncoding];
	
	ShionLog(@"Sending %@", xml);
	
	if ([_output write:[data bytes] maxLength:[data length]] == -1)
		ShionLog(@"Error sending command '%@'.", xml);
}

- (void) resetDevice
{
	NSString * xml = @"<Command Name=\"ClearFlash\" />";
	
	NSData * data = [xml dataUsingEncoding:NSASCIIStringEncoding];
	
	ShionLog(@"Sending %@", xml);
	
	if ([_output write:[data bytes] maxLength:[data length]] == -1)
		ShionLog(@"Error sending command '%@'.", xml);
}

- (ASEzSrveWebController *) initWithHost:(NSString *) host
{
	if (self = [super init])
	{
		_input = nil;
		_output = nil;
		
		_host = [host retain];

		[NSStream getStreamsToHost:[NSHost hostWithAddress:host] port:8002 inputStream:&_input outputStream:&_output];

		[_input retain];
		[_input setDelegate:self];
		[_input scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_input open];
		
		[_output retain];
		[_output setDelegate:self];
		[_output scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_output open];
		
		ready = YES;
		
		knownDevices = [[NSMutableSet alloc] init];
		
		readData = [[NSMutableData data] retain];

//			[self resetDevice];
		
		_refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(next:) userInfo:nil repeats:YES] retain];

	}
	
	return self;
}

- (BOOL) acceptsCommand: (ASCommand *) command;
{
	if ([command isMemberOfClass:[ASStatusCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetInfoCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASActivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDeactivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetLevelCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetTemperatureCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetThermostatModeCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetThermostatModeCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetThermostatState class]])
		return YES;
	else if ([command isMemberOfClass:[ASActivateThermostatStatusBroadcastCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetCoolPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetHeatPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetCoolPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetHeatPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAggregateCommand class]])
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
	
	return NO;
}


@end
