//
//  MultipeerConnectivity.m
//  ARKit
//
//  Created by Mac on 2018/6/5.
//  Copyright © 2018年 AR. All rights reserved.
//

#import "MultipeerConnectivity.h"

@interface MultipeerConnectivity ()<MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

@end

@implementation MultipeerConnectivity

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        NSString *serviceType = @"ar-multi-sample";
        
        self.myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
        
        self.session = [[MCSession alloc] initWithPeer:self.myPeerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        self.session.delegate = self;
        
        self.serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerID discoveryInfo:nil serviceType:serviceType];
        self.serviceAdvertiser.delegate = self;
        [self.serviceAdvertiser startAdvertisingPeer];
        
        self.serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.myPeerID serviceType:serviceType];
        self.serviceBrowser.delegate = self;
        [self.serviceBrowser startBrowsingForPeers];
    }
    
    return self;
}
//广播给所有人
- (void)sendToAllPeers:(NSData *)data
{
  BOOL succseful = [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:nil];
    if (succseful) {
        NSLog(@"广播成功");
    }else{
        NSLog(@"广播失败");
    }
}

//获取同时连接的对象
- (NSArray<MCPeerID *> *)connectedPeers
{
    return self.session.connectedPeers;
}

#pragma mark MCSessionDelegate
// Remote peer changed state.远程对象连接状态
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    
}

// Received data from remote peer. 从远程获取数据
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
     [self.delegate receivedDataHandler:data PeerID:peerID];
}

// Received a byte stream from remote peer. 从远程获取了第一个数据流
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"This service does not send/receive streams.");
}

// Start receiving a resource from remote peer.
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"This service does not send/receive resources.");
}

//完成从远程对等体接收资源并保存内容
//在一个临时位置-应用程序负责移动文件
//到它的沙盒内的永久位置。
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(nullable NSURL *)localURL withError:(nullable NSError *)error
{
    NSLog(@"This service does not send/receive resources.");
}

#pragma mark MCNearbyServiceBrowserDelegate
// Found a nearby advertising peer. 找到了附近的广告同行
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info
{
    // Invite the new peer to the session. 邀请新的对等体加入会话。
    [browser invitePeer:peerID toSession:self.session withContext:nil timeout:10];
}

// A nearby peer has stopped advertising.附近的同行停止了广告宣传。
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    //This app doesn't do anything with non-invited peers, so there's nothing to do here.
   // 这个应用程序对未被邀请的同龄人没有任何作用，所以这里没什么可做的。
}

#pragma mark MCNearbyServiceAdvertiserDelegate
// Incoming invitation request.  Call the invitationHandler block with YES
// and a valid session to connect the inviting peer to the session.
//
//输入邀请请求。用“Yes”调用邀请处理程序块
//以及将邀请对等体连接到会话的有效会话。
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(nullable NSData *)context invitationHandler:(void (^)(BOOL accept, MCSession * __nullable session))invitationHandler
{
    // Call handler to accept invitation and join the session.
    invitationHandler(true, self.session);
}

@end
