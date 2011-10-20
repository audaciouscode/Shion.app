//
//  Base64.h
//  Shion
//
//  Created by Chris Karr on 4/11/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Base64 : NSObject 
{

}

+ (NSData *) loadDataFromURLForcingBasicAuth:(NSURL *) url;

+ (void) initialize;
+ (NSString*) encode:(const uint8_t*) input length:(int) length;
+ (NSString*) encode:(NSData*) rawBytes;
+ (NSData*) decode:(const char*) string length:(int) inputLength;
+ (NSData*) decode:(NSString*) string;

@end
