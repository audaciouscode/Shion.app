//
//  Camera.m
//  Shion
//
//  Created by Chris Karr on 9/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Camera.h"

#import "XMPPManager.h"
#import "EventManager.h"

#define TAKE_PICTURE @"take_picture"

@implementation Camera

+ (Camera *) camera;
{
	return [Camera dictionary];
}

- (NSString *) type
{
	return @"Camera";
}

- (void) autoCapture:(NSTimer *) theTimer
{
	if ([[self valueForKey:@"capture_automatically"] boolValue])
	{
		NSDate * now = [NSDate date];
		
		NSTimeInterval interval = [now timeIntervalSinceDate:lastUpdate];
		
		NSNumber * updateInterval = [self valueForKey:@"capture_frequency"];
		
		if (([updateInterval floatValue] * 60) < interval)
		{
			[self captureImage];
			
			[lastUpdate release];
			lastUpdate = [now retain];
		}
	}
}

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Camera" forKey:TYPE];
		[self setValue:@"Unknown" forKey:LOCATION];
		
		lastFrame = NULL;
		
		lastUpdate = [[NSDate distantPast] retain];
		
		captureTimer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(autoCapture:) userInfo:nil repeats:YES] retain];
	}
	
	return self;
}

- (id) valueForKey:(NSString *) key
{
	id value = [super valueForKey:key];

	if ([key isEqual:@"latest_image"])
	{
		NSArray * images = [self valueForKey:@"images"];
		
		if (images != nil)
			return [[images lastObject] valueForKey:@"data"];
		
		return nil;
	}
	else if (value == nil)
	{
		if ([key isEqual:@"capture_automatically"])
			value = [NSNumber numberWithBool:NO];
		else if ([key isEqual:@"capture_frequency"])
			value = [NSNumber numberWithInt:10];
		else if ([key isEqual:@"capture_unique"])
			value = [NSNumber numberWithBool:YES];
		else if ([key isEqual:@"capture_sound"])
			value = [NSNumber numberWithBool:YES];
	}
	
	return value;
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	[super setValue:value forKey:key];
	
	if ([key isEqual:TAKE_PICTURE])
	{
		if (lastFrame != NULL)
			cvReleaseImage(&lastFrame);

		[self captureImage];
	}
}

- (BOOL) shouldSaveImage:(IplImage *) newImage
{
	if (lastFrame == NULL)
		return YES;
	else if ([[self valueForKey:@"capture_unique"] boolValue])
	{
		IplImage * diffs = cvCloneImage(newImage);
		
		cvAbsDiff(newImage, lastFrame, diffs);
		
		CvScalar avg = cvAvg(diffs, NULL);

		BOOL save = NO;

		double threshold = 10.000;
		
		if (avg.val[0] > threshold || avg.val[1] > threshold || avg.val[2] > threshold || avg.val[3] > threshold)
			save = YES;
		
		cvReleaseImage(&diffs);
		
		return save;
	}

	return YES;
}

- (void) captureImage
{
	[self willChangeValueForKey:LAST_UPDATE];

	CvCapture * camera = cvCreateCameraCapture (CV_CAP_ANY);
	
	if (camera)
	{
		if ([[self valueForKey:@"capture_sound"] boolValue])
			[[NSSound soundNamed:@"camera"] play];

		[self willChangeValueForKey:@"images"];
		[self willChangeValueForKey:@"latest_image"];
		
		IplImage * current_frame = cvQueryFrame (camera);
		
		if ([self shouldSaveImage:current_frame])
		{
			NSString * path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"shion-snapshot.jpg"];
		
			cvSaveImage([path cStringUsingEncoding:NSUTF8StringEncoding], current_frame);
		
			NSData * imageData = [NSData dataWithContentsOfFile:path];
		
			NSMutableDictionary * image = [NSMutableDictionary dictionary];
		
			[image setValue:imageData forKey:@"data"];
			[image setValue:[NSDate date] forKey:@"date"];
		
			CFUUIDRef uuid = CFUUIDCreate(NULL);
			NSString * deviceId = ((NSString *) CFUUIDCreateString(NULL, uuid));
			[image setValue:deviceId forKey:@"identifier"];
			[deviceId release];
			CFRelease(uuid);
		
			NSMutableArray * images = [self valueForKey:@"images"];
			if (images == nil)
			{
				images = [NSMutableArray array];
				[self setValue:images forKey:@"images"];
			}

			[images addObject:image];
		
			NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
			[images sortUsingDescriptors:[NSArray arrayWithObject:sort]];
			[sort release];
			
			[self didChangeValueForKey:@"latest_image"];
			[self didChangeValueForKey:@"images"];
		
			[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		
			[[XMPPManager sharedInstance] transmitPhoto:[self photoForId:[image valueForKey:@"identifier"]] forCamera:self];
			
			if (lastFrame != NULL)
				cvReleaseImage(&lastFrame);
			
			lastFrame = cvCloneImage(current_frame);
			
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
										   description:@"Image captured."
												 value:@"65535"
												 match:NO];
		}
		else
		{
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
										   description:@"Image discarded for lack of significant changes"
												 value:@"0"
												 match:NO];
		}
		
		cvReleaseCapture(&camera);
	}

	[self didChangeValueForKey:LAST_UPDATE];
}

- (NSArray *) photoList
{
	NSMutableArray * images = [self valueForKey:@"images"];
	if (images == nil)
	{
		images = [NSMutableArray array];
		[self setValue:images forKey:@"images"];
	}
	
	NSMutableArray * list = [NSMutableArray array];
	
	NSEnumerator * iter = [images objectEnumerator];
	NSDictionary * dict = nil;
	while (dict = [iter nextObject])
	{
		NSString * photoId = [dict valueForKey:@"identifier"];
		
		if (photoId != nil)
			[list addObject:photoId];
	}
	
	return list;
}

- (NSDictionary *) photoForId:(NSString *) photoId
{
	NSMutableArray * images = [self valueForKey:@"images"];
	if (images == nil)
	{
		images = [NSMutableArray array];
		[self setValue:images forKey:@"images"];
	}
	
	NSDictionary * finalDict = nil;

	NSEnumerator * iter = [images objectEnumerator];
	NSDictionary * dict = nil;
	while (dict = [iter nextObject])
	{
		if (finalDict == nil && [[dict valueForKey:@"identifier"] isEqual:photoId])
			finalDict = dict;
	}
	
	return finalDict;
}

- (void) takePicture:(NSScriptCommand *) command
{
	[self setValue:@"" forKey:TAKE_PICTURE];
}


@end
