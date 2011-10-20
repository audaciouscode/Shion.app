//
//  XMPPUpdateAvatarMetadataCommand.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "XMPPUpdateAvatarMetadataCommand.h"
#import <SSCrypto/SSCrypto.h>

@implementation XMPPUpdateAvatarMetadataCommand

- (NSXMLElement *) responseElement
{
	NSXMLElement * pubsub = [NSXMLElement elementWithName:@"pubsub"];
	[pubsub addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/pubsub"]];
	
	NSXMLElement * publish = [NSXMLElement elementWithName:@"publish"];
	[publish setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"urn:xmpp:avatar:metadata" forKey:@"node"]];
	
	// TODO: User-customizable icons
	NSData * defaultIcon = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shion-64" ofType:@"png"]];
	NSString * sha = [[SSCrypto getSHA1ForData:defaultIcon] hexval];
	
	NSXMLElement * item = [NSXMLElement elementWithName:@"item"];
	[item setAttributesAsDictionary:[NSDictionary dictionaryWithObject:sha forKey:@"id"]];

	NSXMLElement * metadata = [NSXMLElement elementWithName:@"metadata"];
	[metadata addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"urn:xmpp:avatar:metadata"]];

	NSXMLElement * info = [NSXMLElement elementWithName:@"info"];
	
	NSImage * icon = [[NSImage alloc] initWithData:defaultIcon];
	NSSize size = [icon size];
	[icon release];
	
	[info setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", [defaultIcon length]], @"bytes", 
									 sha, @"id", 
									 [NSString stringWithFormat:@"%f", size.height], @"height", 
									 [NSString stringWithFormat:@"%f", size.width], @"width", 
									 @"image/png", @"type", nil]];
	[metadata addChild:info];
	[item addChild:metadata];
	[publish addChild:item];
	[pubsub addChild:publish];
	
	return pubsub;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	
@end
