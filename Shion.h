/*
 *  Shion.h
 *  Shion
 *
 *  Created by Chris Karr on 12/27/08.
 *  Copyright 2008 CASIS LLC. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#define SHION_SNAPSHOTS @"Shion Snapshots"
#define SNAPSHOT @"snapshot"

#define TOGGLE_DEVICE @"Toggle Device"
#define CONTINUOUS_DEVICE @"Continuous Device"
#define THERMOSTAT_DEVICE @"Thermostat"
#define DIMMER_DEVICE @"One-Way Dimmer Device"
#define CONTROLLER_DEVICE @"Controller Device"
#define CHIME_DEVICE @"Chime"
#define SENSOR @"Sensor"
#define HOUSE @"House"
#define SPRINKLER @"Sprinkler"

#define MODEM_DEVICE @"Modem"

#define DEVICE @"device"

#define DEVICE_COMMAND @"Device Command"

#define STATUS_COMMAND @"Status Command"
#define GET_INFO_COMMAND @"Get Info Command"

#define SET_LEVEL_COMMAND @"Set Level"
#define SET_RAMP_RATE_COMMAND @"Set Ramp Rate"

#define SET_HVAC_MODE @"Set HVAC Mode"
#define SET_HVAC_COOL_POINT @"Set Cool Point"
#define SET_HVAC_HEAT_POINT @"Set Heat Point"

#define ACTIVATE_SPRINKLER_ZONE @"Activate Sprinkler Zone"
#define DEACTIVATE_SPRINKLER_ZONE @"Deactivate Sprinkler Zone"
#define SET_SPRINKLER_DIAGNOSTICS @"Set Sprinkler Diagnostics"
#define SET_SPRINKLER_RAIN @"Set Sprinkler Rain Sensor"
#define SET_SPRINKLER_PUMP @"Set Sprinkler Pump Mode"

#define FAN_ON @"Fan On"
#define FAN_OFF @"Fan Off"

#define BRIGHTEN_COMMAND @"Brighten Command"
#define DIM_COMMAND @"Dim Command"

#define CHIME_COMMAND @"Chime Command"

#define ALL_LIGHTS_ON_COMMAND @"All Lights On"
#define ALL_UNITS_OFF_COMMAND @"All Units Off"
#define ALL_LIGHTS_OFF_COMMAND @"All Lights Off"
#define HOUSE_COMMAND @"house_command"

#define COMMAND_VALUE @"Command Value"

#define SNAPSHOT_NAME @"name"
#define SNAPSHOT_ID @"id"
#define SNAPSHOT_DEVICES @"devices"
#define SNAPSHOT_STATUS @"device_status"

#define TRIGGER @"trigger"

SInt32 getVersion ();

