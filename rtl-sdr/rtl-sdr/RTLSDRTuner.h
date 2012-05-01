//
//  RTLSDRTuner.h
//  rtl-sdr
//
//  Created by William Dillon on 4/29/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTLSDRDevice.h"

@interface RTLSDRTuner : NSObject
{
    RTLSDRDevice *device;
    
    double freq;
    
    NSUInteger gain;
    NSUInteger bandWidth;
}

+ (RTLSDRTuner *)createTuner;

- (id)initWithDevice:(RTLSDRDevice *)dev;

@property (readwrite) double freq;
@property (readwrite) NSUInteger gain;
@property (readwrite) NSUInteger bandWidth;

@end
