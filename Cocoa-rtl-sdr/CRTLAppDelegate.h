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

    NSArray *deviceList;
    IBOutlet NSComboBox *deviceComboBox;
}

@property (retain) IBOutlet NSComboBox *deviceComboBox;

@property (assign) IBOutlet NSWindow *window;
@property (readonly) NSArray *deviceList;

- (IBAction)openDevice:(id)sender;

@end
