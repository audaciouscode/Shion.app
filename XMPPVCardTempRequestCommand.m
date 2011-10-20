//
//  XMPPVCardTempRequestCommand.m
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "XMPPVCardTempRequestCommand.h"
#import <SystemConfiguration/SystemConfiguration.h>

#import <SSCrypto/SSCrypto.h>

#import "PreferencesManager.h"

@implementation XMPPVCardTempRequestCommand

- (NSXMLElement *) responseElement
{
	PreferencesManager * preferences = [PreferencesManager sharedInstance];
	
	NSXMLElement * vcard = [NSXMLElement elementWithName:@"vCard"];
	[vcard addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"vcard-temp"]];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	if ([preferences valueForKey:@"shion_online_site"] == nil)
		[preferences setValue:[(NSString *) SCDynamicStoreCopyComputerName(NULL, NULL) autorelease] forKeyPath:@"shion_online_site"];
	
	NSString * name = [defaults valueForKey:@"shion_online_site"];
	
	NSXMLElement * fn = [NSXMLElement elementWithName:@"FN"];
	[fn setStringValue:[NSString stringWithFormat:@"Shion (%@)", name, nil]];
	[vcard addChild:fn];

	NSXMLElement * nick = [NSXMLElement elementWithName:@"NICKNAME"];
	[nick setStringValue:name];
	[vcard addChild:nick];
	
	NSXMLElement * url = [NSXMLElement elementWithName:@"URL"];
	[url setStringValue:@"http://www.audacious-software.com/products/shion/"];
	[vcard addChild:url];

	NSXMLElement * photo = [NSXMLElement elementWithName:@"PHOTO"];

	NSXMLElement * type = [NSXMLElement elementWithName:@"TYPE"];
	[type setStringValue:@"image/png"];
	[photo addChild:type];

	NSData * defaultIcon = [preferences valueForKey:SITE_ICON];

	NSXMLElement * binval = [NSXMLElement elementWithName:@"BINVAL"];
	[binval setStringValue:[defaultIcon encodeBase64]];
	[photo addChild:binval];
	
	[vcard addChild:photo];

	NSXMLElement * jabber = [NSXMLElement elementWithName:@"JABBERID"];
	[jabber setStringValue:toString];
	[vcard addChild:jabber];
	
	return vcard;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
