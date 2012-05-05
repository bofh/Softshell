//
//  RTLSDRTuner.m
//  rtl-sdr
//
//  Created by William Dillon on 4/29/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import "RTLSDRDevice.h"
#import "RTLSDRTuner.h"
#import "RTLSDRTuner_e4000.h"
#import "RTLSDRTuner_fc0012.h"
#import "RTLSDRTuner_fc0013.h"
#import "RTLSDRTuner_fc2580.h"

@implementation RTLSDRTuner

@synthesize xtal;

+ (RTLSDRTuner *)createTunerForDevice:(RTLSDRDevice *)device
{
    RTLSDRTuner *tuner = nil;
    uint8_t reg;

    [device setI2cRepeater:YES];

//  reg = rtlsdr_i2c_read_reg(dev, E4K_I2C_ADDR, E4K_CHECK_ADDR);
    reg = [device readI2cRegister:E4K_CHECK_ADDR fromAddress:E4K_I2C_ADDR];
    if (reg == E4K_CHECK_VAL) {
        fprintf(stderr, "Found Elonics E4000 tuner\n");
        tuner = [[RTLSDRTuner_e4000 alloc] initWithDevice:device];
        
        [device setI2cRepeater:NO];
        return tuner;
    }
    
//  reg = rtlsdr_i2c_read_reg(dev, FC0013_I2C_ADDR, FC0013_CHECK_ADDR);
    reg = [device readI2cRegister:FC0013_CHECK_ADDR fromAddress:FC0013_I2C_ADDR];
    if (reg == FC0013_CHECK_VAL) {
        fprintf(stderr, "Found Fitipower FC0013 tuner\n");
        tuner = [[RTLSDRTuner_fc0012 alloc] initWithDevice:device];
        
        [device setI2cRepeater:NO];
        return tuner;
    }
    
    /* initialise GPIOs */
//  rtlsdr_set_gpio_output(dev, 5);
    [device setGpioOutput:5];
    
    /* reset tuner before probing */
//  rtlsdr_set_gpio_bit(dev, 5, 1);
    [device setGpioBit:5 value:1];

//  rtlsdr_set_gpio_bit(dev, 5, 0);
    [device setGpioBit:5 value:0];
    
//  reg = rtlsdr_i2c_read_reg(dev, FC2580_I2C_ADDR, FC2580_CHECK_ADDR);
    reg = [device readI2cRegister:FC2580_CHECK_ADDR fromAddress:FC2580_I2C_ADDR];

    if ((reg & 0x7f) == FC2580_CHECK_VAL) {
        fprintf(stderr, "Found FCI 2580 tuner\n");
        tuner = [[RTLSDRTuner_fc2580 alloc] initWithDevice:device];
        
        [device setI2cRepeater:NO];
        return tuner;
    }
    
//  reg = rtlsdr_i2c_read_reg(dev, FC0012_I2C_ADDR, FC0012_CHECK_ADDR);
    reg = [device readI2cRegister:FC0012_CHECK_ADDR fromAddress:FC0012_I2C_ADDR];
    if (reg == FC0012_CHECK_VAL) {
        fprintf(stderr, "Found Fitipower FC0012 tuner\n");
        [device setGpioOutput:0];
        
        [device setI2cRepeater:NO];
        return tuner;
    }

    [device setI2cRepeater:NO];
    
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

- (NSString *)tunerType
{
    return @"Baseclass!";
}

- (double)freq
{
    return freq;
}

- (double)setFreq:(double)freq
{
    [device setI2cRepeater:YES];
    
    NSLog(@"Trying to access the baseclass, this doesn't do anything.");
    // Tuning commands (implement in a subclass)
    
    [device setI2cRepeater:NO];
    
    return 0.;
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
