//
//  NetworkSession.m
//  TCP-audio-OSX
//
//  Created by William Dillon on 11/3/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "NetworkSession.h"

@implementation NetworkSession

- (id)initWithHost:(NSString*)inHostName Port:(int)inPort
{
	self = [super init];
	
	if( self != nil ) {		
		hp = gethostbyname( [inHostName UTF8String] );
		if( hp == nil ) {
			perror( "Looking up host address" );
			goto error;
		}
		
		sock = socket( AF_INET, SOCK_STREAM, 0 );
		if( sock == -1 ) {
			perror( "Opening Socket" );
			goto error;
		}
		
		memcpy((char *)&server.sin_addr, hp->h_addr_list[0], hp->h_length);
		server.sin_port = htons((short)inPort);
		server.sin_family = AF_INET;
        
		written = read =  0;
		fileDescriptor = -1;
        
        hostname = [inHostName retain];
	} 
    
	return self;
	
error:
	perror("Creating socket for Network Session");
	self = nil;
	return self;
}

- (id)initWithSocket:(int)socket andDescriptor:(int)fd
{
	self = [super init];
	
	if( self != nil ) {		
		written = read =  0;
		sock = socket;
		fileDescriptor = fd;
		connected = true;
        hostname = nil;
	}
	
	return self;
	
error:
	perror("Creating socket for Network Session");
	self = nil;
	return self;	
}

- (bool)connect
{
	int retval;
	
	while( ((retval = connect( sock, (struct sockaddr *)&server, sizeof(server))) == -1)
          && (errno == EINTR) )
		;
	
	if( retval == -1 ) {
		perror("Unable to connect");
		connected = NO;
	} else {
		
		// When the remote connection is closed, we DO NOT want a SIGPIPE: ask for a EPIPE instead.
		int opt_yes = 1;
		setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, &opt_yes, sizeof(opt_yes));
		
		connected = YES;
		fileDescriptor = sock;
	}
    
	return connected;
}

- (void)disconnect
{
	close(fileDescriptor);
	sock = -1;
	fileDescriptor = -1;
	connected = NO;
}

- (bool)sendData:(NSData*)theData
{
	ssize_t retval;
	NSInteger localWritten = 0;
	NSInteger dataLength;
    
    [theData retain];
    const void *bytes = [theData bytes];
    dataLength  = [theData length];
	
	if( !connected ) {
		if( ![self connect] ) {
			perror("Unable to send, not connected and unable to connect");
            [theData release];
			return NO;
		}
	}
	
    
	do {
        // Send the remaining data
        // We send the data plus the offest of data alread sent (starting at 0)
        // And the length of the remaining data to be sent (starting with total)
		retval = send(fileDescriptor,
                      bytes + localWritten,
                      dataLength - localWritten, 0);

		// Evaluate recoverable errors
        if (retval < 0) {
            if (errno != EINTR  &&
                errno != EAGAIN &&
                errno != ENOBUFS) {
                NSLog(@"Unrecoverable error sending data to session %s", strerror(errno));
                [theData release];
                return NO;
            }
            
            // This error indicates a transient condition, so let's wait
            // for some small period instead of thrashing. (.001 seconds)
            if (errno == ENOBUFS) {
                NSLog(@"Network send ran out of buffers, retrying.");
                usleep(1000);
            }
        }
		
		localWritten += retval;
		
	} while( localWritten < dataLength );

	[theData release];
	return YES;
}

- (size_t)send:(int)length bytes:(void *)data
{
	if( !connected ) {
		if( ![self connect] ) {
			perror("Unable to send, not connected and unable to connect");
			return NO;
		}
	}
	
	ssize_t retval;
    retval = send( fileDescriptor, data, length, 0 );
    if( retval < 0 ) {
		perror("Writing data");
		if( errno == EPIPE ) {
			[delegate sessionTerminated:self];
		}
	}
	
	return retval;
}

- (NSData*)getData
{
	if( !connected ) {
		if( ![self connect] ) {
			perror("Unable to receive, not connected and unable to connect");
			return nil;
		}
	}	
	
	return nil;
}

- (size_t)bytesWritten
{
	return written;
}

- (size_t)bytesRead
{
	return read;
}

- (NSString *)hostname
{
	NSString *retval = [hostname copy];
    [retval autorelease];
    
    return retval;
}

- (void)setHostname:(NSString *)newHostname
{
    if (hostname != nil) {
        [hostname release];
    }
    
	hostname = newHostname;
    [hostname retain];
}

- (void)setDelegate:(id)del
{
	delegate = del;
}

@end
