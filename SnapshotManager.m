//
//  SnapshotManager.m
//  Shion
//
//  Created by Chris Karr on 4/6/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "SnapshotManager.h"
#import "ConsoleManager.h"

@implementation SnapshotManager

static SnapshotManager * sharedInstance = nil;

+ (SnapshotManager *) sharedInstance
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            [[self alloc] init]; // assignment not done here
		}
    }
    return sharedInstance;
}

+ (id) allocWithZone:(NSZone *) zone
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
	
    return nil; //on subsequent allocation attempts return nil
}

- (id) copyWithZone:(NSZone *) zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (unsigned) retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void) release
{
    //do nothing
}

- (id) autorelease
{
    return self;
}

- (NSString *) snapshotStorageFolder 
{
	NSString * applicationSupportFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder (kUserDomain, kApplicationSupportFolderType, kCreateFolder, &foundRef);
	
	if (err != noErr) 
	{
		return nil;
	}
	else 
	{
		unsigned char path[1024];
		FSRefMakePath (&foundRef, path, sizeof(path));
		applicationSupportFolder = [NSString stringWithUTF8String:(char *) path];
		applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"Shion"];
	}
	
	BOOL isDir;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportFolder isDirectory:&isDir])
		[[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportFolder attributes:[NSDictionary dictionary]];
	
	return applicationSupportFolder;
}

- (void) loadSnapshots
{
	if ([snapshots count] > 0)
		[snapshots removeAllObjects];
	
	NSString * storageFolder = [self snapshotStorageFolder];
	
	NSDirectoryEnumerator * fileIter = [[NSFileManager defaultManager] enumeratorAtPath:storageFolder];
	NSString * file = nil;
	while (file = [fileIter nextObject]) 
	{
		if ([[file pathExtension] isEqualToString:@"snapshot"]) 
		{
			NSData * data = [NSData dataWithContentsOfFile:[storageFolder stringByAppendingPathComponent:file]];
			
			if (data)
			{
				Snapshot * snapshot = [Snapshot snapshotFromData:data];
				
				[snapshots addObject:snapshot];
			}
		}
	}
}

- (Snapshot *) snapshotWithIdentifier:(NSString *) identifier
{
	Snapshot * finalSnapshot = nil;

	NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
	
	NSEnumerator * snapIter = [snapshots objectEnumerator];
	Snapshot * snap = nil;
	while (snap = [snapIter nextObject])
	{
		if (finalSnapshot == nil && [[snap identifier] isEqual:identifier])
			finalSnapshot = snap;
	}
	
	[innerPool drain];
	
	return finalSnapshot;
}

- (id) init
{
	if (self = [super init])
	{
		snapshots = [[NSMutableArray alloc] init];

		[self loadSnapshots];
	}
	
	return self;
}

- (NSArray *) snapshots
{
	return [NSArray arrayWithArray:snapshots];
}

- (Snapshot *) createSnapshot
{
	Snapshot * snapshot = [Snapshot snapshot];
	
	[snapshots addObject:snapshot];
	
	return snapshot;
}

- (void) saveSnapshots
{
	NSString * snapsFolder = [self snapshotStorageFolder];
	
	NSEnumerator * snapIter = [snapshots objectEnumerator];
	Snapshot * snap = nil;
	while (snap = [snapIter nextObject])
	{
		if ([snap isDirty])
		{
			NSData * data = [snap data];
		
			if (data)
			{
				NSString * filename = [NSString stringWithFormat:@"%@.snapshot", [snap identifier]];
				NSString * devicePath = [snapsFolder stringByAppendingPathComponent:filename];
			
				[data writeToFile:devicePath atomically:YES];
			}
		}
	}
}

- (void) removeSnapshot:(Snapshot *) snapshot
{
	int choice = NSRunAlertPanel(@"Delete snapshot?", [NSString stringWithFormat:@"Are you sure that you wish to remove %@?", [snapshot name]], @"No", @"Yes", nil);
	
	if (choice == 0)
	{
		NSString * snapsFolder = [self snapshotStorageFolder];
		
		NSString * filename = [NSString stringWithFormat:@"%@.snapshot", [snapshot identifier]];
		NSString * snapshotPath = [snapsFolder stringByAppendingPathComponent:filename];
		
		// TODO: Add 10.4 & 10.5+ specific handling code here...
		
		[[NSFileManager defaultManager] removeFileAtPath:snapshotPath handler:nil];
		
		[snapshots removeObject:snapshot];
	}
}

@end
