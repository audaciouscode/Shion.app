//
//  Camera.h
//  Shion
//
//  Created by Chris Karr on 9/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenCV/OpenCV.h>

#import "Device.h"

#define CAMERA @"Camera"

@interface Camera : Device 
{
	IplImage * lastFrame;
	NSTimer * captureTimer;
	NSDate * lastUpdate;
}

+ (Camera *) camera;

- (void) captureImage;

- (NSArray *) photoList;
- (NSDictionary *) photoForId:(NSString *) photoId;

@end
