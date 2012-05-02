//
//  rtl_sdr.h
//  rtl-sdr
//
//  Created by William Dillon on 4/29/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libusb.h>

@class RTLSDRTuner;

@interface RTLSDRDevice : NSObject
{
    NSUInteger rtlXtal;
    NSUInteger rtlFreq;
    NSUInteger tunerFreq;
    
    NSUInteger centerFreq;
    NSUInteger freqCorrection;
    NSUInteger tunerGain;
    NSUInteger sampleRate;
    
    RTLSDRTuner *tuner;
    
    libusb_context *context;
    libusb_device_handle *devh;
}

+ (NSInteger)deviceCount;
+ (NSArray *)deviceList;

// This initializes an SDR device with an index into the device list
- (id)initWithDeviceIndex:(NSInteger)index;

// These functions have been lifted wholesale from the osmocom rtl-sdr sourcecode
// The actual functions have been changed to match Obj-C style and useage, but the
// functionality should be the same.

/*!
 * Set crystal oscillator frequencies used for the RTL2832 and the tuner IC.
 *
 * Usually both ICs use the same clock. Changing the clock may make sense if
 * you are applying an external clock to the tuner or to compensate the
 * frequency (and samplerate) error caused by the original cheap crystal.
 *
 * NOTE: Call this function only if you know what you are doing.
 *
 * \param rtl_freq frequency value used to clock the RTL2832 in Hz
 * \param tuner_freq frequency value used to clock the tuner IC in Hz
 * \check value for success
 */
@property(readwrite) NSUInteger rtlFreq;
@property(readwrite) NSUInteger tunerFreq;

/*!
 * Get actual frequency the device is tuned to.
 */
@property(readwrite) NSUInteger centerFreq;
@property(readwrite) NSUInteger freqCorrection;
@property(readwrite) NSUInteger tunerGain;

/* this will select the baseband filters according to the requested sample rate */
/*!
 * Get actual sample rate the device is configured to.
 *
 * \param dev the device handle given by rtlsdr_open()
 * \return 0 on error, sample rate in Hz otherwise
 */
@property(readwrite) NSUInteger sampleRate;

/* streaming functions */

// This function starts reading from the device.
// It will call the provided block when the specified number of
// samples are collected.
// The size must be multiples of 512, if zero defaults to 
- (bool)readCount:(NSUInteger)bufferSize withBlock:(dispatch_block_t)block;
- (bool)stopReading;

/*!
 * Read samples from the device asynchronously. This function will block until
 * it is being canceled using rtlsdr_cancel_async()
 *
 * \param dev the device handle given by rtlsdr_open()
 * \param cb callback function to return received samples
 * \param ctx user specific context to pass via the callback function
 * \param buf_num optional buffer count, buf_num * buf_len = overall buffer size
 *		  set to 0 for default buffer count (32)
 * \param buf_len optional buffer length, must be multiple of 512,
 *		  set to 0 for default buffer length (16 * 32 * 512)
 * \return 0 on success
 */
//RTLSDR_API int rtlsdr_read_async(rtlsdr_dev_t *dev,
//                                 rtlsdr_read_async_cb_t cb,
//                                 void *ctx,
//                                 uint32_t buf_num,
//                                 uint32_t buf_len);

/*!
 * Cancel all pending asynchronous operations on the device.
 *
 */
- (void)cancelOperations;

// These methods should only be called from within the library!
- (void)setI2cRepeater:(bool)enabled;

- (uint16_t)readAddress:(uint16_t)addr fromBlock:(uint8_t)block length:(uint8_t)bytes;
- (void)writeValue:(uint16_t)value AtAddress:(uint16_t)addr InBlock:(uint8_t)block Length:(uint8_t)bytes;

- (uint16_t)demodReadAddress:(uint16_t)addr fromPage:(uint8_t)page length:(uint8_t)bytes;
- (void)demodWriteValue:(uint16_t)value AtAddress:(uint16_t)addr InPage:(uint8_t)page Length:(uint8_t)bytes;

- (int)readArray:(uint8_t*)array fromAddress:(uint16_t)addr inBlock:(uint8_t)block length:(uint8_t)len;
- (int)writeArray:(uint8_t *)array toAddress:(uint16_t)addr inBlock:(uint8_t)block length:(uint8_t)len;

- (int)writeI2cRegister:(uint8_t)reg atAddress:(uint8_t)i2c_addr withValue:(uint8_t)val;
- (uint8_t)readI2cRegister:(uint8_t)reg fromAddress:(uint8_t)i2c_addr;

- (int)writeI2cAtAddress:(uint8_t)i2c_addr withBuffer:(uint8_t *)buffer length:(int)len;
- (int)readI2cAtAddress:(uint8_t)i2c_addr withBuffer:(uint8_t *)buffer length:(int)len;

- (void)setGpioBit:(uint8_t)gpio value:(int)value;
- (void)setGpioOutput:(uint8_t)gpio;

@end

