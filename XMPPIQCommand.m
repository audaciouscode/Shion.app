//
//  XMPPIQNode.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "XMPPIQCommand.h"

#import "XMPPTimeCommand.h"
#import "XMPPLastActivityCommand.h"
#import "XMPPSoftwareVersionCommand.h"
#import "XMPPServiceDiscoveryCommand.h"

#import "ShionRemoteItemsList.h"
#import "ShionRemoteSystemStatusMessage.h"
#import "ShionRemoteSnapshotsMessage.h"
#import "ShionRemoteDevicesMessage.h"

#import "XMPPShionScriptCommand.h"

@implementation XMPPIQCommand

+ (XMPPIQCommand *) commandForElement:(NSXMLElement *) iqElement sender:(XMPPManager *) sender
{
	NSString * from = [[iqElement attributeForName:@"from"] stringValue];
	NSString * to = [[iqElement attributeForName:@"to"] stringValue];
	NSString * type = [[iqElement attributeForName:@"type"] stringValue];
	NSString * identifier = [[iqElement attributeForName:@"id"] stringValue];

	NSXMLElement * queryElement = [[iqElement elementsForName:@"query"] lastObject];

	NSString * query = @"shion:unknown";
	
	if (queryElement != nil)
	{
		NSEnumerator * nsIter = [[queryElement namespaces] objectEnumerator];
		NSXMLNode * ns = nil;
		
		while (ns = [nsIter nextObject])
		{
			if ([ns name] == nil || [[ns name] isEqual:@""])
				query = [ns stringValue];
		}
		
		if ([query isEqual:@"jabber:iq:last"])
			return [[[XMPPLastActivityCommand alloc] initWithFrom:from to:to type:type id:identifier query:query] autorelease];		
		else if ([query isEqual:@"jabber:iq:version"])
			return [[[XMPPSoftwareVersionCommand alloc] initWithFrom:from to:to type:type id:identifier query:query] autorelease];		
		else if ([query isEqual:@"http://jabber.org/protocol/disco#info"])
			return [[[XMPPServiceDiscoveryCommand alloc] initWithFrom:from to:to type:type id:identifier query:query] autorelease];		
		else if ([query isEqual:@"shion:script"])
		{
			XMPPShionScriptCommand * scriptCommand = [[XMPPShionScriptCommand alloc] initWithFrom:from to:to type:type id:identifier query:query];
			[scriptCommand setScript:[queryElement stringValue]];
			
			return [scriptCommand autorelease];
		}
			
	}
	else
	{
		NSXMLElement * timeElement = [[iqElement elementsForName:@"time"] lastObject];
		
		if (timeElement != nil)
			return [[[XMPPTimeCommand alloc] initWithFrom:from to:to type:type id:identifier query:@"vcard"] autorelease];

	}

	return [[[XMPPIQCommand alloc] initWithFrom:from to:to type:type id:identifier query:query] autorelease];
}


- (id) initWithFrom:(NSString *) from to:(NSString *) to type:(NSString *) type id:(NSString *) identifier query:(NSString *) query
{
	if (self = [super init])
	{
		fromString = [from retain];
		toString = [to retain];
		typeString = [type retain];
		identifierString = [identifier retain];
		
		queryString = [query retain];
	}
	
	return self;
}

- (void) setTo:(NSString *) to
{
	if (toString != nil)
		[toString release];
	
	toString = [to retain];
}

- (void) dealloc
{
	if (fromString != nil)
		[fromString release];

	if (toString != nil)
		[toString release];

	if (typeString != nil)
		[typeString release];

	if (identifierString != nil)
		[identifierString release];

	if (queryString != nil)
		[queryString release];
	
	[super dealloc];
}
	

- (NSXMLElement *) responseElement
{
	return nil;
}	

- (NSXMLElement *) errorElement
{
	NSXMLElement * error = [NSXMLElement elementWithName:@"error"];
	[error setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"cancel" forKey:@"type"]];
	
	NSXMLElement * unavailable = [NSXMLElement elementWithName:@"service-unavailable"];
	[unavailable addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"urn:ietf:params:xml:ns:xmpp-stanzas"]];
	
	[error addChild:unavailable];
	
	return error;
}	

- (NSXMLElement *) execute
{
	NSXMLElement * iq = [NSXMLElement elementWithName:@"iq"];
	
	NSXMLElement * error = [self errorElement];
	
	if (error != nil)
	{
		[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"error", @"type", toString, @"from", fromString, @"to", identifierString, @"id", nil]];
	
		[iq addChild:error];
	}
	else
	{
		if (fromString != nil && ![fromString isEqual:@""])
			[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"result", @"type", toString, @"from", fromString, @"to", identifierString, @"id", nil]];
		else
			[iq setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:typeString, @"type", toString, @"from", identifierString, @"id", nil]];
			
		[iq addChild:[self responseElement]];
	}
	
	return iq;
}

@end
