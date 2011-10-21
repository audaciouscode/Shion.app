//
//  DeviceManager.m
//  Shion
//
//  Created by Chris Karr on 12/21/08.
//  Copyright 2008 CASIS LLC. All rights reserved.
//

#import "DeviceManager.h"

#import <AddressBook/AddressBook.h>

#import <Shion/ASPowerLinc2414Controller.h>
#import <Shion/ASPowerLinc2412Controller.h>
#import <Shion/ASPowerLincSerialRFController.h>
#import <Shion/ASCM15AUSBController.h>
#import <Shion/ASCM11AController.h>
#import <Shion/ASCM17AController.h>
#import <Shion/ASSmartLincWebController.h>
#import <Shion/ASSmartLincDirectController.h>
#import <Shion/ASEzSrveWebController.h>
#import <Shion/ASThermostatDevice.h>
#import <Shion/ASSerialPortAddress.h>
#import <Shion/ASSerialPortModemDevice.h>

#import "PreferencesManager.h"
#import "EventManager.h"
#import "ConsoleManager.h"
#import "Controller.h"
#import "Appliance.h"
#import "MotionSensor.h"
#import "ApertureSensor.h"
#import "PowerSensor.h"
#import "PowerMeterSensor.h"
#import "Thermostat.h"
#import "Phone.h"
#import "Camera.h"
#import "GarageHawk.h"

#import "AMSerialPortList.h"
#import "AMSerialPort.h"

#import "Shion.h"

#define X10_ADDRESS @"X10 Address"
#define X10_COMMAND @"X10 Command"

@implementation DeviceManager

#pragma mark -
#pragma mark Singleton Methods

static DeviceManager * sharedInstance = nil;

- (NSString *) deviceStorageFolder 
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

- (Controller *) usbController
{
	Controller * finalController = nil;
	
	NSEnumerator * iter = [[ASDeviceController findControllers] objectEnumerator];
	ASDeviceController * controllerDevice = nil;
	if (controllerDevice = [iter nextObject])
	{
		Controller * controller = [Controller controller];
		
		[controller setDeviceController:controllerDevice];
		
		if ([controllerDevice getAddress] != nil)
			[controller setAddress:[[controllerDevice getAddress] description]];
		
		if ([controllerDevice isMemberOfClass:[ASPowerLinc2414Controller class]])
		{
			[controller setModel:@"PowerLinc 2414"];
			[controller setPlatform:@"Insteon"];
		}
		else if ([controllerDevice isMemberOfClass:[ASCM15AUSBController class]])
		{
			[controller setModel:@"CM15A"];
			[controller setPlatform:@"X10"];
		}
		else
		{
			[controller setModel:@"Unknown USB Controller"];
			[controller setPlatform:@"Unknown Platform"];
		}
		
		// TODO: PowerLinc 1132CU
		
		[controller setName:[controller model]];
		
		finalController = controller;
	}
	
	return finalController;
}

- (Controller *) serialControllerForDetails:(NSDictionary *) details
{
	NSString * portName = [details valueForKey:SERIAL_CONTROLLER_PORT];
	NSString * portPath = nil;
	
	NSEnumerator * portIter = [[[AMSerialPortList sharedPortList] serialPorts] objectEnumerator];
	AMSerialPort * port = nil;
	while (port = [portIter nextObject])
	{
		if ([[port name] isEqual:portName])
			portPath = [port bsdPath];
	}
	
	if (portPath == nil)
		return nil;
	
	Controller * controller = nil;
	
	if ([[details valueForKey:SERIAL_CONTROLLER_MODEL] isEqual:CONTROLLER_PL2412])
	{
		ASPowerLinc2412Controller * controllerDevice = [ASPowerLinc2412Controller controllerWithPath:portPath];
		
		if (controllerDevice != nil)
		{
			controller = [Controller controller];
			
			[controller setDeviceController:controllerDevice];
			
			if ([controllerDevice getAddress] != nil)
				[controller setAddress:[[controllerDevice getAddress] description]];
			
			[controller setModel:@"PowerLinc 2412"];
			[controller setPlatform:@"Insteon"];
			
			[controller setName:[controller model]];
		}
	}
	else if ([[details valueForKey:SERIAL_CONTROLLER_MODEL] isEqual:CONTROLLER_PL2413])
	{
		ASPowerLinc2412Controller * controllerDevice = [ASPowerLinc2412Controller controllerWithPath:portPath];
		
		if (controllerDevice != nil)
		{
			controller = [Controller controller];
			
			[controller setDeviceController:controllerDevice];
			
			if ([controllerDevice getAddress] != nil)
				[controller setAddress:[[controllerDevice getAddress] description]];
			
			[controller setModel:@"PowerLinc 2413"];
			[controller setPlatform:@"Insteon"];
			
			[controller setName:[controller model]];
		}
	}
	else if ([[details valueForKey:SERIAL_CONTROLLER_MODEL] isEqual:CONTROLLER_PLRFUSB])
	{
		ASPowerLincSerialRFController * controllerDevice = [ASPowerLincSerialRFController controllerWithPath:portPath];
		
		if (controllerDevice != nil)
		{
			controller = [Controller controller];
			
			[controller setDeviceController:controllerDevice];
			
			if ([controllerDevice getAddress] != nil)
				[controller setAddress:[[controllerDevice getAddress] description]];
			
			[controller setModel:@"INSTEON Portable USB Adapter"];
			[controller setPlatform:@"Insteon"];
			
			[controller setName:[controller model]];
		}
	}
	else if ([[details valueForKey:SERIAL_CONTROLLER_MODEL] isEqual:CONTROLLER_CM11A])
	{
		ASCM11AController * controllerDevice = [ASCM11AController controllerWithPath:portPath];
		
		if (controllerDevice != nil)
		{
			controller = [Controller controller];
			
			[controller setDeviceController:controllerDevice];
			
			[controller setModel:@"CM11A"];
			[controller setPlatform:@"X10"];
			
			[controller setName:[controller model]];
		}
	}
	else if ([[details valueForKey:SERIAL_CONTROLLER_MODEL] isEqual:CONTROLLER_CM17A])
	{
		ASCM17AController * controllerDevice = [ASCM17AController controllerWithPath:portPath];
		
		if (controllerDevice != nil)
		{
			controller = [Controller controller];
			
			[controller setDeviceController:controllerDevice];
			
			[controller setModel:@"CM17A Firecracker"];
			[controller setPlatform:@"X10"];
			
			[controller setName:[controller model]];
		}
	}
	
	return controller;
}

- (Controller *) networkControllerForDetails:(NSDictionary *) details
{
	NSString * address = [details valueForKey:NETWORK_CONTROLLER_ADDRESS];
	
	Controller * controller = nil;
	
	if ([[details valueForKey:NETWORK_CONTROLLER_MODEL] isEqual:CONTROLLER_SL2414])
	{
		ASSmartLincWebController * controllerDevice = [[[ASSmartLincWebController alloc] initWithHost:address] autorelease];
		
		if (controllerDevice != nil)
		{
			controller = [Controller controller];
			
			[controller setDeviceController:controllerDevice];
			
			if ([controllerDevice getAddress] != nil)
				[controller setAddress:[[controllerDevice getAddress] description]];
			
			[controller setModel:@"SmartLinc 2414N"];
			[controller setPlatform:@"Insteon"];
			
			[controller setName:[controller model]];
		}
	}
	else if ([[details valueForKey:NETWORK_CONTROLLER_MODEL] isEqual:CONTROLLER_SL2414_BETA])
	{
		ASSmartLincDirectController * controllerDevice = [[[ASSmartLincDirectController alloc] initWithHost:address] autorelease];
		
		if (controllerDevice != nil)
		{
			controller = [Controller controller];
			
			[controller setDeviceController:controllerDevice];
			
			if ([controllerDevice getAddress] != nil)
				[controller setAddress:[[controllerDevice getAddress] description]];
			
			[controller setModel:@"SmartLinc 2414N (Beta)"];
			[controller setPlatform:@"Insteon"];
			
			[controller setName:[controller model]];
		}
	}
	else if ([[details valueForKey:NETWORK_CONTROLLER_MODEL] isEqual:CONTROLLER_EZSRVE])
	{
		NSString * ipAddress = [ASEzSrveWebController findController];

		if (ipAddress != nil)
		{
			address = ipAddress;
			[[PreferencesManager sharedInstance] setValue:ipAddress forKey:NETWORK_CONTROLLER_ADDRESS];
		}
		
		ASEzSrveWebController * controllerDevice = [[[ASEzSrveWebController alloc] initWithHost:address] autorelease];
		
		if (controllerDevice != nil)
		{
			controller = [Controller controller];
			
			[controller setDeviceController:controllerDevice];
			
			if ([controllerDevice getAddress] != nil)
				[controller setAddress:[[controllerDevice getAddress] description]];
			
			[controller setModel:@"EzServe 2.0"];
			[controller setPlatform:@"Insteon"];
			
			[controller setName:[controller model]];
		}
	}
	
	return controller;
}

- (Controller *) controllerForDetails:(NSDictionary *) details
{
	Controller * controller = nil;
	
	if ([[details valueForKey:CONTROLLER_TYPE] isEqual:CONTROLLER_USB])
		controller = [self usbController];
	else if ([[details valueForKey:CONTROLLER_TYPE] isEqual:CONTROLLER_SERIAL])
		controller = [self serialControllerForDetails:details];
	else if ([[details valueForKey:CONTROLLER_TYPE] isEqual:CONTROLLER_NETWORK])
		controller = [self networkControllerForDetails:details];
	
	if (controller != nil)
	{
		NSString * location = [details valueForKey:CONTROLLER_LOCATION];
		
		if (location == nil)
			location = @"Unknown Location";
		
		[controller setLocation:location];
		
		NSNumber * fav = [[PreferencesManager sharedInstance] valueForKey:@"controller_favorite"];
		
		if (fav != nil)
			[controller setValue:fav forKey:@"favorite"];
	}
	
	return controller;
}

- (Phone *) phoneForDetails:(NSDictionary *) details
{
	AMSerialPortList * portList = [AMSerialPortList sharedPortList];
	
	AMSerialPort * serialPort = [portList objectWithName:[details valueForKey:MODEM_PORT]];
	
	if (serialPort != nil)
	{
		ASSerialPortAddress * address = [[ASSerialPortAddress alloc] init];
		[address setPort:[serialPort bsdPath]];

		ASSerialPortModemDevice * modemDevice = [[ASSerialPortModemDevice alloc] init];
		[modemDevice setAddress:address];
		[modemDevice setModel:[details valueForKey:MODEM_MODEL]];
		[modemDevice go];
		
		Phone * phone = [Phone phone];
		[phone setAddress:[serialPort bsdPath]];
		[phone setModel:[details valueForKey:MODEM_MODEL]];
		[phone setName:[details valueForKey:MODEM_MODEL]];
		[phone setLocation:[details valueForKey:MODEM_LOCATION]];
				
		[address release];
					
		[phone setValue:modemDevice forKey:FRAMEWORK_DEVICE];
		[modemDevice release];

		NSNumber * fav = [[PreferencesManager sharedInstance] valueForKey:@"phone_favorite"];
		
		if (fav != nil)
			[phone setValue:fav forKey:@"favorite"];
		
		[phone setPlatform:@"Native Peripheral"];
		
		return phone;
	}
	
	return nil;
}

- (void) loadDevices
{
	if ([devices count] > 0)
		[devices removeAllObjects];
	
	NSString * storageFolder = [self deviceStorageFolder];
	
	NSDirectoryEnumerator * fileIter = [[NSFileManager defaultManager] enumeratorAtPath:storageFolder];
	NSString * file = nil;
	while (file = [fileIter nextObject]) 
	{
		if ([[file pathExtension] isEqualToString:@"device"]) 
		{
			NSData * data = [NSData dataWithContentsOfFile:[storageFolder stringByAppendingPathComponent:file]];
			
			if (data)
			{
				Device * device = [Device deviceFromData:data];
				
				[devices addObject:device];
			}
		}
	}
	
	Controller * controller = [self controllerForDetails:[[PreferencesManager sharedInstance] controllerDetails]];
	
	if (controller)
		[devices addObject:controller];
	
	Phone * phone = [self phoneForDetails:[[PreferencesManager sharedInstance] phoneDetails]];
	
	if (phone)
		[devices addObject:phone];
}

+ (DeviceManager *) sharedInstance
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

#pragma mark -
#pragma mark Standard Class Methods

- (id) init
{
	if (self = [super init])
	{
		devices = [[NSMutableArray alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUpdate:) name:DEVICE_UPDATE_NOTIFICATION object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUpdate:) name:X10_COMMAND_NOTIFICATION object:nil];
		
		[self loadDevices];
		
		refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(refreshDevices:) userInfo:nil repeats:YES] retain];
		currentStatusDevice = 0;
	}
	
	return self;
}

- (Device *) createDevice:(NSString *) type platform:(NSString *) platform
{
	Device * device = [Device deviceForType:type platform:platform];
	
	[devices addObject:device];

	return device;
}

- (NSArray *) devices
{
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];

	NSArray * sorted = [devices sortedArrayUsingDescriptors:[NSArray arrayWithObjects:sort, nil]];
	
	[sort release];
	
	return sorted;
}

- (void) saveDevices
{
	NSString * devicesFolder = [self deviceStorageFolder];
	
	NSEnumerator * deviceIter = [devices objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		if ([device isDirty])
		{
			NSData * data = [device data];
		
			if (data)
			{
				NSString * filename = [NSString stringWithFormat:@"%@.device", [device identifier]];
				NSString * devicePath = [devicesFolder stringByAppendingPathComponent:filename];
			
				[data writeToFile:devicePath atomically:YES];
			}
			
			[device clearDirty];
		}
	}
}

- (IBAction) refreshDevices:(id) sender
{
	if ([devices count] < 1)
		return;
	
	if (currentStatusDevice >= [devices count])
		currentStatusDevice = 0;
	
	[[devices objectAtIndex:currentStatusDevice] fetchStatus];

	currentStatusDevice += 1;
}

- (ASDeviceController *) controllerDevice
{
	ASDeviceController * finalController = nil;
	NSEnumerator * deviceIter = [devices objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		if (finalController == nil && [device isKindOfClass:[Controller class]])
			finalController = [((Controller *) device) deviceController];
	}
	
	return finalController;
}

- (Device *) deviceWithIdentifier:(NSString *) identifier
{
	Device * finalDevice = nil;

	NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
	
	NSEnumerator * deviceIter = [devices objectEnumerator];
	
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		if (finalDevice == nil && [identifier isEqual:[device identifier]])
			finalDevice = device;
	}
	
	[innerPool drain];

	return finalDevice;
}

- (void) sendCommand:(NSDictionary *) command
{
	ASDeviceController * controller = [self controllerDevice];
	
	if (controller != nil)
	{
		ASDevice * device = [command valueForKey:DEVICE];
		
		unsigned int commandType = [[command valueForKey:DEVICE_COMMAND] unsignedIntValue];
		NSObject * value = [command valueForKey:COMMAND_VALUE];
		
		ASCommand * asCommand = nil;
		
		if (value == nil)
			asCommand = [controller commandForDevice:device kind:commandType];
		else
			asCommand = [controller commandForDevice:device kind:commandType value:value];

		if (asCommand != nil)
			[controller queueCommand:asCommand];
		
		// Update the status of X10 devices on house commands...
		
		/*	if (([command isEqual:ALL_UNITS_OFF_COMMAND] || [command isEqual:ALL_LIGHTS_ON_COMMAND] || 
		 [command isEqual:ALL_LIGHTS_OFF_COMMAND]) && [address isKindOfClass:[ASX10Address class]])
		 {
		 unsigned char houseCode = [((ASX10Address *) address) getAddressByte];
		 
		 if (houseCode != 0x00)
		 houseCode = (houseCode & 0xf0);
		 
		 DeviceDictionary * x10Device = nil;
		 NSEnumerator * iter = [[devices arrangedObjects] objectEnumerator];
		 while (x10Device = [iter nextObject])
		 {
		 NSString * addressString = [x10Device valueForKey:SHION_ADDRESS];
		 
		 if ([addressString length] < 6)
		 {
		 ASX10Address * deviceAddress = [[ASX10Address alloc] init];
		 [deviceAddress setAddress:addressString];
		 
		 unsigned char deviceCode = [((ASX10Address *) deviceAddress) getAddressByte];
		 
		 if ((deviceCode & 0xf0) == houseCode)
		 {
		 NSString * deviceType = [x10Device valueForKey:SHION_TYPE];
		 
		 [x10Device setValue:[NSNumber numberWithBool:YES] forKey:FROZEN];
		 
		 if ([command isEqual:ALL_UNITS_OFF_COMMAND])
		 [x10Device setValue:[NSNumber numberWithInt:0] forKey:TOGGLE_STATE];
		 else if ([command isEqual:ALL_LIGHTS_ON_COMMAND] && [deviceType isEqual:CONTINUOUS_DEVICE])
		 [x10Device setValue:[NSNumber numberWithInt:255] forKey:TOGGLE_STATE];
		 else if ([command isEqual:ALL_LIGHTS_OFF_COMMAND] && [deviceType isEqual:CONTINUOUS_DEVICE])
		 [x10Device setValue:[NSNumber numberWithInt:0] forKey:TOGGLE_STATE];
		 
		 [x10Device setValue:[NSNumber numberWithBool:NO] forKey:FROZEN];
		 }
		 
		 [deviceAddress release];
		 }
		 }
		 } */
	}
}

- (void) removeDevice:(Device *) device
{
	int choice = NSRunAlertPanel(@"Delete device?", [NSString stringWithFormat:@"Are you sure that you wish to remove %@?", [device name]], @"No", @"Yes", nil);
	
	if (choice == 0)
	{
		NSString * devicesFolder = [self deviceStorageFolder];
	
		NSString * filename = [NSString stringWithFormat:@"%@.device", [device identifier]];
		NSString * devicePath = [devicesFolder stringByAppendingPathComponent:filename];
	
		// TODO: Add 10.4 & 10.5+ specific handling code here...
	
		[[NSFileManager defaultManager] removeFileAtPath:devicePath handler:nil];
	
		[devices removeObject:device];
	}
}

- (void) deviceUpdate:(NSNotification *) theNote
{
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithDictionary:[theNote userInfo]];

	if ([userInfo valueForKey:X10_ADDRESS] != nil)
	{
		[userInfo setValue:[userInfo valueForKey:X10_ADDRESS] forKey:DEVICE_ADDRESS];
		
		NSString * command = [userInfo valueForKey:X10_COMMAND];
		
		if ([command hasSuffix:NSLocalizedString(@"Off", nil)])
			[userInfo setValue:[NSNumber numberWithInt:0] forKey:DEVICE_STATE];
		else 
			[userInfo setValue:[NSNumber numberWithInt:255] forKey:DEVICE_STATE];
	}
	
	NSString * cmdAddress = [[userInfo valueForKey:DEVICE_ADDRESS] lowercaseString];
	
	NSEnumerator * iter = [devices objectEnumerator];
	Device * device = nil;
	while (device = [iter nextObject])
	{
		NSString * address = [[device address] lowercaseString];
		
		if ([device isKindOfClass:[Controller class]] && [[userInfo valueForKey:DEVICE_TYPE] isEqual:CONTROLLER_DEVICE])
		{
			[device setAddress:cmdAddress];
			[device setModel:[userInfo valueForKey:DEVICE_MODEL]];
			[device setVersion:[userInfo valueForKey:DEVICE_FIRMWARE]];
			
			// TODO: Set last updated...
		}
		else
		{
			if ([cmdAddress isEqual:address])
			{
				[device willChangeValueForKey:LAST_UPDATE];

				[device recordResponse];
				
				if ([userInfo valueForKey:DEVICE_MODEL] != nil)
					[device setModel:[userInfo valueForKey:DEVICE_MODEL]];
				
				if ([userInfo valueForKey:DEVICE_FIRMWARE] != nil)
					[device setVersion:[userInfo valueForKey:DEVICE_FIRMWARE]];
				
				if ([userInfo valueForKey:DEVICE_STATE] != nil)
				{
					[device disarm];
					
					if ([device isKindOfClass:[Appliance class]])
					{
						NSNumber * level = [userInfo valueForKey:DEVICE_STATE];
					
						[device setValue:level forKey:DEVICE_LEVEL];
					}
					else if ([device isKindOfClass:[MotionSensor class]])
					{
						NSNumber * level = [userInfo valueForKey:DEVICE_STATE];
						
						NSString * message = [NSString stringWithFormat:@"%@ detected motion.", [device name]];
						
						if ([level intValue] == 0)
							message = [NSString stringWithFormat:@"%@ ceased detecting motion.", [device name]];
						
						[[EventManager sharedInstance] createEvent:@"device" source:[device identifier] initiator:[device identifier]
													   description:message value:level];
					}
					else if ([device isKindOfClass:[ApertureSensor class]])
					{
						NSNumber * level = [userInfo valueForKey:DEVICE_STATE];
						
						NSString * message = [NSString stringWithFormat:@"%@ is open.", [device name]];
						
						if ([level intValue] == 0)
							message = [NSString stringWithFormat:@"%@ is closed.", [device name]];
						
						[[EventManager sharedInstance] createEvent:@"device" source:[device identifier] initiator:[device identifier]
													   description:message value:level];
					}
					else if ([device isKindOfClass:[PowerSensor class]])
					{
						NSNumber * level = [userInfo valueForKey:DEVICE_STATE];
						
						NSString * message = [NSString stringWithFormat:@"%@ is active.", [device name]];
						
						if ([level intValue] == 0)
							message = [NSString stringWithFormat:@"%@ is inactive.", [device name]];
						
						[[EventManager sharedInstance] createEvent:@"device" source:[device identifier] initiator:[device identifier]
													   description:message value:level];
					}
					else if ([device isKindOfClass:[Thermostat class]])
					{
						Thermostat * therm = (Thermostat *) device;
						
						NSNumber * level = [userInfo valueForKey:DEVICE_STATE];
						
						if(level != nil)
							[therm setRunning:([level intValue] != 0)];
					}
					else if ([device isKindOfClass:[GarageHawk class]])
					{
						NSNumber * level = [userInfo valueForKey:DEVICE_STATE];
						
						NSString * message = [NSString stringWithFormat:@"%@ detected motion.", [device name]];
						
						if ([level intValue] == 0)
							message = [NSString stringWithFormat:@"%@ is closed.", [device name]];
						else if ([level intValue] < 128)
							message = [NSString stringWithFormat:@"%@ is closing.", [device name]];
						else if ([level intValue] < 192)
							message = [NSString stringWithFormat:@"%@ is open.", [device name]];
						else if ([level intValue] < 255)
							message = [NSString stringWithFormat:@"%@ is in an unknown state.", [device name]];
						else
							message = [NSString stringWithFormat:@"%@ is experiencing errors.", [device name]];
						
						[[EventManager sharedInstance] createEvent:@"device" source:[device identifier] initiator:[device identifier]
													   description:message value:level];

						[device setValue:level forKey:DEVICE_LEVEL];
					}
					
					[device arm];
				}
				
				if ([device isKindOfClass:[Thermostat class]])
				{
					[device disarm];
					
					Thermostat * thermostat = (Thermostat *) device;
					
					NSNumber * mode = [userInfo valueForKey:THERMOSTAT_MODE];
					
					if (mode != nil)
					{
						NSString * modeString = [NSString stringWithFormat:@"Unknown Mode (%d)", [mode intValue]];
						
						if ([mode intValue] == 0)
							modeString = @"Off";
						else if ([mode intValue] == 1)
							modeString = @"Heat";
						else if ([mode intValue] == 2)
							modeString = @"Cool";
						else if ([mode intValue] == 3)
							modeString = @"Auto";
						else if ([mode intValue] == 4)
							modeString = @"Fan";
						else if ([mode intValue] == 5)
							modeString = @"Program";
						else if ([mode intValue] == 6)
							modeString = @"Program Heat";
						else if ([mode intValue] == 7)
							modeString = @"Program Cool";
						
						[thermostat setMode:modeString];
					}
					
					NSNumber * temperature = [userInfo valueForKey:THERMOSTAT_TEMPERATURE];
					
					if (temperature != nil)
						[thermostat setTemperature:temperature];

					NSNumber * coolPoint = [userInfo valueForKey:THERMOSTAT_COOL_POINT];
					
					if (coolPoint != nil)
						[thermostat setCoolPoint:coolPoint];

					NSNumber * heatPoint = [userInfo valueForKey:THERMOSTAT_HEAT_POINT];
					
					if (heatPoint != nil)
						[thermostat setHeatPoint:heatPoint];

					[device arm];
				}
				else if ([device isKindOfClass:[Phone class]])
				{
					Phone * phone = (Phone *) device;

					NSString * caller = [userInfo valueForKey:CID_NAME];
					NSString * number = [userInfo valueForKey:CID_NUMBER];

					if (caller != nil && number != nil)
					{
						number = [Phone normalizePhoneNumber:number];
				 
						ABPerson * person = [Phone findPersonByNumber:number];
				 
						// NSData * icon = nil;
				 
						if (person != nil)
						{
							NSString * newName = [NSString stringWithFormat:@"%@ %@", [person valueForProperty:kABFirstNameProperty],
												  [person valueForProperty:kABLastNameProperty], nil];
				 
							BOOL isCompany = ([[person valueForProperty:kABPersonFlags] intValue] & kABShowAsMask) == kABShowAsCompany;
				 
							if (isCompany)
							{
								NSString * orgName = [person valueForProperty:kABOrganizationProperty];
				 
								if (orgName != nil)
									newName = orgName;
							}
				 
							caller = newName;
						}
				 
						NSMutableDictionary * call = [NSMutableDictionary dictionary];
						[call setValue:caller forKey:@"caller_name"];
						[call setValue:number forKey:@"number"];

						[[ConsoleManager sharedInstance] willChangeValueForKey:@"phoneCallArray"];
						[phone addCall:call];
						[[ConsoleManager sharedInstance] didChangeValueForKey:@"phoneCallArray"];
					}
					else 
					{
						// What do do on rings? Flash icon?
					}
				}
				else if ([device isKindOfClass:[PowerMeterSensor class]])
				{
					PowerMeterSensor * sensor = (PowerMeterSensor *) device;
					
					[sensor setCurrentPower:[NSNumber numberWithInt:[[userInfo valueForKey:CURRENT_POWER] intValue]]];
					[sensor setTotalPower:[NSNumber numberWithFloat:[[userInfo valueForKey:ACCUMULATED_POWER] floatValue]]];
				}
				
				[device didChangeValueForKey:LAST_UPDATE];
			}
		}
	}
}


// -- OLD


/*
 
 
  
 - (void) loadControllers
 {
 NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
 NSString * type = [defaults valueForKey:@"controller_type"];
 
 if ([type isEqual:NSLocalizedString(@"Serial Port", nil)])
 {
 controller = [serialPortManager getController];
 
 if (controller != nil)
 {
 serial = controller;
 
 DeviceDictionary * device = [[DeviceDictionary alloc] init];
 
 [device setObject:controller forKey:DEVICE];
 [device setObject:CONTROLLER_DEVICE forKey:SHION_TYPE];
 [device setObject:[[controller getAddress] description] forKey:SHION_ADDRESS];
 [device setObject:[NSNumber numberWithBool:NO] forKey:IS_EDITABLE];
 
 if ([controller getType] != nil)
 [device setObject:[controller getType] forKey:SHION_MODEL];
 else if ([controller isMemberOfClass:[ASCM11AController class]])
 {
 [device setObject:@"CM11A" forKey:SHION_MODEL];
 [device removeObjectForKey:SHION_ADDRESS];
 }
 else if ([controller isMemberOfClass:[ASCM15AUSBController class]])
 {
 [device setObject:@"CM15A" forKey:SHION_MODEL];
 [device removeObjectForKey:SHION_ADDRESS];
 }
 else if ([controller isMemberOfClass:[ASPowerLinc2412Controller class]])
 {
 [device setObject:@"PowerLinc Modem" forKey:SHION_MODEL];
 [device removeObjectForKey:SHION_ADDRESS];
 }
 
 if ([controller getName] != nil)
 [device setObject:[controller getName] forKey:SHION_NAME];
 else
 [device setObject:[device valueForKey:SHION_MODEL] forKey:SHION_NAME];
 
 [devices addObject:device];
 
 [device release];
 }
 }
 else if ([type isEqual:NSLocalizedString(@"Network", nil)])
 {
 NSString * ezAddress = [ASEzSrveWebController findController];
 
 if (ezAddress != nil)
 {
 NSString * address = [NSString stringWithFormat:@"socket://%@:8002", ezAddress];
 
 [[NSUserDefaults standardUserDefaults] setValue:address forKey:@"plc_url"];
 
 ASEzSrveWebController * ezController = [[ASEzSrveWebController alloc] initWithHost:ezAddress];
 
 DeviceDictionary * device = [[DeviceDictionary alloc] init];
 
 [device setObject:ezController forKey:DEVICE];
 [device setObject:CONTROLLER_DEVICE forKey:SHION_TYPE];
 
 [device setObject:[NSNumber numberWithBool:NO] forKey:IS_EDITABLE];
 
 [device setObject:@"Simplehomenet EZServe" forKey:SHION_MODEL];
 
 [device setObject:@"EZServe" forKey:SHION_NAME];
 
 [devices addObject:device];
 [device release];
 }
 else
 {
 NSString * address = [[NSUserDefaults standardUserDefaults] valueForKey:@"plc_url"];
 
 ASSmartLincWebController * slController = [[ASSmartLincWebController alloc] initWithRoot:address];
 
 DeviceDictionary * device = [[DeviceDictionary alloc] init];
 
 [device setObject:slController forKey:DEVICE];
 [device setObject:CONTROLLER_DEVICE forKey:SHION_TYPE];
 [device setObject:address forKey:SHION_ADDRESS];
 [device setObject:[NSNumber numberWithBool:NO] forKey:IS_EDITABLE];
 
 [device setObject:@"SmartLinc 2412N" forKey:SHION_MODEL];
 
 [device setObject:@"SmartLinc" forKey:SHION_NAME];
 
 [devices addObject:device];
 [device release];
 }
 }
 }
 
  - (void) awakeFromNib
 {
 lastActionDate = [[NSDate date] retain];
 
 currentDevice = -1;
 initDone = NO;
 
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUpdate:) name:DEVICE_UPDATE_NOTIFICATION object:nil];
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendCommand:) name:DEVICE_COMMAND object:nil];
 
 statusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(status:) userInfo:nil repeats:YES];
 
 [[serialPortManager valueForKey:MODELS] addObserver:self forKeyPath:@"selection" options:0 context:NULL];
 [[serialPortManager valueForKey:PORTS] addObserver:self forKeyPath:@"selection" options:0 context:NULL];
 [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"use_comm_port" options:0 context:NULL];
 
 [devices addObserver:self forKeyPath:@"selection" options:0 context:NULL];
 [devices addObserver:self forKeyPath:@"arrangedObjects" options:0 context:NULL];
 
 [devices setSelectedObjects:[NSArray array]];
 
 [self loadControllers];
 
 [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"modem_model" options:0 context:NULL];
 [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"modem_port" options:0 context:NULL];
 }
 
 - (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
 {
 if ([keyPath isEqualTo:@"selection"])
 {
 [self willChangeValueForKey:@"canRemove"];
 [self didChangeValueForKey:@"canRemove"];
 
 [self willChangeValueForKey:@"hasStatus"];
 [self didChangeValueForKey:@"hasStatus"];
 }
 else if ([keyPath isEqualTo:@"arrangedObjects"])
 {
 [self willChangeValueForKey:@"canAdd"];
 [self didChangeValueForKey:@"canAdd"];
 
 [self willChangeValueForKey:@"motionDevices"];
 [self didChangeValueForKey:@"motionDevices"];
 
 [self setupModem];
 }
 else if ([keyPath isEqualTo:@"modem_model"] || [keyPath isEqualTo:@"modem_port"])
 [self setupModem];
 else
 [self loadControllers];
 }
 
 
 
 - (NSNumber *) idleTime
 {
 NSNumber * idle = [NSNumber numberWithFloat:(0 - [lastActionDate timeIntervalSinceNow])];
 
 return idle;
 }
 */

/*
 
 - (IBAction) openUrl:(id) sender
 {
 NSURL * url = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] valueForKey:@"plc_url"]];
 
 if (url != nil)
 [[NSWorkspace sharedWorkspace] openURL:url];
 else
 NSRunAlertPanel(@"Enter URL For Controller", @"Please enter a valid URL for the controller", @"OK", nil, nil);
 }
 
 */

@end
