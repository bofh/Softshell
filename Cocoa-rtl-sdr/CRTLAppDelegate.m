//
//  CRTLAppDelegate.m
//  Cocoa-rtl-sdr
//
//  Created by William Dillon on 4/29/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import "CRTLAppDelegate.h"

@implementation CRTLAppDelegate

@synthesize window = _window;
@synthesize deviceComboBox;

- (void)dealloc
{
    [super dealloc];
}

- (NSArray *)deviceList
{
    return deviceList;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSArray *tempDeviceList = [RTLSDRDevice deviceList];
    
    deviceList = [[NSMutableArray alloc] initWithCapacity:[tempDeviceList count]];
    for (NSDictionary *dict in tempDeviceList) {
        NSString *name = [dict objectForKey:@"deviceName"];
        if (name == nil) {
            NSLog(@"Nil name received from device list...  this is bad.");
        } else {
            [deviceList addObject:name];
        }
    }
    
    [deviceComboBox bind:NSContentBinding
                toObject:self
             withKeyPath:@"self.deviceList"
                 options:nil];
    [deviceComboBox selectItemAtIndex:0];
}

- (IBAction)openDevice:(id)sender
{
    NSInteger index = [deviceComboBox indexOfSelectedItem];
    device = [[RTLSDRDevice alloc] initWithDeviceIndex:index];
    
    if (device == nil) {
        NSLog(@"Unable to open device");
    } else {
        if ([device tuner] != nil) {
            [tunerTypeField setStringValue:[[device tuner] tunerType]];
        }
    }
    
    
}

         
@end
