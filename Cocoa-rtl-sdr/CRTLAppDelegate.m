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
@synthesize deviceList;
@synthesize deviceComboBox;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    deviceList = [RTLSDRDevice deviceList];
    [deviceComboBox bind:NSContentBinding toObject:self
             withKeyPath:@"deviceList" options:nil];
    [deviceComboBox selectItemAtIndex:0];
}

- (IBAction)openDevice:(id)sender
{
    NSInteger index = [deviceComboBox indexOfSelectedItem];
    device = [[RTLSDRDevice alloc] initWithDeviceIndex:index];
    
    if (device == nil) {
        NSLog(@"Unable to open device");
    }
    
    
}

@end
