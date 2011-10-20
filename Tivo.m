//
//  Tivo.m
//  Shion
//
//  Created by Chris Karr on 4/11/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "Tivo.h"
#import "Base64.h"

#define AVAILABLE_CONTENT @"available_content"

@implementation Tivo

- (void) netServiceDidResolveAddress:(NSNetService *) netService
{
	NSString * hostName = [netService hostName];

	[self setAddress:hostName];
	
	fetching = NO;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	[netService setDelegate:self];
	[netService resolveWithTimeout:5.0];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser
{
 	[netServiceBrowser release];

	fetching = NO;
}

- (void) findAddress
{
	NSNetServiceBrowser * browser = [[NSNetServiceBrowser alloc] init];
	[browser setDelegate:self];
	[browser searchForServicesOfType:@"_tivo-videos._tcp" inDomain:@""];
}

- (void) setPlatform:(NSString *) platform
{
	[super setPlatform:@"TiVo"];
}
	
- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:TIVO_DVR forKey:TYPE];
		[self setPlatform:@"TiVo"];
		
		lock = [[NSLock alloc] init];
	}
	
	return self;
}

- (NSString *) type
{
	return TIVO_DVR;
}

- (BOOL) checksStatus
{
	return YES;
}

- (NSArray *) availableContent
{
	NSArray * content = nil;
	
	[lock lock];
	
	content = [self valueForKey:AVAILABLE_CONTENT];

	[lock unlock];
	
	return content;
}

- (NSArray *) fetchItemsForSuffix:(NSString *) suffix
{
	NSMutableArray * shows = [NSMutableArray array];
	
	NSString * mak = [self valueForKey:@"media_access_key"];
	
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"https://tivo:%@@%@%@", mak, [self address], suffix]];
	
	NSData * xmlData = [Base64 loadDataFromURLForcingBasicAuth:url];

	if (xmlData == nil)
		return [NSArray array];
	
	NSXMLDocument * document = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentTidyXML error:NULL];
	
	if (document)
	{
		NSXMLElement * container = [document rootElement];
		
		NSArray * items = [container elementsForName:@"Item"];
		NSEnumerator * iter = [items objectEnumerator];
		
		NSXMLElement * item = nil;
		while (item = [iter nextObject])
		{
			NSXMLElement * details = [[item elementsForName:@"Details"] lastObject];
			NSXMLElement * links = [[item elementsForName:@"Links"] lastObject];
			
			NSString * type = [[[details elementsForName:@"ContentType"] lastObject] stringValue];
			
			if ([type isEqual:@"video/x-tivo-raw-tts"])
			{
				NSString * title = [[[details elementsForName:@"Title"] lastObject] stringValue];
				NSString * episode = [[[details elementsForName:@"EpisodeTitle"] lastObject] stringValue];
				NSString * episodeNo = [[[details elementsForName:@"EpisodeNumber"] lastObject] stringValue];
				NSString * station = [[[details elementsForName:@"SourceStation"] lastObject] stringValue];
				NSString * channel = [[[details elementsForName:@"SourceChannel"] lastObject] stringValue];
				NSString * synopsis = [[[details elementsForName:@"Description"] lastObject] stringValue];
				NSString * hiDef = [[[details elementsForName:@"HighDefinition"] lastObject] stringValue];
			
				NSString * rating = [[[details elementsForName:@"TvRating"] lastObject] stringValue];

				if ([rating isEqual:@"0"])
					rating = @"TV-Y7";
				else if ([rating isEqual:@"1"])
					rating = @"TV-Y";
				else if ([rating isEqual:@"2"])
					rating = @"TV-G";
				else if ([rating isEqual:@"3"])
					rating = @"TV-PG";
				else if ([rating isEqual:@"4"])
					rating = @"TV-14";
				else if ([rating isEqual:@"5"])
					rating = @"TV-MA";
				else
					rating = @"TV-NR";

				NSString * captured = [[[details elementsForName:@"CaptureDate"] lastObject] stringValue];
				int captureTime = 0;
				sscanf([captured cStringUsingEncoding:NSASCIIStringEncoding], "%x", &captureTime);
			
				NSDate * captureDate = [NSDate dateWithTimeIntervalSince1970:((NSTimeInterval) captureTime)];

				NSMutableDictionary * show = [NSMutableDictionary dictionary];

				if ([[details elementsForName:@"Duration"] count] > 0)
				{
					int duration = [[[[details elementsForName:@"Duration"] lastObject] stringValue] intValue];
					[show setValue:[NSNumber numberWithInt:(duration / 60000)] forKey:@"duration"];
				}
				
				[show setValue:title forKey:@"title"];
				[show setValue:episode forKey:@"episode"];
				[show setValue:episodeNo forKey:@"episode_number"];
				[show setValue:rating forKey:@"rating"];
				[show setValue:hiDef forKey:@"high_definition"];

				if (station != nil)
					[show setValue:[NSString stringWithFormat:@"%@ (%@)", station, channel] forKey:@"station"];
				else
					[show setValue:[NSString stringWithFormat:@"Unknown", station, channel] forKey:@"station"];

				[show setValue:synopsis forKey:@"synopsis"];
				[show setValue:captureDate forKey:@"recorded"];
			
				[shows addObject:show];
			}
			else if ([type isEqual:@"x-tivo-container/folder"])
			{
				NSString * pointerUrl = [[[[[links elementsForName:@"Content"] lastObject] elementsForName:@"Url"] lastObject] stringValue];
				
				NSRange range = [pointerUrl rangeOfString:@"/TiVoConnect" options:0 range:NSMakeRange(0, [pointerUrl length])];
				
				if (range.location != NSNotFound)
				{
					pointerUrl = [pointerUrl substringFromIndex:range.location];
					
					NSString * title = [[[details elementsForName:@"Title"] lastObject] stringValue];

					NSMutableDictionary * folder = [NSMutableDictionary dictionary];
					[folder setValue:title forKey:@"title"];
					[folder setValue:[self fetchItemsForSuffix:pointerUrl] forKey:@"children"];
					
					[shows addObject:folder];
				}
			}
		}
		
		[document release];
	}
	
	return shows;
}

- (NSArray *) recordings
{
	return [self availableContent];
	
}
- (void) setItems:(NSArray *) items
{
	[self willChangeValueForKey:AVAILABLE_CONTENT];

	[self didChangeValueForKey:AVAILABLE_CONTENT];

	[lock lock];
	[self setValue:[NSArray arrayWithArray:items] forKey:AVAILABLE_CONTENT];
	[lock unlock];
	
	[self recordResponse];
	
	[self setValue:[NSDate date] forKey:LAST_UPDATE];
}
	
- (void) fetchRecordings:(id) param
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSArray * items = [self fetchItemsForSuffix:@"/TiVoConnect?Command=QueryContainer&Container=%2FNowPlaying"];
	
	[self performSelectorOnMainThread:@selector(setItems:) withObject:items waitUntilDone:YES];
	
	[pool release];
}	

- (void) fetchStatus
{
	[self setValue:[NSDate date] forKey:LAST_CHECK];
	
	[NSThread detachNewThreadSelector:@selector(fetchRecordings:) toTarget:self withObject:nil];
}

- (void) fetchInfo
{
	[self fetchStatus];
}

/* - (void) postAction:(NSString *) action
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
*/

- (NSString *) address
{
	NSString * addy = [super address];
	
	if ((addy == nil || [addy isEqual:@""]) && !fetching)
	{
		fetching = YES;
		
		[self findAddress];
	}
	
	return addy;
}


@end
