//
//  Phone.m
//  Shion
//
//  Created by Chris Karr on 4/26/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Phone.h"
#import "EventManager.h"

@implementation Phone

+ (Phone *) phone;
{
	return [Phone dictionary];
}

- (NSString *) type
{
	return @"Telephone / Modem";
}

- (NSData *) data
{
	return nil;
}

+ (NSString *) normalizePhoneNumber:(NSString *) number
{
	NSMutableString * newNumber = [NSMutableString stringWithString:[number stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet]]];
	
	[newNumber replaceOccurrencesOfString:@"\r" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newNumber length])];
	[newNumber replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newNumber length])];
	[newNumber replaceOccurrencesOfString:@"-" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newNumber length])];
	[newNumber replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newNumber length])];
	[newNumber replaceOccurrencesOfString:@"(" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newNumber length])];
	[newNumber replaceOccurrencesOfString:@")" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newNumber length])];
	[newNumber replaceOccurrencesOfString:@"+" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newNumber length])];
	[newNumber replaceOccurrencesOfString:@"." withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange (0, [newNumber length])];
	
	return newNumber;
}

+ (ABPerson *) findPersonByNumber:(NSString *) number
{
	number = [self normalizePhoneNumber:number];
	
	ABPerson * finalPerson = nil;
	
	NSEnumerator * iter = [[[ABAddressBook sharedAddressBook] people] objectEnumerator];
	ABPerson * person = nil;
	while (person = [iter nextObject])
	{
		ABMutableMultiValue * phones = [person valueForProperty:kABPhoneProperty];
		
		int i = 0;
		for (i = 0; i < [phones count]; i++)
		{
			NSString * phone = [self normalizePhoneNumber:[phones valueAtIndex:i]];
			
			if (finalPerson == nil && [number rangeOfString:phone].location != NSNotFound)
				finalPerson = person;
		}
	}
	
	return finalPerson;
}

- (void) addCall:(NSDictionary *) call
{
	NSString * desc = [NSString stringWithFormat:@"Received phone call from %@ (%@).", [call valueForKey:@"caller_name"], 
					   [call valueForKey:@"number"]];
	
	[[EventManager sharedInstance] createEvent:@"device" source:@"Phone" initiator:@"Phone"
								   description:desc
										 value:call
										 match:NO];
}

@end
