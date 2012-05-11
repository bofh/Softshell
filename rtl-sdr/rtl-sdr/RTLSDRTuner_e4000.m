//
//  RTLSDRTuner_e4000.m
//  rtl-sdr
//
//  Created by William Dillon on 4/30/12.
//  Copyright (c) 2012 Oregon State University (COAS). All rights reserved.
//

#import "RTLSDRTuner_e4000.h"
#import "RTLSDRDevice.h"

#define FUNCTION_ERROR		1
#define FUNCTION_SUCCESS	0
#define NO_USE              0
#define LEN_2_BYTE          2
#define I2C_BUFFER_LEN		128
#define CRYSTAL_FREQ		28800000

@implementation RTLSDRTuner_e4000

/* glue functions to rtl-sdr code */
- (bool)I2CReadByte:(uint8_t *)byte fromRegister:(uint8_t)regAddr
{
	uint8_t data = regAddr;
    
    [device writeI2cAtAddress:E4K_I2C_ADDR withBuffer:&data length:1];
    [device  readI2cAtAddress:E4K_I2C_ADDR withBuffer:&data length:1];
    
	*byte = data;
    
	return YES;
}

- (bool)I2CWriteByte:(uint8_t)byte toRegister:(uint8_t)regAddr
{
	uint8_t data[2];    
	data[0] = regAddr;
	data[1] = byte;
    
    [device writeI2cAtAddress:E4K_I2C_ADDR withBuffer:data length:2];
    
	return YES;
}

- (bool)I2CWriteArray:(uint8_t *)array
               length:(uint8_t)length
            atAddress:(uint8_t)startAddress
{
    // OSMOCOM RTL-SDR DERIVED CODE
	unsigned int i;
	uint8_t WritingBuffer[I2C_BUFFER_LEN];
    
	WritingBuffer[0] = startAddress;
    
	for(i = 0; i < length; i++)
		WritingBuffer[1 + i] = array[i];
    // END OSMOCOM CODE
    
    [device writeI2cAtAddress:E4K_I2C_ADDR
                   withBuffer:WritingBuffer
                       length:length+1];
    
	return YES;
}

- (bool)tunerReset
{    
    // OSMOCOM RTL-SDR DERIVED CODE
//	unsigned char writearray[5];
	bool success;
    
	// For dummy I2C command, don't check executing status.
//         I2CWriteByte(pTuner, NoUse, RegAddr, WritingByte)
//	status=I2CWriteByte(pTuner, 200  , 2      , writearray[0]);
    [self I2CWriteByte:64 toRegister:2];

//	status=I2CWriteByte (pTuner, 200,2,writearray[0]);
    success = [self I2CWriteByte:64 toRegister:2];

    if(!success) return NO;
    
//	writearray[0] = 0;
//	status=I2CWriteByte (pTuner, 200,9,writearray[0]);
    success = [self I2CWriteByte:0 toRegister:9];
    if(!success) return NO;
    
//	writearray[0] = 0;
//	status=I2CWriteByte (pTuner, 200,5,writearray[0]);
    success = [self I2CWriteByte:0 toRegister:5];
    if(!success) return NO;
    
//	writearray[0] = 7;
//	status=I2CWriteByte (pTuner, 200,0,writearray[0]);
    success = [self I2CWriteByte:7 toRegister:0];
    if(!success) return NO;
    
	return YES;
    // END OSMOCOM CODE
}

/****************************************************************************\
 *  Function: Tunerclock
 *
 *  Detailed Description:
 *  The function configures the E4000 clock. (Register 0x06, 0x7a).
 *  Function disables the clock - values can be modified to enable if required.
 \****************************************************************************/

- (bool)tunerClock
{    
//	status=I2CWriteByte(pTuner, 200,6  ,  0);
//	status=I2CWriteByte(pTuner, 200,122,150);
    if([self I2CWriteByte:0   toRegister:6] == NO) return NO;    
    if([self I2CWriteByte:150 toRegister:122] == NO) return NO;
    
	return YES;
}

/****************************************************************************\
 *  Function: Qpeak()
 *
 *  Detailed Description:
 *  The function configures the E4000 gains.
 *  Also sigma delta controller. (Register 0x82).
 *
 \****************************************************************************/

- (bool)qPeak
{
    // OSMOCOM RTL-SDR DERIVED CODE
	unsigned char writearray[5];
    
	writearray[0] = 1;
	writearray[1] = 254;
//	status=I2CWriteArray(pTuner, 200,126,2,writearray);
    if (![self I2CWriteArray:writearray length:2 atAddress:126])
        return NO;
    
    
//	status=I2CWriteByte (pTuner, 200,130,0);
    if (![self I2CWriteByte:0 toRegister:130]) return NO;
    
    
//	status=I2CWriteByte (pTuner, 200,36,5);
    if (![self I2CWriteByte:5 toRegister:36]) return NO;
    
	writearray[0] = 32;
	writearray[1] = 1;
//	status=I2CWriteArray(pTuner, 200,135,2,writearray);
    if (![self I2CWriteArray:writearray length:2 atAddress:135])
        return NO;

	return YES;
}
/****************************************************************************\
 *  Function: E4000_gain_freq()
 *
 *  Detailed Description:
 *  The function configures the E4000 gains vs. freq
 *  0xa3 to 0xa7. Also 0x24.
 *
 \****************************************************************************/
- (bool)gainVsFreq:(int)gainFreq
{
    unsigned char writearray[5];

    // OSMOCOM RTL-SDR DERIVED CODE
	if (gainFreq<=350000)
	{
		writearray[0] = 0x10;
		writearray[1] = 0x42;
		writearray[2] = 0x09;
		writearray[3] = 0x21;
		writearray[4] = 0x94;
	}
	else if(gainFreq>=1000000)
	{
		writearray[0] = 0x10;
		writearray[1] = 0x42;
		writearray[2] = 0x09;
		writearray[3] = 0x21;
		writearray[4] = 0x94;
	}
	else
	{
		writearray[0] = 0x10;
		writearray[1] = 0x42;
		writearray[2] = 0x09;
		writearray[3] = 0x21;
		writearray[4] = 0x94;
	}
    
//	status=I2CWriteArray(pTuner, 200,163,5,writearray);
    if (![self I2CWriteArray:writearray length:5 atAddress:163])
        return NO;    
    
	if (gainFreq<=350000)
	{
		writearray[0] = 94;
		writearray[1] = 6;
//		status=I2CWriteArray(pTuner, 200,159,2,writearray);
        if (![self I2CWriteArray:writearray length:2 atAddress:159])
            return NO;    
        
		writearray[0] = 0;
//		status=I2CWriteArray(pTuner, 200,136,1,writearray);
        if (![self I2CWriteArray:writearray length:1 atAddress:136])
            return NO;
	}
	else
	{
		writearray[0] = 127;
		writearray[1] = 7;
//		status=I2CWriteArray(pTuner, 200,159,2,writearray);
        if (![self I2CWriteArray:writearray length:2 atAddress:159])
            return NO;    
        
		writearray[0] = 1;
//		status=I2CWriteArray(pTuner, 200,136,1,writearray);
        if (![self I2CWriteArray:writearray length:1 atAddress:136])
            return NO;
	}
    
	return YES;
}
/****************************************************************************\
 *  Function: DCoffloop
 *
 *  Detailed Description:
 *  Populates DC offset LUT. (Registers 0x2d, 0x70, 0x71).
 *  Turns on DC offset LUT and time varying DC offset.
 \****************************************************************************/
- (bool)dcOffsetLoop
{
    // OSMOCOM RTL-SDR DERIVED CODE       
	unsigned char writearray[5];
    
//	writearray[0] = 31;
//	status=I2CWriteByte(pTuner, 200,45,writearray[0]);
    if (![self I2CWriteByte:31 toRegister:45]) return NO;
    
	writearray[0] = 1;
	writearray[1] = 1;
//	status=I2CWriteArray(pTuner, 200,112,2,writearray);
    if (![self I2CWriteArray:writearray length:2 atAddress:112])
        return NO;
    
	return YES;
}

/****************************************************************************\
 *  Function: GainControlinit
 *
 *  Detailed Description:
 *  Configures gain control mode. (Registers 0x1d, 0x1e, 0x1f, 0x20, 0x21,
 *  0x1a, 0x74h, 0x75h).
 *  User may wish to modify values depending on usage scenario.
 *  Routine configures LNA: autonomous gain control
 *  IF PWM gain control.
 *  PWM thresholds = default
 *  Mixer: switches when LNA gain =7.5dB
 *  Sensitivity / Linearity mode: manual switch
 *
 \****************************************************************************/
- (bool)gainControlInit
{
    // OSMOCOM RTL-SDR DERIVED CODE
	unsigned char writearray[5];
	unsigned char read1[1];    
	unsigned char sum=255;
    
//	writearray[0] = 23;
//	status=I2CWriteByte(pTuner, 200,26,23);
    if (![self I2CWriteByte:23 toRegister:26]) return NO;


//	status=I2CReadByte(pTuner, 201,27,read1);
    if (![self I2CReadByte:read1 fromRegister:27]) return NO;
    
	writearray[0] = 16;
	writearray[1] = 4;
	writearray[2] = 26;
	writearray[3] = 15;
	writearray[4] = 167;
//	status=I2CWriteArray(pTuner, 200,29,5,writearray);
    if (![self I2CWriteArray:writearray length:5 atAddress:29])
        return NO;
    
//	status=I2CWriteByte(pTuner, 200,134,81);
    if (![self I2CWriteByte:81 toRegister:134]) return NO;
    
	//For Realtek - gain control logic
//	status=I2CReadByte(pTuner, 201,27,read1);
    if (![self I2CReadByte:read1 fromRegister:27]) return NO;
    
	if(read1[0] <= sum)
	{
		sum=read1[0];
	}
    
//	status=I2CWriteByte(pTuner, 200,31,26);
    if (![self I2CWriteByte:26 toRegister:31]) return NO;

//	status=I2CReadByte(pTuner, 201,27,read1);
    if (![self I2CReadByte:read1 fromRegister:27]) return NO;
    
	if(read1[0] <= sum)
	{
		sum=read1[0];
	}
    
//	status=I2CWriteByte(pTuner, 200,31,26);
    if (![self I2CWriteByte:26 toRegister:31]) return NO;
    
//	status=I2CReadByte(pTuner, 201,27,read1);
    if (![self I2CReadByte:read1 fromRegister:27]) return NO;
    
	if(read1[0] <= sum)
	{
		sum=read1[0];
	}
    
    //	status=I2CWriteByte(pTuner, 200,31,26);
    if (![self I2CWriteByte:26 toRegister:31]) return NO;
    
    //	status=I2CReadByte(pTuner, 201,27,read1);
    if (![self I2CReadByte:read1 fromRegister:27]) return NO;
    
    
	if(read1[0] <= sum)
	{
		sum=read1[0];
	}
    
    //	status=I2CWriteByte(pTuner, 200,31,26);
    if (![self I2CWriteByte:26 toRegister:31]) return NO;
    
    //	status=I2CReadByte(pTuner, 201,27,read1);
    if (![self I2CReadByte:read1 fromRegister:27]) return NO;    
    
	if (read1[0]<=sum)
	{
		sum=read1[0];
	}
    
//	status=I2CWriteByte(pTuner, 200,27,sum);
    if (![self I2CWriteByte:sum toRegister:27]) return NO;
    
	return YES;
}

/****************************************************************************
 *  Function: Gainmanual
 *
 *  Detailed Description:
 *  Sets Gain control to serial interface control.
 *
 ****************************************************************************/
- (bool)manualGain
{
    // OSMOCOM RTL-SDR DERIVED CODE
    
//	status=I2CWriteByte(pTuner, 200,26,0);
    if (![self I2CWriteByte:0 toRegister:26]) return NO;
    
//	status=I2CWriteByte (pTuner, 200,9,0);
    if (![self I2CWriteByte:0 toRegister:9]) return NO;
    
//	status=I2CWriteByte (pTuner, 200,5,0);
    if (![self I2CWriteByte:0 toRegister:5]) return NO;
    
	return YES;
}

/****************************************************************************\
 *  Function: GainControlinit
 *
 *  Detailed Description:
 *  Configures gain control mode. (Registers 0x1a)
 *
 \****************************************************************************/
- (bool)gainControlAuto
{    
//	status=I2CWriteByte(pTuner, 200,26,23);
	return [self I2CWriteByte:23 toRegister:26];
}

- (id)initWithDevice:(RTLSDRDevice *)dev
{
    // The device ivar is set in the superclass init
    self = [super initWithDevice:dev];
    if (self) {
        // Initialize tuner.
        NSLog(@"tuner reset");
        if (![self tunerReset]) {
            [self release];
            self = nil;
            return self;
        }

        NSLog(@"tuner clock");
        if (![self tunerClock]) {
            [self release];
            self = nil;
            return self;
        }
        
        NSLog(@"q peak");
        if (![self qPeak]) {
            [self release];
            self = nil;
            return self;
        }

//        if (![self dcOffsetLoop]) {
//            [self release];
//            self = nil;
//            return self;
//        }

        NSLog(@"gain control");
        if (![self gainControlInit]) {
            [self release];
            self = nil;
            return self;
        }
    }
    
    return self;
}


- (NSString *)tunerType
{
    return @"Elonics E4000";
}

/****************************************************************************\
 *  Function: PLL
 *
 *  Detailed Description:
 *  Configures E4000 PLL divider & sigma delta. 0x0d,0x09, 0x0a, 0x0b).
 *
 \****************************************************************************/
- (bool)PLLwithRefClock:(int)refClk freq:(int)Freq
{
    // OSMOCOM RTL-SDR DERIVED CODE
	int VCO_freq;
	unsigned char writearray[5];
    
	unsigned char divider;
	int intVCOfreq;
	int SigDel;
	int SigDel2;
	int SigDel3;
    //	int harmonic_freq;
    //	int offset;
    
	if (Freq<=72400)
	{
		writearray[4] = 15;
		VCO_freq=Freq*48;
	}
	else if (Freq<=81200)
    {
		writearray[4] = 14;
		VCO_freq=Freq*40;
	}
	else if (Freq<=108300)
	{
		writearray[4]=13;
		VCO_freq=Freq*32;
	}
	else if (Freq<=162500)
	{
		writearray[4]=12;
		VCO_freq=Freq*24;
	}
	else if (Freq<=216600)
	{
		writearray[4]=11;
		VCO_freq=Freq*16;
	}
	else if (Freq<=325000)
	{
		writearray[4]=10;
		VCO_freq=Freq*12;
	}
	else if (Freq<=350000)
	{
		writearray[4]=9;
		VCO_freq=Freq*8;
	}
	else if (Freq<=432000)
	{
		writearray[4]=3;
		VCO_freq=Freq*8;
	}
	else if (Freq<=667000)
	{
		writearray[4]=2;
		VCO_freq=Freq*6;
	}
	else if (Freq<=1200000)
	{
		writearray[4]=1;
		VCO_freq=Freq*4;
	}
	else
	{
		writearray[4]=0;
		VCO_freq=Freq*2;
	}
    
	//printf("\nVCOfreq=%d", VCO_freq);
    //	divider =  VCO_freq * 1000 / Ref_clk;
	divider =  VCO_freq / refClk;
	//printf("\ndivider=%d", divider);
	writearray[0]= divider;
    //	intVCOfreq = divider * Ref_clk /1000;
	intVCOfreq = divider * refClk;
	//printf("\ninteger VCO freq=%d", intVCOfreq);
    //	SigDel=65536 * 1000 * (VCO_freq - intVCOfreq) / Ref_clk;
	SigDel=65536 * (VCO_freq - intVCOfreq) / refClk;
	//printf("\nSigma delta=%d", SigDel);
	if (SigDel<=1024)
	{
		SigDel = 1024;
	}
	else if (SigDel>=64512)
	{
		SigDel=64512;
	}
	SigDel2 = SigDel / 256;
	//printf("\nSigdel2=%d", SigDel2);
	writearray[2] = (unsigned char)SigDel2;
	SigDel3 = SigDel - (256 * SigDel2);
	//printf("\nSig del3=%d", SigDel3);
	writearray[1]= (unsigned char)SigDel3;
	writearray[3]=(unsigned char)0;

//	status=I2CWriteArray(pTuner, 200,9,5,writearray);
    if ([self I2CWriteArray:writearray length:5 atAddress:9] == NO)
         return NO;
	
    //printf("\nRegister 9=%d", writearray[0]);
	//printf("\nRegister a=%d", writearray[1]);
	//printf("\nRegister b=%d", writearray[2]);
	//printf("\nRegister d=%d", writearray[4]);
    
	if (Freq<=82900)
	{
		writearray[0]=0;
		writearray[2]=1;
	}
	else if (Freq<=89900)
	{
		writearray[0]=3;
		writearray[2]=9;
	}
	else if (Freq<=111700)
	{
		writearray[0]=0;
		writearray[2]=1;
	}
	else if (Freq<=118700)
	{
		writearray[0]=3;
		writearray[2]=1;
	}
	else if (Freq<=140500)
	{
		writearray[0]=0;
		writearray[2]=3;
	}
	else if (Freq<=147500)
	{
		writearray[0]=3;
		writearray[2]=11;
	}
	else if (Freq<=169300)
	{
		writearray[0]=0;
		writearray[2]=3;
	}
	else if (Freq<=176300)
	{
		writearray[0]=3;
		writearray[2]=11;
	}
	else if (Freq<=198100)
	{
		writearray[0]=0;
		writearray[2]=3;
	}
	else if (Freq<=205100)
	{
		writearray[0]=3;
		writearray[2]=19;
	}
	else if (Freq<=226900)
	{
		writearray[0]=0;
		writearray[2]=3;
	}
	else if (Freq<=233900)
	{
		writearray[0]=3;
		writearray[2]=3;
	}
	else if (Freq<=350000)
	{
		writearray[0]=0;
		writearray[2]=3;
	}
	else if (Freq<=485600)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=493600)
	{
		writearray[0]=3;
		writearray[2]=5;
	}
	else if (Freq<=514400)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=522400)
	{
		writearray[0]=3;
		writearray[2]=5;
	}
	else if (Freq<=543200)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=551200)
	{
		writearray[0]=3;
		writearray[2]=13;
	}
	else if (Freq<=572000)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=580000)
	{
		writearray[0]=3;
		writearray[2]=13;
	}
	else if (Freq<=600800)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=608800)
	{
		writearray[0]=3;
		writearray[2]=13;
	}
	else if (Freq<=629600)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=637600)
	{
		writearray[0]=3;
		writearray[2]=13;
	}
	else if (Freq<=658400)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=666400)
	{
		writearray[0]=3;
		writearray[2]=13;
	}
	else if (Freq<=687200)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=695200)
	{
		writearray[0]=3;
		writearray[2]=13;
	}
	else if (Freq<=716000)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=724000)
	{
		writearray[0]=3;
		writearray[2]=13;
	}
	else if (Freq<=744800)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=752800)
	{
		writearray[0]=3;
		writearray[2]=21;
	}
	else if (Freq<=773600)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=781600)
	{
		writearray[0]=3;
		writearray[2]=21;
	}
	else if (Freq<=802400)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=810400)
	{
		writearray[0]=3;
		writearray[2]=21;
	}
	else if (Freq<=831200)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=839200)
	{
		writearray[0]=3;
		writearray[2]=21;
	}
	else if (Freq<=860000)
	{
		writearray[0]=0;
		writearray[2]=5;
	}
	else if (Freq<=868000)
	{
		writearray[0]=3;
		writearray[2]=21;
	}
	else
	{
		writearray[0]=0;
		writearray[2]=7;
	}
    
//	status=I2CWriteByte (pTuner, 200,7,writearray[2]);
    if (![self I2CWriteByte:writearray[2] toRegister:7]) return NO;
    
//	status=I2CWriteByte (pTuner, 200,5,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:5]) return NO;
    
	return E4000_1_SUCCESS;
}

/****************************************************************************\
 *  Function: LNAfilter
 *
 *  Detailed Description:
 *  The function configures the E4000 LNA filter. (Register 0x10).
 *
 \****************************************************************************/
- (bool)LNAfilter:(int)Freq
{
    // OSMOCOM RTL-SDR DERIVED CODE
	unsigned char writearray[5];
    
	if(Freq<=370000)
	{
		writearray[0]=0;
	}
	else if(Freq<=392500)
	{
		writearray[0]=1;
	}
	else if(Freq<=415000)
	{
		writearray[0] =2;
	}
	else if(Freq<=437500)
	{
		writearray[0]=3;
	}
	else if(Freq<=462500)
	{
		writearray[0]=4;
	}
	else if(Freq<=490000)
	{
		writearray[0]=5;
	}
	else if(Freq<=522500)
	{
		writearray[0]=6;
	}
	else if(Freq<=557500)
	{
		writearray[0]=7;
	}
	else if(Freq<=595000)
	{
		writearray[0]=8;
	}
	else if(Freq<=642500)
	{
		writearray[0]=9;
	}
	else if(Freq<=695000)
	{
		writearray[0]=10;
	}
	else if(Freq<=740000)
	{
		writearray[0]=11;
	}
	else if(Freq<=800000)
	{
		writearray[0]=12;
	}
	else if(Freq<=865000)
	{
		writearray[0] =13;
	}
	else if(Freq<=930000)
	{
		writearray[0]=14;
	}
	else if(Freq<=1000000)
	{
		writearray[0]=15;
	}
	else if(Freq<=1310000)
	{
		writearray[0]=0;
	}
	else if(Freq<=1340000)
	{
		writearray[0]=1;
	}
	else if(Freq<=1385000)
	{
		writearray[0]=2;
	}
	else if(Freq<=1427500)
	{
		writearray[0]=3;
	}
	else if(Freq<=1452500)
	{
		writearray[0]=4;
	}
	else if(Freq<=1475000)
	{
		writearray[0]=5;
	}
	else if(Freq<=1510000)
	{
		writearray[0]=6;
	}
	else if(Freq<=1545000)
	{
		writearray[0]=7;
	}
	else if(Freq<=1575000)
	{
		writearray[0] =8;
	}
	else if(Freq<=1615000)
	{
		writearray[0]=9;
	}
	else if(Freq<=1650000)
	{
		writearray[0] =10;
	}
	else if(Freq<=1670000)
	{
		writearray[0]=11;
	}
	else if(Freq<=1690000)
	{
		writearray[0]=12;
	}
	else if(Freq<=1710000)
	{
		writearray[0]=13;
	}
	else if(Freq<=1735000)
	{
		writearray[0]=14;
	}
	else
	{
		writearray[0]=15;
	}
    
//	status=I2CWriteByte (pTuner, 200,16,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:16]) return NO;
    
	return E4000_1_SUCCESS;
}
/****************************************************************************\
 *  Function: IFfilter
 *
 *  Detailed Description:
 *  The function configures the E4000 IF filter. (Register 0x11,0x12).
 *
 \****************************************************************************/
- (bool)IFfilterBandwidth:(int)bandwidth refClock:(int)Ref_clk
{
    // OSMOCOM RTL-SDR DERIVED CODE
	unsigned char writearray[5];
    
	int IF_BW;
    
	IF_BW = bandwidth / 2;
	if(IF_BW<=2150)
	{
		writearray[0]=253;
		writearray[1]=31;
	}
	else if(IF_BW<=2200)
	{
		writearray[0]=253;
		writearray[1]=30;
	}
	else if(IF_BW<=2240)
	{
		writearray[0]=252;
		writearray[1]=29;
	}
	else if(IF_BW<=2280)
	{
		writearray[0]=252;
		writearray[1]=28;
	}
	else if(IF_BW<=2300)
	{
		writearray[0]=252;
		writearray[1]=27;
	}
	else if(IF_BW<=2400)
	{
		writearray[0]=252;
		writearray[1]=26;
	}
	else if(IF_BW<=2450)
	{
		writearray[0]=252;
		writearray[1]=25;
	}
	else if(IF_BW<=2500)
	{
		writearray[0]=252;
		writearray[1]=24;
	}
	else if(IF_BW<=2550)
	{
		writearray[0]=252;
		writearray[1]=23;
	}
	else if(IF_BW<=2600)
	{
		writearray[0]=252;
		writearray[1]=22;
	}
	else if(IF_BW<=2700)
	{
		writearray[0]=252;
		writearray[1]=21;
	}
	else if(IF_BW<=2750)
	{
		writearray[0]=252;
		writearray[1]=20;
	}
	else if(IF_BW<=2800)
	{
		writearray[0]=252;
		writearray[1]=19;
	}
	else if(IF_BW<=2900)
	{
		writearray[0]=251;
		writearray[1]=18;
	}
	else if(IF_BW<=2950)
	{
		writearray[0]=251;
		writearray[1]=17;
	}
	else if(IF_BW<=3000)
	{
		writearray[0]=251;
		writearray[1]=16;
	}
	else if(IF_BW<=3100)
	{
		writearray[0]=251;
		writearray[1]=15;
	}
	else if(IF_BW<=3200)
	{
		writearray[0]=250;
		writearray[1]=14;
	}
	else if(IF_BW<=3300)
	{
		writearray[0]=250;
		writearray[1]=13;
	}
	else if(IF_BW<=3400)
	{
		writearray[0]=249;
		writearray[1]=12;
	}
	else if(IF_BW<=3600)
	{
		writearray[0]=249;
		writearray[1]=11;
	}
	else if(IF_BW<=3700)
	{
		writearray[0]=249;
		writearray[1]=10;
	}
	else if(IF_BW<=3800)
	{
		writearray[0]=248;
		writearray[1]=9;
	}
	else if(IF_BW<=3900)
	{
		writearray[0]=248;
		writearray[1]=8;
	}
	else if(IF_BW<=4100)
	{
		writearray[0]=248;
		writearray[1]=7;
	}
	else if(IF_BW<=4300)
	{
		writearray[0]=247;
		writearray[1]=6;
	}
	else if(IF_BW<=4400)
	{
		writearray[0]=247;
		writearray[1]=5;
	}
	else if(IF_BW<=4600)
	{
		writearray[0]=247;
		writearray[1]=4;
	}
	else if(IF_BW<=4800)
	{
		writearray[0]=246;
		writearray[1]=3;
	}
	else if(IF_BW<=5000)
	{
		writearray[0]=246;
		writearray[1]=2;
	}
	else if(IF_BW<=5300)
	{
		writearray[0]=245;
		writearray[1]=1;
	}
	else if(IF_BW<=5500)
	{
		writearray[0]=245;
		writearray[1]=0;
	}
	else
	{
		writearray[0]=0;
		writearray[1]=32;
	}
    
//	status=I2CWriteArray(pTuner, 200,17,2,writearray);
    if (![self I2CWriteArray:writearray length:2 atAddress:17])
        return NO;

	return YES;
}
/****************************************************************************\
 *  Function: freqband
 *
 *  Detailed Description:
 *  Configures the E4000 frequency band. (Registers 0x07, 0x78).
 *
 \****************************************************************************/
- (bool)bandForFreq:(int)Freq
{
    // OSMOCOM RTL-SDR DERIVED CODE
	if (Freq<=140000)
	{
//		status=I2CWriteByte(pTuner, 200,120,3);
        if (![self I2CWriteByte:3 toRegister:120]) return NO;
	}
	else if (Freq<=350000)
	{
//		status=I2CWriteByte(pTuner, 200,120,3);
        if (![self I2CWriteByte:3 toRegister:120]) return NO;
	}
	else if (Freq<=1000000)
	{
//		status=I2CWriteByte(pTuner, 200,120,3);
        if (![self I2CWriteByte:3 toRegister:120]) return NO;
	}
	else
	{
//		status=I2CWriteByte(pTuner, 200,7,7);
        if (![self I2CWriteByte:7 toRegister:7]) return NO;
        
//		status=I2CWriteByte(pTuner, 200,120,0);
        if (![self I2CWriteByte:0 toRegister:120]) return NO;
	}
    
	return E4000_1_SUCCESS;
}

/****************************************************************************\
 *  Function: DCoffLUT
 *
 *  Detailed Description:
 *  Populates DC offset LUT. (Registers 0x50 - 0x53, 0x60 - 0x63).
 *
 \****************************************************************************/
- (bool)DCoffsetLUT
{
    // OSMOCOM RTL-SDR DERIVED CODE
	unsigned char writearray[5];
    
	unsigned char read1[1];
	unsigned char IOFF;
	unsigned char QOFF;
	unsigned char RANGE1;
    //	unsigned char RANGE2;
	unsigned char QRANGE;
	unsigned char IRANGE;
	writearray[0] = 0;
	writearray[1] = 126;
	writearray[2] = 36;

//	status=I2CWriteArray(pTuner, 200,21,3,writearray);
    if (![self I2CWriteArray:writearray length:3 atAddress:21])
        return NO;
    
	// Sets mixer & IF stage 1 gain = 00 and IF stg 2+ to max gain.
//	status=I2CWriteByte(pTuner, 200,41,1);
    if (![self I2CWriteByte:1 toRegister:41]) return NO;

	// Instructs a DC offset calibration.
//	status=I2CReadByte(pTuner, 201,42,read1);
    if (![self I2CReadByte:read1 fromRegister:42]) return NO;
	IOFF=read1[0];

//	status=I2CReadByte(pTuner, 201,43,read1);
    if (![self I2CReadByte:read1 fromRegister:43]) return NO;
	QOFF=read1[0];

//	status=I2CReadByte(pTuner, 201,44,read1);
    if (![self I2CReadByte:read1 fromRegister:44]) return NO;
	RANGE1=read1[0];

	//reads DC offset values back
	if(RANGE1>=32)
	{
		RANGE1 = RANGE1 -32;
	}
	if(RANGE1>=16)
	{
		RANGE1 = RANGE1 - 16;
	}
	IRANGE=RANGE1;
	QRANGE = (read1[0] - RANGE1) / 16;
    
	writearray[0] = (IRANGE * 64) + IOFF;
//	status=I2CWriteByte(pTuner, 200,96,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:96]) return NO;
    
	writearray[0] = (QRANGE * 64) + QOFF;
//	status=I2CWriteByte(pTuner, 200,80,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:80]) return NO;
    
	// Populate DC offset LUT
	writearray[0] = 0;
	writearray[1] = 127;
//	status=I2CWriteArray(pTuner, 200,21,2,writearray);
    if (![self I2CWriteArray:writearray length:2 atAddress:21])
        return NO;
    
	// Sets mixer & IF stage 1 gain = 01 leaving IF stg 2+ at max gain.
//	status=I2CWriteByte(pTuner, 200,41,1);
    if (![self I2CWriteByte:1 toRegister:41]) return NO;
    
	// Instructs a DC offset calibration.
//	status=I2CReadByte(pTuner, 201,42,read1);
    if (![self I2CReadByte:read1 fromRegister:42]) return NO;
	IOFF=read1[0];

	
//    status=I2CReadByte(pTuner, 201,43,read1);
    if (![self I2CReadByte:read1 fromRegister:43]) return NO;
	QOFF=read1[0];

//	status=I2CReadByte(pTuner, 201,44,read1);
    if (![self I2CReadByte:read1 fromRegister:44]) return NO;
	RANGE1=read1[0];

	// Read DC offset values
	if(RANGE1>=32)
	{
		RANGE1 = RANGE1 -32;
	}
	if(RANGE1>=16)
    {
		RANGE1 = RANGE1 - 16;
	}
	IRANGE = RANGE1;
	QRANGE = (read1[0] - RANGE1) / 16;
    
	writearray[0] = (IRANGE * 64) + IOFF;
//	status=I2CWriteByte(pTuner, 200,97,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:97]) return NO;
    
	writearray[0] = (QRANGE * 64) + QOFF;
//	status=I2CWriteByte(pTuner, 200,81,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:81]) return NO;
    
	// Populate DC offset LUT
//	status=I2CWriteByte(pTuner, 200,21,1);
    if (![self I2CWriteByte:1 toRegister:21]) return NO;
    
	// Sets mixer & IF stage 1 gain = 11 leaving IF stg 2+ at max gain.
//	status=I2CWriteByte(pTuner, 200,41,1);
    if (![self I2CWriteByte:1 toRegister:41]) return NO;
    
	// Instructs a DC offset calibration.
//	status=I2CReadByte(pTuner, 201,42,read1);
    if (![self I2CReadByte:read1 fromRegister:42]) return NO;
	IOFF=read1[0];

//	status=I2CReadByte(pTuner, 201,43,read1);
    if (![self I2CReadByte:read1 fromRegister:43]) return NO;    
	QOFF=read1[0];
	
//  status=I2CReadByte(pTuner, 201,44,read1);
    if (![self I2CReadByte:read1 fromRegister:44]) return NO;    
	RANGE1 = read1[0];

	// Read DC offset values
	if(RANGE1>=32)
	{
		RANGE1 = RANGE1 -32;
	}
	if(RANGE1>=16)
	{
		RANGE1 = RANGE1 - 16;
	}
	IRANGE = RANGE1;
	QRANGE = (read1[0] - RANGE1) / 16;
	writearray[0] = (IRANGE * 64) + IOFF;
//	status=I2CWriteByte(pTuner, 200,99,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:99]) return NO;
    
	writearray[0] = (QRANGE * 64) + QOFF;
//	status=I2CWriteByte(pTuner, 200,83,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:83]) return NO;
    
	// Populate DC offset LUT
//	status=I2CWriteByte(pTuner, 200,22,126);
    if (![self I2CWriteByte:126 toRegister:22]) return NO;
    
	// Sets mixer & IF stage 1 gain = 11 leaving IF stg 2+ at max gain.
//	status=I2CWriteByte(pTuner, 200,41,1);
    if (![self I2CWriteByte:1 toRegister:41]) return NO;
    
	// Instructs a DC offset calibration.
//	status=I2CReadByte(pTuner, 201,42,read1);
    if (![self I2CReadByte:read1 fromRegister:42]) return NO;    
	IOFF=read1[0];
    
//	status=I2CReadByte(pTuner, 201,43,read1);
    if (![self I2CReadByte:read1 fromRegister:43]) return NO;    
	QOFF=read1[0];
    
//	status=I2CReadByte(pTuner, 201,44,read1);
    if (![self I2CReadByte:read1 fromRegister:44]) return NO;    
	RANGE1=read1[0];
    
	// Read DC offset values
	if(RANGE1>=32)
	{
		RANGE1 = RANGE1 -32;
	}
	if(RANGE1>=16)
	{
		RANGE1 = RANGE1 - 16;
	}
	IRANGE = RANGE1;
	QRANGE = (read1[0] - RANGE1) / 16;
    
	writearray[0]=(IRANGE * 64) + IOFF;
//	status=I2CWriteByte(pTuner, 200,98,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:98]) return NO;
    
	writearray[0] = (QRANGE * 64) + QOFF;
//	status=I2CWriteByte(pTuner, 200,82,writearray[0]);
    if (![self I2CWriteByte:writearray[0] toRegister:82]) return NO;
    
	return YES;
}

- (double)setFreq:(double)freqIn
{
    [device setI2cRepeater:YES];

    NSLog(@"Set frequency to %f", freqIn);
    // OSMOCOM RTL-SDR DERIVED CODE
	// Set tuner RF frequency in KHz.
	// Note: 1. RfFreqKhz = round(RfFreqHz / 1000)
	//          CrystalFreqKhz = round(CrystalFreqHz / 1000)
	//       2. Call E4000 source code functions.
	double RfFreqKhz      = (freqIn + 500.) / 1000.;
	double CrystalFreqKhz = (xtal + 500.) / 1000.;
    
    RfFreqKhz = floor(RfFreqKhz);
    CrystalFreqKhz = floor(CrystalFreqKhz);
    
    if (![self manualGain]) {
        return freq;
    }
    
    if (![self gainVsFreq:RfFreqKhz]) {
        return freq;
    }
    
    if (![self PLLwithRefClock:CrystalFreqKhz freq:RfFreqKhz])
        return NO;
    
    if (![self LNAfilter:RfFreqKhz]) {
        return freq;
    }

    if (![self bandForFreq:RfFreqKhz] ) {
        return freq;
    }
    
    if (![self DCoffsetLUT]) {
        return freq;
    }
    
    if (![self gainControlAuto]) {
        return freq;
    }

    freq = RfFreqKhz * 1000.;
    
    [device setI2cRepeater:NO];

    return freq;
}

- (void)setBandWidth:(NSUInteger)newBandwidth
{
    NSLog(@"Setting bandwidth: %ld", newBandwidth);
    // OSMOCOM RTL-SDR DERIVED CODE
    //	E4000_EXTRA_MODULE *pExtra;
    
	int BandwidthKhz;
	int CrystalFreqKhz;
    
	NSInteger CrystalFreqHz = [device tunerClock];
    
	// Get tuner extra module.
    //	pExtra = &(pTuner->Extra.E4000);    
    
	// Set tuner bandwidth Hz.
	// Note: 1. BandwidthKhz = round(BandwidthHz / 1000)
	//          CrystalFreqKhz = round(CrystalFreqHz / 1000)
	//       2. Call E4000 source code functions.
	BandwidthKhz   = (int)((newBandwidth + 500) / 1000);
	CrystalFreqKhz = (int)((CrystalFreqHz + 500) / 1000);
    
    if ([self IFfilterBandwidth:BandwidthKhz refClock:CrystalFreqKhz])
        bandWidth = BandwidthKhz * 1000;
        
//	return bandWidth;
}

- (void)setGain:(NSUInteger)gain
{
    
}

@end
