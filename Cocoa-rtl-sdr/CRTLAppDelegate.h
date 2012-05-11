//
//  CRTLAppDelegate.h
//  Cocoa-rtl-sdr
//
//  Created by William Dillon on 4/29/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <rtl-sdr/RTLSDRDevice.h>

#import "NetworkServer.h"
#import "NetworkSession.h"

@interface CRTLAppDelegate : NSObject <NSApplicationDelegate, NetworkServerDelegate>
{
    RTLSDRDevice *device;

    NetworkServer *server;
    NSMutableArray *sessions;
    
    NSMutableArray *deviceList;
    
    bool running;
}

@property (retain) IBOutlet NSComboBox *deviceComboBox;
@property (retain) IBOutlet NSTextField *tunerTypeField;

@property (retain) IBOutlet NSTextField *portNumberField;
@property (retain) IBOutlet NSButton *networkCheckBox;

@property (retain) IBOutlet NSTextField *centerFreqField;
@property (retain) IBOutlet NSTextField *sampleRateField;

@property (assign) IBOutlet NSWindow *window;

- (IBAction)openDevice:(id)sender;
- (IBAction)networkToggle:(id)sender;
- (IBAction)updateTuner:(id)sender;

- (NSArray *)deviceList;

@end
