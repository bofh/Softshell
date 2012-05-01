//
//  RTLSDRTuner_e4000.h
//  rtl-sdr
//
//  Created by William Dillon on 4/30/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import "RTLSDRTuner.h"

// Definition (implemeted for E4000)
#define E4000_1_SUCCESS			1
#define E4000_1_FAIL			0
#define E4000_I2C_SUCCESS		1
#define E4000_I2C_FAIL			0

#define E4K_I2C_ADDR		0xc8
#define E4K_CHECK_ADDR		0x02
#define E4K_CHECK_VAL		0x40

@interface RTLSDRTuner_e4000 : RTLSDRTuner

@end
