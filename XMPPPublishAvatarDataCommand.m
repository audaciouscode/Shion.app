//
//  XMPPPublishAvatarDataCommand.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "XMPPPublishAvatarDataCommand.h"

#import <SSCrypto/SSCrypto.h>

@implementation XMPPPublishAvatarDataCommand

- (NSXMLElement *) responseElement
{
	NSXMLElement * pubsub = [NSXMLElement elementWithName:@"pubsub"];
	[pubsub addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/pubsub"]];
	
	NSXMLElement * publish = [NSXMLElement elementWithName:@"publish"];
	[publish setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"urn:xmpp:avatar:data" forKey:@"node"]];

	// TODO: User-customizable icons
	NSData * defaultIcon = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shion-64" ofType:@"png"]];
	NSString * sha = [[SSCrypto getSHA1ForData:defaultIcon] hexval];

	NSXMLElement * item = [NSXMLElement elementWithName:@"item"];
	[item setAttributesAsDictionary:[NSDictionary dictionaryWithObject:sha forKey:@"id"]];
	
	NSXMLElement * data = [NSXMLElement elementWithName:@"data"];
	[data addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"urn:xmpp:avatar:data"]];

	[data setStringValue:[defaultIcon encodeBase64]];
	
	[item addChild:data];
	[publish addChild:item];
	[pubsub addChild:publish];
	
	return pubsub;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
