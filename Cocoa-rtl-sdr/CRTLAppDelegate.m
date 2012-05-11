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
@synthesize tunerTypeField;

@synthesize networkCheckBox;
@synthesize portNumberField;

@synthesize centerFreqField;
@synthesize sampleRateField;

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
    // Disable signals for broken pipe (they're handled during the send call)
	struct sigaction act;		
	if( sigaction(SIGPIPE, NULL, &act) == -1)
		perror("Couldn't find the old handler for SIGPIPE");
	else if (act.sa_handler == SIG_DFL) {
		act.sa_handler = SIG_IGN;
		if( sigaction(SIGPIPE, &act, NULL) == -1)
			perror("Could not ignore SIGPIPE");
	}

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

            // Set the initial frequencies from the text fields
            [device setSampleRate:[[self centerFreqField] intValue]];
            [device setCenterFreq:[[self sampleRateField] intValue]];
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
            server = [[NetworkServer alloc] init];
            [server setDelegate:self];
        }
        
        [server openWithPort:[portNumberField intValue]];
        [server acceptInBackground];
        
        // Start reading from the USB device
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            [device resetEndpoints];
            running = YES;
            // While the running variable remains YES, collect samples
            do {
                @autoreleasepool {
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
                    for (NetworkSession *session in tempSessions) {
                        [session sendData:outputData];
                    }
                    
                    [outputData release];
                    [tempSessions release];
                }                
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
        [server close];
    }    
}

-(IBAction)updateTuner:(id)sender
{
    [device setCenterFreq:[[self sampleRateField] intValue]];
    [device setSampleRate:[[self centerFreqField] intValue]];
}

#pragma mark -
#pragma mark Delegate Methods

#pragma mark -
#pragma mark NetworkServer Delegate Methods
- (void)NetworkServer:(NetworkServer *)theServer
           newSession:(NetworkSession *)newSession
{
	NSLog(@"Accepted new session.");
	
    [newSession retain];
    [newSession setDelegate:self];

    @synchronized(sessions) {
        [sessions addObject:newSession];
    }
}

#pragma mark -
#pragma mark NetworkSession Delegate Methods
- (void)sessionTerminated:(NetworkSession *)session
{
    NSLog(@"Removed a session.");

    @synchronized(sessions) {
        [sessions removeObject:session];
    }
}

@end
