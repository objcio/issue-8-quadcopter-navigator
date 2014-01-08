//
// Created by chris on 06.01.14.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

@class RemoteClient;

@protocol RemoteClientDelegate <NSObject>

- (void)remoteClient:(RemoteClient *)client didReceiveTargetLocation:(CLLocation *)location;
- (void)remoteClientDidReceiveResetCommand:(RemoteClient *)client;
- (void)remoteClientDidReceiveTakeOffCommand:(RemoteClient *)client;
- (void)remoteClientDidReceiveLandCommand:(RemoteClient *)client;
@end


@interface RemoteClient : NSObject

@property (nonatomic,weak) id<RemoteClientDelegate> delegate;

- (void)startBrowsing;
@end
