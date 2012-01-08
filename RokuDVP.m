//
//  RokuDVP.m
//  Shion
//
//  Created by Chris Karr on 4/11/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "RokuDVP.h"
#import "AsyncUdpSocket.h"

#import "EventManager.h"

#define AVAILABLE_CONTENT @"available_content"

@implementation RokuDVP

-(void) completeSearch: (NSTimer *) timer
{
	AsyncUdpSocket * socket = [[timer userInfo] valueForKey:@"socket"];
	
	[socket close];
}
	
- (BOOL) onUdpSocket:(AsyncUdpSocket *) sock didReceiveData:(NSData *) data withTag:(long) tag fromHost:(NSString *) host port:(UInt16) port
{
	
	/*
	 Cache-Control: max-age=300
	 ST: roku:ecp
	 USN: uuid:roku:ecp:20F85L000446
	 Ext: 
	 Server: Roku UPnP/1.0 MiniUPnPd/1.4
	 Location: http://10.0.1.25:8060/
*/

	NSMutableString * string = [[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	[string replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0, [string length])];
	
	while ([string replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:0 range:NSMakeRange(0, [string length])] > 0)
	{
		
	}
	
	NSArray * lines = [string componentsSeparatedByString:@"\n"];

	[string release];

	NSString * line = nil;
	NSEnumerator * iter = [lines objectEnumerator];
	while (line = [iter nextObject])
	{
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		if ([line hasPrefix:@"Location: "])
			[self setAddress:[line substringFromIndex:10]];
	}
	
	[self fetchInfo];

	return YES;
}

- (void) findAddress
{
	AsyncUdpSocket * ssdpSock = [[AsyncUdpSocket alloc] initWithDelegate:self];
	[ssdpSock enableBroadcast:TRUE error:nil];
	NSString *str = @"M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMan: \"ssdp:discover\"\r\nST: roku:ecp\r\n\r\n";    
	[ssdpSock bindToPort:0 error:nil];
	[ssdpSock joinMulticastGroup:@"239.255.255.250" error:nil];
	[ssdpSock sendData:[str dataUsingEncoding:NSUTF8StringEncoding] toHost: @"239.255.255.250" port:1900 withTimeout:-1 tag:1];
	[ssdpSock receiveWithTimeout: -1 tag:1];
	[NSTimer scheduledTimerWithTimeInterval: 5 target:self selector:@selector(completeSearch:) 
								   userInfo:[NSDictionary dictionaryWithObject:ssdpSock forKey:@"socket"] repeats: NO]; 
	
}

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:ROKU_DVP forKey:TYPE];
	}
	
	return self;
}

- (NSString *) type
{
	return ROKU_DVP;
}

- (BOOL) checksStatus
{
	return YES;
}

- (NSArray *) availableContent
{
	return [self valueForKey:AVAILABLE_CONTENT];
}

- (void) fetchStatus
{
	[self setValue:[NSDate date] forKey:LAST_CHECK];
	[self removeObjectForKey:LAST_RESPONSE];

	NSURL * channelUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@query/apps", [self address]]];
	
	NSXMLDocument * document = [[NSXMLDocument alloc] initWithContentsOfURL:channelUrl options:NSXMLDocumentTidyXML error:NULL];
	
	if (document)
	{
		[self willChangeValueForKey:AVAILABLE_CONTENT];
		
		NSMutableArray * channels = [NSMutableArray array];
		
		NSMutableArray * added = [NSMutableArray array];
		NSMutableArray * removed = [NSMutableArray arrayWithArray:[self availableContent]];
		
		NSArray * children = [[document rootElement] elementsForName:@"app"];
		NSXMLElement * child = nil;
		NSEnumerator * iter = [children objectEnumerator];
		while (child = [iter nextObject])
		{
			NSString * name = [child stringValue];
			NSString * appId = [[child attributeForName:@"id"] stringValue];
			NSString * version = [[child attributeForName:@"version"] stringValue];
			
			NSMutableDictionary * channel = [NSMutableDictionary dictionary];
			[channel setValue:name forKey:@"channel"];
			[channel setValue:appId forKey:@"id"];
			[channel setValue:version forKey:@"version"];
			
			if (![removed containsObject:channel])
				[added addObject:channel];
			else
				[removed removeObject:channel];
			
			[channels addObject:channel];
		}
		
		NSDictionary * channel = nil;
		iter = [removed objectEnumerator];
		while (channel = [iter nextObject])
		{
			NSString * message = [NSString stringWithFormat:@"'%@' was removed and is no longer available.", [channel valueForKey:@"channel"]];
			
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
										   description:message value:@"255"];
		}

		iter = [added objectEnumerator];
		while (channel = [iter nextObject])
		{
			NSString * message = [NSString stringWithFormat:@"'%@' was added and is now available.", [channel valueForKey:@"channel"]];
			
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
										   description:message value:@"255"];
		}
		
		[self setValue:channels forKey:AVAILABLE_CONTENT];

		[self didChangeValueForKey:AVAILABLE_CONTENT];

		[self setValue:[NSDate date] forKey:LAST_RESPONSE];
	}
	
	
	NSURL * modelUrl = [NSURL URLWithString:[self address]];
	
	document = [[NSXMLDocument alloc] initWithContentsOfURL:modelUrl options:NSXMLDocumentTidyXML error:NULL];
	
	if (document)
	{
		NSXMLElement * root = [document rootElement];
		NSXMLElement * device = [[root elementsForName:@"device"] lastObject];
		NSXMLElement * modelName = [[device elementsForName:@"modelName"] lastObject];
		
		if (modelName)
		{
			[self setModel:[modelName stringValue]];
		}
		
		[document release];
	}
}

- (void) fetchInfo
{
	[self fetchStatus];
}

- (void) postAction:(NSString *) action
{
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@keypress/%@", [self address], action]]];;
	[request setHTTPMethod:@"POST"];

	NSURLResponse * response = nil;
	[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
}

- (void) homeAction
{
	[self postAction:@"Home"];
}

- (void) playAction
{
	[self postAction:@"Play"];
}

- (void) backAction
{
	[self postAction:@"Rev"];
}

- (void) fwdAction
{
	[self postAction:@"Fwd"];
}

- (void) upAction
{
	[self postAction:@"Up"];
}

- (void) downAction
{
	[self postAction:@"Down"];
}

- (void) leftAction
{
	[self postAction:@"Left"];
}

- (void) rightAction
{
	[self postAction:@"Right"];
}

- (void) selectAction
{
	[self postAction:@"Select"];
}

- (NSString *) address
{
	NSString * addy = [super address];
	
	if (addy == nil || [addy isEqual:@""])
	{
		[self findAddress];
		
		addy = @"Unknown";
		
		[self setAddress:addy];
	}
	
	return addy;
}

@end
