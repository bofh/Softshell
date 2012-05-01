//
//  RTLSDRTuner.m
//  rtl-sdr
//
//  Created by William Dillon on 4/29/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import "RTLSDRTuner.h"
#import "RTLSDRTuner_e4000.h"

@implementation RTLSDRTuner

+ (RTLSDRTuner *)createTunerForDevice:(RTLSDRDevice *)device
{
    
    
    return nil;
}

- (id)initWithDevice:(RTLSDRDevice *)dev
{
    self = [super init];
    if (self) {
        device = dev;
    }
    
    return self;
}

- (double)freq
{
    return freq;
}

- (void)setFreq:(double)freq
{
    [device setI2cRepeater:YES];
    
    NSLog(@"Trying to access the baseclass, this doesn't do anything.");
    // Tuning commands (implement in a subclass)
    
    [device setI2cRepeater:NO];
}

- (NSUInteger)gain
{
    return gain;
}

- (void)setGain:(NSUInteger)newGain
{
    gain = newGain;
    NSLog(@"Trying to access the baseclass, this doesn't do anything.");
}

- (NSUInteger)bandWidth
{
    return bandWidth;
}

- (void)setBandWidth:(NSUInteger)newBandWidth
{
    bandWidth = newBandWidth;
    NSLog(@"Trying to access the baseclass, this doesn't do anything.");
}

@end
