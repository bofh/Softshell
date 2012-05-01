//
//  rtl_sdr.m
//  rtl-sdr
//
//  Created by William Dillon on 4/29/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import "RTLSDRDevice.h"
#import "RTLSDRTuner.h"

// OSMOCOM RTL-SDR DERIVED CODE
#define DEFAULT_BUF_NUMBER	32
#define DEFAULT_BUF_LENGTH	(16 * 32 * 512)

#define DEF_RTL_XTAL_FREQ	28800000
#define MIN_RTL_XTAL_FREQ	(DEF_RTL_XTAL_FREQ - 1000)
#define MAX_RTL_XTAL_FREQ	(DEF_RTL_XTAL_FREQ + 1000)

#define MAX_SAMP_RATE		3200000

#define CTRL_IN		(LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_ENDPOINT_IN)
#define CTRL_OUT	(LIBUSB_REQUEST_TYPE_VENDOR | LIBUSB_ENDPOINT_OUT)
#define CTRL_TIMEOUT	300
#define BULK_TIMEOUT	0

typedef struct rtlsdr_dongle {
	uint16_t vid;
	uint16_t pid;
	const char *name;
} rtlsdr_dongle_t;

/*
 * Please add your device here and send a patch to osmocom-sdr@lists.osmocom.org
 */
static rtlsdr_dongle_t known_devices[] = {
	{ 0x0bda, 0x2832, "Generic RTL2832U (e.g. hama nano)" },
	{ 0x0bda, 0x2838, "ezcap USB 2.0 DVB-T/DAB/FM dongle" },
	{ 0x0ccd, 0x00a9, "Terratec Cinergy T Stick Black (rev 1)" },
	{ 0x0ccd, 0x00b3, "Terratec NOXON DAB/DAB+ USB dongle (rev 1)" },
	{ 0x0ccd, 0x00d3, "Terratec Cinergy T Stick RC (Rev.3)" },
	{ 0x0ccd, 0x00d7, "Terratec T Stick PLUS" },
	{ 0x0ccd, 0x00e0, "Terratec NOXON DAB/DAB+ USB dongle (rev 2)" },
	{ 0x185b, 0x0620, "Compro Videomate U620F"},
	{ 0x185b, 0x0650, "Compro Videomate U650F"},
	{ 0x1f4d, 0xb803, "GTek T803" },
	{ 0x1f4d, 0xc803, "Lifeview LV5TDeluxe" },
	{ 0x1b80, 0xd3a4, "Twintech UT-40" },
	{ 0x1d19, 0x1101, "Dexatek DK DVB-T Dongle (Logilink VG0002A)" },
	{ 0x1d19, 0x1102, "Dexatek DK DVB-T Dongle (MSI DigiVox mini II V3.0)" },
	{ 0x1d19, 0x1103, "Dexatek Technology Ltd. DK 5217 DVB-T Dongle" },
	{ 0x0458, 0x707f, "Genius TVGo DVB-T03 USB dongle (Ver. B)" },
	{ 0x1b80, 0xd393, "GIGABYTE GT-U7300" },
	{ 0x1b80, 0xd394, "DIKOM USB-DVBT HD" },
	{ 0x1b80, 0xd395, "Peak 102569AGPK" },
	{ 0x1b80, 0xd39d, "SVEON STV20 DVB-T USB & FM" },
};

enum usb_reg {
	USB_SYSCTL		= 0x2000,
	USB_CTRL		= 0x2010,
	USB_STAT		= 0x2014,
	USB_EPA_CFG		= 0x2144,
	USB_EPA_CTL		= 0x2148,
	USB_EPA_MAXPKT		= 0x2158,
	USB_EPA_MAXPKT_2	= 0x215a,
	USB_EPA_FIFO_CFG	= 0x2160,
};

enum sys_reg {
	DEMOD_CTL		= 0x3000,
	GPO			= 0x3001,
	GPI			= 0x3002,
	GPOE			= 0x3003,
	GPD			= 0x3004,
	SYSINTE			= 0x3005,
	SYSINTS			= 0x3006,
	GP_CFG0			= 0x3007,
	GP_CFG1			= 0x3008,
	SYSINTE_1		= 0x3009,
	SYSINTS_1		= 0x300a,
	DEMOD_CTL_1		= 0x300b,
	IR_SUSPEND		= 0x300c,
};

enum blocks {
	DEMODB			= 0,
	USBB			= 1,
	SYSB			= 2,
	TUNB			= 3,
	ROMB			= 4,
	IRB			= 5,
	IICB			= 6,
};

// END OSMOCOM CODE

static NSArray *deviceList;
static dispatch_once_t onceToken;

@implementation RTLSDRDevice

#pragma mark -
#pragma mark Device searching and enumeration

+(const char *)findKnownDeviceVendorID:(uint16_t)vid
                              DeviceID:(uint16_t)did
{
    unsigned int i;
    int nDevices = sizeof(known_devices)/sizeof(rtlsdr_dongle_t);

    for (i = 0; i < nDevices; i++ ) {
        if (known_devices[i].vid == vid &&
            known_devices[i].pid == did) {
            return known_devices[i].name;
        }
    }
    
    return nil;
}

+(NSInteger)deviceCount
{
    return [[RTLSDRDevice deviceList] count];    
}

+(NSArray *)deviceList
{
    // Devices are only enumerated once!
    dispatch_once(&onceToken, ^{
        NSMutableArray *tempDeviceList = [[NSMutableArray alloc] init];
        
        int i;
        libusb_context *ctx;
        libusb_device **list;
        struct libusb_device_descriptor dd;
        
        ssize_t cnt;
        
        libusb_init(&ctx);
        
        cnt = libusb_get_device_list(ctx, &list);
        
        for (i = 0; i < cnt; i++) {
            libusb_get_device_descriptor(list[i], &dd);
            
            const char *name = [self findKnownDeviceVendorID:dd.idVendor
                                                    DeviceID:dd.idProduct];
            if (name) {
                [tempDeviceList addObject:[NSString stringWithCString:name
                                                             encoding:NSUTF8StringEncoding]];
            }
        }
        
        libusb_free_device_list(list, 0);
        
        libusb_exit(ctx);
                
        deviceList = [tempDeviceList copy];
        [tempDeviceList release];
    });
    
    return deviceList;
}


#pragma mark -
#pragma mark Register read/write methods
- (uint16_t)readAddress:(uint16_t)addr
              fromBlock:(uint8_t)block
                 length:(uint8_t)bytes
//uint16_t rtlsdr_read_reg(rtlsdr_dev_t *dev, uint8_t block, uint16_t addr, uint8_t len)
{
    // OSMOCOM RTL-SDR DERIVED CODE
	int r;
	unsigned char data[2];
	uint16_t index = (block << 8);
	uint16_t reg;
    
	r = libusb_control_transfer(devh, CTRL_IN, 0,
                                addr, index, data, bytes,
                                CTRL_TIMEOUT);
    
	if (r < 0)
		NSLog(@"%s failed with %d\n", __FUNCTION__, r);
    
	reg = (data[1] << 8) | data[0];
    
	return reg;
}

- (void)writeValue:(uint16_t)value
         AtAddress:(uint16_t)addr
           InBlock:(uint8_t)block
            Length:(uint8_t)bytes;
//void rtlsdr_write_reg(rtlsdr_dev_t *dev, uint8_t block, uint16_t addr, uint16_t val, uint8_t len)
{
	int r;
	unsigned char data[2];
    
	uint16_t index = (block << 8) | 0x10;
    
	if (bytes == 1)
		data[0] = bytes & 0xff;
	else
		data[0] = bytes >> 8;
    
	data[1] = bytes & 0xff;
    
	r = libusb_control_transfer(devh, CTRL_OUT, 0, addr, index, data, bytes, CTRL_TIMEOUT);
    
	if (r < 0)
		NSLog(@"%s failed with %d\n", __FUNCTION__, r);
}

- (uint16_t)demodReadAddress:(uint16_t)addr
                    fromPage:(uint8_t)page
                      length:(uint8_t)bytes
{
    // OSMOCOM RTL-SDR DERIVED CODE
	int r;
	unsigned char data[2];
    
	uint16_t index = page;
	uint16_t reg;
	addr = (addr << 8) | 0x20;
    
	r = libusb_control_transfer(devh, CTRL_IN, 0,
                                addr, index, data, bytes,
                                CTRL_TIMEOUT);
    
	if (r < 0)
		fprintf(stderr, "%s failed with %d\n", __FUNCTION__, r);
    
	reg = (data[1] << 8) | data[0];
    
	return reg;
    // END OSMOCOM CODE
}

- (void)demodWriteValue:(uint16_t)value
              AtAddress:(uint16_t)addr
                 InPage:(uint8_t)page
                 Length:(uint8_t)bytes;

{
    // OSMOCOM RTL-SDR DERIVED CODE
	int r;
	unsigned char data[2];
	uint16_t index = 0x10 | page;
	addr = (addr << 8) | 0x20;
    
	if (bytes == 1)
		data[0] = value & 0xff;
	else
		data[0] = value >> 8;
    
	data[1] = value & 0xff;
    
	r = libusb_control_transfer(devh, CTRL_OUT, 0,
                                addr, index, data, bytes,
                                CTRL_TIMEOUT);
    
	if (r < 0)
		fprintf(stderr, "%s failed with %d\n", __FUNCTION__, r);
    
    [self demodReadAddress:0x01
                  fromPage:0x0a
                    length:1];
    // END OSMOCOM CODE
}

- (void)setI2cRepeater:(bool)enabled
{
    // OSMOCOM RTL-SDR DERIVED CODE
    if (enabled) {
        [self demodWriteValue:0x18 AtAddress:0x01 InPage:1 Length:1];
        //        rtlsdr_demod_write_reg(dev, 1, 0x01, on ? 0x18 : 0x10, 1);
    } else {
        [self demodWriteValue:0x10 AtAddress:0x01 InPage:1 Length:1];
        //        rtlsdr_demod_write_reg(dev, 1, 0x01, on ? 0x18 : 0x10, 1);
    }
    // END OSMOCOM CODE
}

- (int)readArray:(uint8_t*)array fromAddress:(uint16_t)addr inBlock:(uint8_t)block length:(uint8_t)len
{
    // OSMOCOM RTL-SDR DERIVED CODE
	int r;
	uint16_t index = (block << 8);
    
	r = libusb_control_transfer(devh, CTRL_IN, 0, addr, index, array, len, CTRL_TIMEOUT);
    
	return r;
    // END OSMOCOM CODE
}

- (int)writeArray:(uint8_t *)array toAddress:(uint16_t)addr inBlock:(uint8_t)block length:(uint8_t)len
{
    // OSMOCOM RTL-SDR DERIVED CODE
	int r;
	uint16_t index = (block << 8) | 0x10;
    
	r = libusb_control_transfer(devh, CTRL_OUT, 0, addr, index, array, len, CTRL_TIMEOUT);
    
	return r;
    // END OSMOCOM CODE
}

- (int)writeI2cRegister:(uint8_t)reg atAddress:(uint8_t)i2c_addr withValue:(uint8_t)val
{
    // OSMOCOM RTL-SDR DERIVED CODE
	uint16_t addr = i2c_addr;
	uint8_t data[2];
    
	data[0] = reg;
	data[1] = val;

    //	return rtlsdr_write_array(dev, IICB, addr, (uint8_t *)&data, 2);
    return [self writeArray:(uint8_t *)&data toAddress:addr inBlock:IICB length:2];
    // END OSMOCOM CODE
}

- (uint8_t)readI2cRegister:(uint8_t)reg fromAddress:(uint8_t)i2c_addr
{
	uint16_t addr = i2c_addr;
	uint8_t data;
    
//	rtlsdr_write_array(dev, IICB, addr, &reg, 1);
    [self writeArray:&reg toAddress:addr inBlock:IICB length:1];
//	rtlsdr_read_array(dev, IICB, addr, &data, 1);
    [self readArray:&data fromAddress:addr inBlock:IICB length:1];
    
	return data;
}

- (int)writeI2cAtAddress:(uint8_t)i2c_addr withBuffer:(uint8_t *)buffer length:(int)len
{
	uint16_t addr = i2c_addr;

    return [self writeArray:buffer toAddress:addr inBlock:IICB length:len];
}

- (int)readI2cAtAddress:(uint8_t)i2c_addr withBuffer:(uint8_t *)buffer length:(int)len
{
	uint16_t addr = i2c_addr;

    return [self readArray:buffer fromAddress:addr inBlock:IICB length:len];
}

#pragma mark -
#pragma mark Class initialization/deallocation
- (void)initBaseband
{
    // OSMOCOM RTL-SDR DERIVED CODE
    unsigned int i;
    
	/* default FIR coefficients used for DAB/FM by the Windows driver,
	 * the DVB driver uses different ones */
	uint8_t fir_coeff[] = {
		0xca, 0xdc, 0xd7, 0xd8, 0xe0, 0xf2, 0x0e, 0x35, 0x06, 0x50,
		0x9c, 0x0d, 0x71, 0x11, 0x14, 0x71, 0x74, 0x19, 0x41, 0xa5,
	};
    
	/* initialize USB */
//  rtlsdr_write_reg(dev, block,  addr,     val, len);
//	rtlsdr_write_reg(dev, USBB, USB_SYSCTL, 0x09, 1);
    [self writeValue:0x09 AtAddress:USB_SYSCTL InBlock:USBB Length:1];
    
//	rtlsdr_write_reg(dev, USBB, USB_EPA_MAXPKT, 0x0002, 2);
    [self writeValue:0x0002 AtAddress:USB_EPA_MAXPKT InBlock:2 Length:2];
//	rtlsdr_write_reg(dev, USBB, USB_EPA_CTL, 0x1002, 2);
    [self writeValue:0x1002 AtAddress:USB_EPA_CTL InBlock:2 Length:2];
    
	/* poweron demod */
//	rtlsdr_write_reg(dev, SYSB, DEMOD_CTL_1, 0x22, 1);
    [self writeValue:0x22 AtAddress:DEMOD_CTL_1 InBlock:SYSB Length:1];
//	rtlsdr_write_reg(dev, SYSB, DEMOD_CTL, 0xe8, 1);
    [self writeValue:0xe8 AtAddress:DEMOD_CTL InBlock:SYSB Length:1];
    
	/* reset demod (bit 3, soft_rst) */
//	rtlsdr_demod_write_reg(dev, 1, 0x01, 0x14, 1);
    [self writeValue:0x14 AtAddress:0x01 InBlock:1 Length:1];
//	rtlsdr_demod_write_reg(dev, 1, 0x01, 0x10, 1);
    [self writeValue:0x10 AtAddress:0x01 InBlock:1 Length:1];
    
	/* disable spectrum inversion and adjacent channel rejection */
//	rtlsdr_demod_write_reg(dev, 1, 0x15, 0x00, 1);
    [self writeValue:0x00   AtAddress:0x15 InBlock:1 Length:1];
//	rtlsdr_demod_write_reg(dev, 1, 0x16, 0x0000, 2);
    [self writeValue:0x0000 AtAddress:0x16 InBlock:1 Length:2];
    
	/* set IF-frequency to 0 Hz */
//	rtlsdr_demod_write_reg(dev, 1, 0x19, 0x0000, 2);
    [self writeValue:0x0000 AtAddress:0x19 InBlock:1 Length:2];
    
	/* set FIR coefficients */
	for (i = 0; i < sizeof (fir_coeff); i++) {
//		rtlsdr_demod_write_reg(dev, 1, 0x1c + i, fir_coeff[i], 1);
        [self writeValue:fir_coeff[i] AtAddress:0x1c InBlock:1 Length:1];
    }
    
//	rtlsdr_demod_write_reg(dev, 0, 0x19, 0x25, 1);
    [self writeValue:0x25 AtAddress:0x19 InBlock:0 Length:1];

	/* init FSM state-holding register */
//	rtlsdr_demod_write_reg(dev, 1, 0x93, 0xf0, 1);
    [self writeValue:0xf0 AtAddress:0x93 InBlock:1 Length:1];
    
	/* disable AGC (en_dagc, bit 0) */
//	rtlsdr_demod_write_reg(dev, 1, 0x11, 0x00, 1);
    [self writeValue:0x00 AtAddress:0x11 InBlock:1 Length:1];
    
	/* disable PID filter (enable_PID = 0) */
//	rtlsdr_demod_write_reg(dev, 0, 0x61, 0x60, 1);
    [self writeValue:0x60 AtAddress:0x61 InBlock:0 Length:1];
    
	/* opt_adc_iq = 0, default ADC_I/ADC_Q datapath */
//	rtlsdr_demod_write_reg(dev, 0, 0x06, 0x80, 1);
    [self writeValue:0x80 AtAddress:0x06 InBlock:0 Length:1];
    
	/* Enable Zero-IF mode (en_bbin bit), DC cancellation (en_dc_est),
	 * IQ estimation/compensation (en_iq_comp, en_iq_est) */
//	rtlsdr_demod_write_reg(dev, 1, 0xb1, 0x1b, 1);
    [self writeValue:0x1b AtAddress:0xb1 InBlock:1 Length:1];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)initWithDeviceIndex:(NSInteger)index
{
    self = [super init];
    if (self) {
        // OSMOCOM RTL-SDR DERIVED CODE
        int r;
        int i;
        libusb_device **list;
        libusb_device *device = NULL;
        uint32_t device_count = 0;
        struct libusb_device_descriptor dd;
        uint8_t reg;
        ssize_t cnt;
        
        libusb_init(&context);
        
        cnt = libusb_get_device_list(context, &list);
        
        for (i = 0; i < cnt; i++) {
            device = list[i];
            
            libusb_get_device_descriptor(list[i], &dd);
            
            if ([RTLSDRDevice findKnownDeviceVendorID:dd.idVendor
                                             DeviceID:dd.idProduct])
            {
                device_count++;
            }
            
            if (index == device_count - 1)
                break;
            
            device = NULL;
        }
        
        if (!device) {
            goto err;
        }
        
        r = libusb_open(device, &devh);
        libusb_free_device_list(list, 0);

        if (r < 0) {
            NSLog(@"Unable to open device (usb_open)");
            goto err;
        }
        
        r = libusb_claim_interface(devh, 0);
        if (r < 0) {
            NSLog(@"usb_claim_interface error %d\n", r);
            goto err;
        }
        
        rtlXtal = DEF_RTL_XTAL_FREQ;
        
        [self initBaseband];
        
        /* Probe tuners */
        [self setI2cRepeater:YES];

//      reg = rtlsdr_i2c_read_reg(dev, E4K_I2C_ADDR, E4K_CHECK_ADDR);
        reg = [self readI2cRegister:E4K_CHECK_ADDR fromAddress:E4K_I2C_ADDR];
        if (reg == E4K_CHECK_VAL) {
            fprintf(stderr, "Found Elonics E4000 tuner\n");
            dev->tuner = &tuners[RTLSDR_TUNER_E4000];
            goto found;
        }
        
        reg = rtlsdr_i2c_read_reg(dev, FC0013_I2C_ADDR, FC0013_CHECK_ADDR);
        if (reg == FC0013_CHECK_VAL) {
            fprintf(stderr, "Found Fitipower FC0013 tuner\n");
            dev->tuner = &tuners[RTLSDR_TUNER_FC0013];
            goto found;
        }
        
        /* initialise GPIOs */
        rtlsdr_set_gpio_output(dev, 5);
        
        /* reset tuner before probing */
        rtlsdr_set_gpio_bit(dev, 5, 1);
        rtlsdr_set_gpio_bit(dev, 5, 0);
        
        reg = rtlsdr_i2c_read_reg(dev, FC2580_I2C_ADDR, FC2580_CHECK_ADDR);
        if ((reg & 0x7f) == FC2580_CHECK_VAL) {
            fprintf(stderr, "Found FCI 2580 tuner\n");
            dev->tuner = &tuners[RTLSDR_TUNER_FC2580];
            goto found;
        }
        
        reg = rtlsdr_i2c_read_reg(dev, FC0012_I2C_ADDR, FC0012_CHECK_ADDR);
        if (reg == FC0012_CHECK_VAL) {
            fprintf(stderr, "Found Fitipower FC0012 tuner\n");
            rtlsdr_set_gpio_output(dev, 6);
            dev->tuner = &tuners[RTLSDR_TUNER_FC0012];
            goto found;
        }
        
    found:
        if (dev->tuner) {
            dev->tun_xtal = dev->rtl_xtal;
            
            if (dev->tuner->init)
                r = dev->tuner->init(dev);
        }
        
        rtlsdr_set_i2c_repeater(dev, 0);
        
        *out_dev = dev;
        
        return 0;
    err:
        if (dev) {
            if (dev->ctx)
                libusb_exit(dev->ctx);
            
            free(dev);
        }
        
        return r;
    }
    
    return nil;
}

#pragma mark -
#pragma mark Getters and Setters
// Sample rate getting/setting
-(NSUInteger)sampleRate
{
    return sampleRate;
}

-(void)setSampleRate:(NSUInteger)newSampleRate
{
    // OSMOCOM RTL-SDR DERIVED CODE
    uint16_t tmp;
	uint32_t rsamp_ratio;
	double real_rate;
        
	/* check for the maximum rate the resampler supports */
	if (newSampleRate > MAX_SAMP_RATE)
		newSampleRate = MAX_SAMP_RATE;
    
	rsamp_ratio = (rtlXtal * pow(2, 22)) / newSampleRate;
	rsamp_ratio &= ~3;
    
	real_rate = (rtlXtal * pow(2, 22)) / rsamp_ratio;
    
	if ( ((double)sampleRate) != real_rate )
		fprintf(stderr, "Exact sample rate is: %f Hz\n", real_rate);
    
    [tuner setBandWidth:real_rate];
    
	sampleRate = newSampleRate;
    
	tmp = (rsamp_ratio >> 16);
    [self demodWriteValue:tmp AtAddress:0x9f InPage:1 Length:2];
//	rtlsdr_demod_write_reg(dev, 1, 0x9f, tmp, 2);

	tmp = rsamp_ratio & 0xffff;
    [self demodWriteValue:tmp AtAddress:0xa1 InPage:1 Length:2];
//  rtlsdr_demod_write_reg(dev, 1, 0xa1, tmp, 2);
    
	/* reset demod (bit 3, soft_rst) */
    [self demodWriteValue:0x14 AtAddress:0x9f InPage:1 Length:1];
//	rtlsdr_demod_write_reg(dev, 1, 0x01, 0x14, 1);

    [self demodWriteValue:0x10 AtAddress:0x01 InPage:1 Length:1];
//	rtlsdr_demod_write_reg(dev, 1, 0x01, 0x10, 1);    
    // END OSMOCOM CODE
}

- (void)setCenterFreq:(NSUInteger)freq
{
    double f = (double)freq * (1.0 + freqCorrection / 1e6);
    [tuner setFreq:f];
}

- (NSUInteger)centerFreq
{
    return [tuner freq];
}

-(void)setFreqCorrection:(NSUInteger)newFreqCorrection
{
	if (freqCorrection == newFreqCorrection)
		return;
    
    freqCorrection = newFreqCorrection;
    
	/* retune to apply new correction value */
    [self setCenterFreq:centerFreq];
    
	return;
}

-(NSUInteger)freqCorrection
{
	return freqCorrection;
}

-(void)setTunerGain:(NSUInteger)newTunerGain
{
    [tuner setGain:newTunerGain];
}

-(NSUInteger)tunerGain
{
    return [tuner gain];
}

//int rtlsdr_set_xtal_freq(rtlsdr_dev_t *dev, uint32_t rtl_freq, uint32_t tuner_freq)

- (NSUInteger)rtlFreq
{
    return rtlFreq;
}

- (void)setRtlFreq:(NSUInteger)newRtlFreq
{
    // OSMOCOM RTL-SDR DERIVED CODE
	if (newRtlFreq < MIN_RTL_XTAL_FREQ ||
        newRtlFreq > MAX_RTL_XTAL_FREQ)
		return;
    
	if (rtlXtal != rtlFreq) {
		rtlXtal  = rtlFreq;
        
		if (rtlXtal == 0)
			rtlXtal = DEF_RTL_XTAL_FREQ;
        
		/* update xtal-dependent settings */
        [self setSampleRate:sampleRate];
	}
    
    // END OSMOCOM CODE
}

- (NSUInteger)tunerFreq
{
    return tunerFreq;
}

// This is probably horribly wrong
- (void)setTunerFreq:(NSUInteger)newTunerFreq
{
    // OSMOCOM RTL-SDR DERIVED CODE
	if (newTunerFreq != tunerFreq) {
        
		tunerFreq = newTunerFreq;
        
		if (tunerFreq == 0)
			tunerFreq = rtlXtal;
        
		/* update xtal-dependent settings */
        [tuner setFreq:[tuner freq]];
	}
    
    // END OSMOCOM CODE
}

@end
