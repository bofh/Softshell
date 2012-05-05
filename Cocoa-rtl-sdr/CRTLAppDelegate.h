//
//  CRTLAppDelegate.h
//  Cocoa-rtl-sdr
//
//  Created by William Dillon on 4/29/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <rtl-sdr/RTLSDRDevice.h>

@interface CRTLAppDelegate : NSObject <NSApplicationDelegate>
{
    RTLSDRDevice *device;

    NSMutableArray *deviceList;
    IBOutlet NSComboBox *deviceComboBox;
    IBOutlet NSTextField *tunerTypeField;
}

@property (retain) IBOutlet NSComboBox *deviceComboBox;

@property (assign) IBOutlet NSWindow *window;

- (IBAction)openDevice:(id)sender;

- (NSArray *)deviceList;

@end
