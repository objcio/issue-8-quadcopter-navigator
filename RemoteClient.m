//
// Created by chris on 06.01.14.
//

#import "RemoteClient.h"

@import MultipeerConnectivity;
@import CoreLocation;

@interface RemoteClient () <MCNearbyServiceBrowserDelegate, MCSessionDelegate>

@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;

@end

@implementation RemoteClient

- (void)startBrowsing
{
    MCPeerID* peerId = [[MCPeerID alloc] initWithDisplayName:@"Drone"];

    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:peerId serviceType:@"loc-broadcaster"];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];

    self.session = [[MCSession alloc] initWithPeer:peerId];
    self.session.delegate = self;
}


- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:1];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error;
{
}


- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
}


- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSNumber* latitude = result[@"latitude"];
        NSNumber* longitude = result[@"longitude"];

        if ([latitude isKindOfClass:[NSNumber class]] && [longitude isKindOfClass:[NSNumber class]]) {
            CLLocation* location = [[CLLocation alloc] initWithLatitude:latitude.doubleValue longitude:longitude.doubleValue];
            [self.delegate remoteClient:self didReceiveTargetLocation:location];
        }

        if (result[@"stop"]) {
            [self.delegate remoteClientDidReceiveLandCommand:self];
        }
        if (result[@"takeoff"]) {
            [self.delegate remoteClientDidReceiveTakeOffCommand:self];
        }
        if (result[@"reset"]) {
            [self.delegate remoteClientDidReceiveResetCommand:self];
        };
    }];

}

@end
