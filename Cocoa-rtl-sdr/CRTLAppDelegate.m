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
@synthesize networkCheckBox;
@synthesize portNumberField;
@synthesize tunerTypeField;

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
    
    sessions = [[NSMutableArray alloc] init];
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
            [device setSampleRate:2048000];
            [device setCenterFreq:152000000];
        }
    }
        
    [networkCheckBox setEnabled:YES];
}
    
- (IBAction)networkToggle:(id)sender
{
    // Network start enabled
    if ([networkCheckBox state] == NSOnState) {
        // If the server hasn't been allocated, create it
        if (server == nil) {
            server = [[OSUNetServer alloc] init];
            [server setDelegate:self];
        }
        
        // If the server is allocated, just start it.
        [server setPort:[portNumberField intValue]];
        NSError *error;
        [server start:&error];

        // Print errors
        if (error) {
            NSLog(@"Error starting server: %@", [error localizedDescription]);
            [networkCheckBox setState:NSOffState];
            return;
        }
        
        // Start reading from the USB device
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            [device resetEndpoints];
            running = YES;
            // While the running variable remains YES, collect samples
            do {
                // Perform the read 
                NSData *inputData = [device readSychronousLength:4096];
                const uint8_t *inputSamples = [inputData bytes];
                
                NSMutableData *outputData = [[NSMutableData alloc] initWithLength:sizeof(float) * 4096];
                float *outputSamples = [outputData mutableBytes];
                
                // Convert the samples from bytes to floats between -1 and 1
                for (int i = 0; i < 4096; i++) {
                    outputSamples[i] = (float)(inputSamples[i] - 127) / 128;
                }
                
                // Get a stable copy of the sessions
                NSArray *tempSessions;
                @synchronized(sessions) {
                    tempSessions = [sessions copy];
                }
                
                // Send the data to every session (asynch)
                for (OSUNetSession *session in tempSessions) {
                    [session sendData:outputData];
                }
                
                [outputData release];
                [tempSessions release];
                
            } while (running);
        });
    }
    
    // Network stop requested
    else {
        // Stop reading from the USB
        running = NO;
        
        // Stop the sessions
        [sessions removeAllObjects];
        // Stop the server
        [server stop];
    }    
}

#pragma mark -
#pragma mark Delegate Methods
- (void)OSUNetServer:(OSUNetServer *)server newSession:(OSUNetSession *)session
{
    NSLog(@"Accepted a new session.");
    [sessions addObject:session];
}

- (void)OSUNetServerPublished:(OSUNetServer *)server
{
    return;
}

         
@end
