//
//  DatagramSocket.m
//  ARDrone
//
//  Created by Daniel Eggert on 29/12/2013.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "DatagramSocket.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>



static NSString * errorString(void)
{
    int e = errno;
    return [NSString stringWithFormat:@"%s (%d)", strerror(e), e];
}



@interface DatagramSocketSendOperation : NSOperation

+ (instancetype)operationWithData:(NSData *)data datagramSocket:(DatagramSocket *)datagramSocket;

@property (nonatomic, copy) NSData *data;
@property (nonatomic, strong) DatagramSocket *datagramSocket;

@end



@interface DatagramSocket ()

@property (nonatomic, copy) NSString *address;
@property (nonatomic) int port;
@property (nonatomic) struct sockaddr_in sin_other;
@property (nonatomic) int nativeSocket;
@property (readonly, nonatomic) BOOL hasValidSocket;
@property (readonly, nonatomic, strong) NSOperationQueue *sendQueue;
@property (readonly, nonatomic, strong) dispatch_queue_t readEventQueue;
@property (readonly, nonatomic, strong) dispatch_source_t readEventSource;
@property (nonatomic, weak) id<DatagramSocketReceiveDelegate> receiveDelegate;
@property (nonatomic, strong) NSOperationQueue *receiveQueue;

@end



@implementation DatagramSocket

+ (instancetype)ipv4socketWithAddress:(NSString *)address port:(int)port error:(NSError **)error;
{
    return [self ipv4socketWithAddress:address port:port receiveDelegate:nil receiveQueue:nil error:error];
}

+ (instancetype)ipv4socketWithAddress:(NSString *)address port:(int)port receiveDelegate:(id<DatagramSocketReceiveDelegate>)receiveDelegate receiveQueue:(NSOperationQueue *)receiveQueue error:(NSError **)error;
{
    DatagramSocket *socket = [[DatagramSocket alloc] init];
    socket.address = address;
    socket.port = port;
    socket.receiveDelegate = receiveDelegate;
    socket.receiveQueue = receiveQueue;
    if (! [socket configureIPv4WithError:error]) {
        return nil;
    }
    return socket;
}

- (id)init
{
    self = [super init];
    if (self) {
        _sendQueue = [[NSOperationQueue alloc] init];
        self.sendQueue.maxConcurrentOperationCount = 1;
        
        NSString *name = [NSString stringWithFormat:@"DatagramSocket-receive-%@-%d", self.address, self.port];
        _readEventQueue = dispatch_queue_create([name UTF8String], 0);
    }
    return self;
}

- (BOOL)configureIPv4WithError:(NSError **)error;
{
    self.sendQueue.name = [NSString stringWithFormat:@"DatagramSocket-send-%@-%d", self.address, self.port];
    
    struct sockaddr_in sin_me = {};
    sin_me.sin_len = (__uint8_t) sizeof(sin);
    sin_me.sin_family = AF_INET;
    sin_me.sin_port = htons(0);
    sin_me.sin_addr.s_addr = htonl(INADDR_ANY);
    
    struct sockaddr_in sin_other = {};
    sin_other.sin_len = (__uint8_t) sizeof(sin_other);
    sin_other.sin_family = AF_INET;
    sin_other.sin_port = htons(self.port);
    
    if (1 != inet_aton([self.address UTF8String], &sin_other.sin_addr)) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"DatagramSocket" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Address format is invalid", @"")}];
        }
        return NO;
    }
    self.sin_other = sin_other;
    
    self.nativeSocket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    int result = bind(self.nativeSocket, (struct sockaddr *) &sin_me, sizeof(sin_me));
    if (result != 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"bind() failed", @"")}];
        }
        return NO;
    }
    result = connect(self.nativeSocket, (struct sockaddr *) &sin_other, sizeof(sin_other));
    if (result != 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"connect() failed", @"")}];
        }
        return NO;
    }
    
    if (self.receiveDelegate != nil) {
        [self createReadSource];
    }
    
    return YES;
}

- (void)createReadSource
{
    _readEventSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, self.nativeSocket, 0, self.readEventQueue);
    __weak DatagramSocket *weakSelf = self;
    dispatch_source_set_event_handler(self.readEventSource, ^{
        [weakSelf socketHasBytesAvailable];
    });
    dispatch_resume(self.readEventSource);
}


// Object allocation ensures that _nativeSocket is 0. We shift it such that the nativeSocket is then -1 after allocation. That way we can safely check if it was set since file descriptors are non-negative.

@synthesize nativeSocket = _nativeSocket;
- (void)setNativeSocket:(int)nativeSocket;
{
    _nativeSocket = nativeSocket + 1;
}

- (int)nativeSocket
{
    return _nativeSocket - 1;
}

- (BOOL)hasValidSocket;
{
    return (0 <= self.nativeSocket);
}

- (void)dealloc;
{
    if ([self hasValidSocket]) {
        close(self.nativeSocket);
    }
}

- (void)socketHasBytesAvailable;
{
    struct sockaddr_in sin_other = self.sin_other;
    socklen_t length = sizeof(sin_other);
    NSMutableData *data  = [NSMutableData dataWithLength:65535];
    ssize_t count = recvfrom(self.nativeSocket, [data mutableBytes], [data length], 0, (struct sockaddr *) &sin_other, &length);
    if (count < 0) {
        NSLog(@"recvfrom() failed: %@", errorString());
    } else {
        [data setLength:count];
        [self.receiveQueue addOperationWithBlock:^{
            [self.receiveDelegate datagramSocket:self didReceiveData:data];
        }];
    }
}

- (void)asynchronouslySendData:(NSData *)data;
{
    [self.sendQueue addOperation:[DatagramSocketSendOperation operationWithData:data datagramSocket:self]];
}

- (void)synchronouslySendData:(NSData *)data;
{
    if (! self.hasValidSocket) {
        NSLog(@"Tried to send data, but there's no native socket.");
    }
    ssize_t const result = sendto(self.nativeSocket, [data bytes], data.length, 0, NULL, 0);
    if (result < 0) {
        NSLog(@"sendto() failed: %@", errorString());
    } else if (result != data.length) {
        NSLog(@"sendto() failed to send all bytes. Sent %ld of %lu bytes.", result, (unsigned long) data.length);
    }
}

@end



@implementation DatagramSocketSendOperation : NSOperation

+ (instancetype)operationWithData:(NSData *)data datagramSocket:(DatagramSocket *)datagramSocket;
{
    DatagramSocketSendOperation *op = [[self alloc] init];
    op.data = data;
    op.datagramSocket = datagramSocket;
    return op;
}

- (void)main
{
    [self.datagramSocket synchronouslySendData:self.data];
}

@end
