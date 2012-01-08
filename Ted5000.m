//
//  Ted5000.m
//  Shion
//
//  Created by Chris Karr on 7/9/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "Ted5000.h"

#import "EventManager.h"

@implementation Ted5000

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"TED 5000" forKey:MODEL];
		
		buffer = [[NSMutableData alloc] init];
		lastUsage = 0;
		lastTotal = -9999;
		[[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateReading:) userInfo:nil repeats:YES] retain];
	}
	
	return self;
}

- (void) updateReading:(NSTimer *) theTimer
{
	[self fetchStatus];
}

- (void) fetchStatus
{
	[self setValue:[NSDate date] forKey:LAST_CHECK];
//	[self removeObjectForKey:LAST_RESPONSE];

	NSURLRequest * request = [NSURLRequest requestWithURL:
							  [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/LiveData.xml", 
													[self address]]]];

	[buffer setData:[NSData data]];

	[[NSURLConnection connectionWithRequest:request delegate:self] retain];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// TODO: Error
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[buffer appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[connection release];

	NSXMLDocument * document = [[NSXMLDocument alloc] initWithData:buffer options:NSXMLDocumentTidyXML error:NULL];
	
	if (document)
	{
		NSXMLElement * container = [document rootElement];
		
		NSArray * powers = [container elementsForName:@"Power"];
		NSEnumerator * iter = [powers objectEnumerator];
		
		NSXMLElement * power = nil;
		while (power = [iter nextObject])
		{
			NSXMLElement * total = [[power elementsForName:@"Total"] lastObject];
			NSXMLElement * now = [[total elementsForName:@"PowerNow"] lastObject];
			NSXMLElement * mtd = [[total elementsForName:@"PowerMTD"] lastObject];
			
			NSString * powerNow = [now stringValue];
			
			NSNumber * level = [NSNumber numberWithInt:[powerNow intValue]];
			
			if (fabs([level floatValue] - lastUsage) > 25 && fabs([level floatValue] - lastUsage) < 10000)
			{
				[self setCurrentPower:level];
				lastUsage = [level floatValue];
			}

			NSString * powerMtd = [mtd stringValue];
			level = [NSNumber numberWithFloat:([powerMtd floatValue] / 1000)];
			
			if (fabs([level floatValue] - lastTotal) > 1)
			{
				[self setTotalPower:level];
				lastTotal = [level floatValue];
			}
		}
		
		[self recordResponse];
		
		[document release];
	}
	
	[buffer setData:[NSData data]];
}

- (BOOL) canReset
{
	return NO;
}

@end
