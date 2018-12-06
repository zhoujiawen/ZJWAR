//
//  ViewController.m
//  ARKit研究
//
//  Created by Apple on 2018/11/27.
//  Copyright © 2018年 zhoujiawen. All rights reserved.
//

#import "ViewController.h"

#define kBitsPerComponent (8)
#define kBitsPerPixel (32)
#define kPixelChannelCount (4)//每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit


@interface ViewController ()<MultipeerConnectivityDelegate,ARSCNViewDelegate, ARSessionDelegate>

@property (nonatomic,strong) UIView *sessionInfoView;
@property (nonatomic,strong) UILabel *sessionInfoLabel;
@property (nonatomic,strong) ARSCNView *sceneView;
@property (nonatomic,strong) UIButton *sendMapButton;
@property (nonatomic,strong) UILabel *mappingStatusLabel;

@property (nonatomic,strong) MultipeerConnectivity *multipeerSession;
@property (nonatomic,strong) MCPeerID *mapProvider;
@property (nonatomic,strong) UIImageView *videoView;

@property (nonatomic,strong) RPBroadcastController *broadcastController;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.multipeerSession = [[MultipeerConnectivity alloc] init];
    self.multipeerSession.delegate = self;
    
    //1.创建AR视图
    self.sceneView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
    self.sceneView.delegate = self;
    [self.view addSubview:self.sceneView];
    UITapGestureRecognizer *tapSceneView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSceneTap:)];
    [self.sceneView addGestureRecognizer:tapSceneView];
    
    [self createSubView];
}

//会话运行
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (!ARWorldTrackingConfiguration.isSupported) {
        NSLog(@"ARKit is not available on this device");
        return;
    }
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    [self.sceneView.session runWithConfiguration:configuration];
    self.sceneView.session.delegate = self;

    
    
    
    
}
//页面消失会话停止
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.sceneView.session pause];
}

#pragma mark --------------------------------- Multiuser shared session (多人会话分享)
//场景点击
-(void)handleSceneTap:(UITapGestureRecognizer *)sender{
    ARHitTestResult *hitTestResult = [[self.sceneView hitTest:[sender locationInView:self.sceneView] types:ARHitTestResultTypeExistingPlaneUsingGeometry|ARHitTestResultTypeEstimatedHorizontalPlane] firstObject];
    if (hitTestResult) {
    }else{
        return;
    }
    ARAnchor *anchor = [[ARAnchor alloc] initWithName:@"panda" transform:hitTestResult.worldTransform];
    [self.sceneView.session addAnchor:anchor];
    NSError *err;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:anchor requiringSecureCoding:YES error:&err];
    if (err) {
        NSLog(@"can't encode anchor");
    }else{
        [self.multipeerSession sendToAllPeers:data];
    }
}
//分享会话
-(void)shareSession:(UIButton *)button{
    [self startRecordScreen:button];
//    [self.sceneView.session getCurrentWorldMapWithCompletionHandler:^(ARWorldMap * _Nullable worldMap, NSError * _Nullable error) {
//        ARWorldMap *map = worldMap;
//        if (!map) {
//            NSLog(@"Error:%@",error.localizedDescription);
//            return ;
//        }
//        NSError *err;
//        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:map requiringSecureCoding:YES error:&err];
//        if (err) {
//            NSLog(@"数据==can't encode map");
//        }else{
//            NSLog(@"数据==发送了");
//            [self.multipeerSession sendToAllPeers:data];
//        }
//    }];
    
}


#pragma mark --------------------------------- MultipeerConnectivityDelegate
//获取数据
- (void)receivedDataHandler:(NSData *)data PeerID:(MCPeerID *)peerID{
    ARWorldMap *worldMap = [NSKeyedUnarchiver unarchivedObjectOfClass:[ARWorldMap classForKeyedUnarchiver] fromData:data error:nil];
    NSLog(@"获取数据===1");
    if (worldMap) {
        NSLog(@"获取数据===2====%@",worldMap);
        ARWorldTrackingConfiguration *configuration = [[ARWorldTrackingConfiguration alloc] init];
        configuration.planeDetection = ARPlaneDetectionHorizontal;
        configuration.initialWorldMap = worldMap;
       [self.sceneView.session runWithConfiguration:configuration options:ARSessionRunOptionResetTracking|ARSessionRunOptionRemoveExistingAnchors];
        self.mapProvider = peerID;
        return;
    }
   ARAnchor *anchor = [NSKeyedUnarchiver unarchivedObjectOfClass:[ARAnchor classForKeyedUnarchiver] fromData:data error:nil];
    NSLog(@"获取数据===3");
    if (anchor) {
        NSLog(@"获取数据===4==%@",anchor);
        [self.sceneView.session addAnchor:anchor];
    }
}

#pragma mark --------------------------------- ARSCNViewDelegate
//添加节点时候调用（当开启平地捕捉模式之后，如果捕捉到平地，ARKit会自动添加一个平地节点）
- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    if ([anchor.name hasPrefix:@"panda"]) {
        //[node addChildNode:[self loadPlanPandaModel]];
        [node addChildNode:[self loadCustomNodeModel]];
    }
}
//刷新时调用
- (void)renderer:(id <SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    //NSLog(@"刷新中");
}
//更新节点时调用
- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    //NSLog(@"节点更新");
}
//移除节点时调用
- (void)renderer:(id <SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    //NSLog(@"节点移除");
}





#pragma mark --------------------------------- ARSessionDelegate

//会话位置更新（监听相机的移动），此代理方法会调用非常频繁，只要相机移动就会调用，如果相机移动过快，会有一定的误差，具体的需要强大的算法去优化，笔者这里就不深入了
//检查地图状态改变
- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame{
//    switch (frame.worldMappingStatus) {
//        case ARWorldMappingStatusNotAvailable:
//            self.sendMapButton.enabled = NO;
//            [self.sendMapButton setBackgroundImage:[UIImage imageNamed:@"btn_gray"] forState:UIControlStateNormal];
//            break;
//        case ARWorldMappingStatusLimited:
//            self.sendMapButton.enabled = NO;
//            [self.sendMapButton setBackgroundImage:[UIImage imageNamed:@"btn_gray"] forState:UIControlStateNormal];
//            break;
//        case ARWorldMappingStatusExtending:
//            if (![self isEmpty:self.multipeerSession.connectedPeers]) {
//                self.sendMapButton.enabled = YES;
//                [self.sendMapButton setBackgroundImage:[UIImage imageNamed:@"btn"] forState:UIControlStateNormal];
//            }
//            break;
//        case ARWorldMappingStatusMapped:
//            if (![self isEmpty:self.multipeerSession.connectedPeers]) {
//                self.sendMapButton.enabled = YES;
//                [self.sendMapButton setBackgroundImage:[UIImage imageNamed:@"btn"] forState:UIControlStateNormal];
//            }
//            break;
//        default:
//            break;
//    }
    //[self updateSessionInfoLabel:frame Messege:frame.camera.trackingState];
    //NSLog(@"相机移动");
    //self.videoView.image = [self toolVideoWithPixelBuffer:frame.capturedImage];
    //[self.sceneView setBackgroundColor:[UIColor colorWithPatternImage:[self toolVideoWithPixelBuffer:frame.capturedImage]]];
}
- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor*>*)anchors{
    NSLog(@"添加锚点");
}
- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor*>*)anchors{
    //NSLog(@"刷新锚点");
}
- (void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor*>*)anchors{
    NSLog(@"移除锚点");
}
-(void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera{
    [self updateSessionInfoLabel:session.currentFrame Messege:camera.trackingState];
}

#pragma mark --------------------------------- ARSessionObserver
-(void)sessionWasInterrupted:(ARSession *)session{
    NSLog(@"会话中断");
}
-(void)sessionInterruptionEnded:(ARSession *)session{
     NSLog(@"会话中断结束");
}
-(void)session:(ARSession *)session didFailWithError:(NSError *)error{
    NSLog(@"会话失败:%@",error.localizedDescription);
    [self resetTracking];
}
-(BOOL)sessionShouldAttemptRelocalization:(ARSession *)session{
    return YES;
}



#pragma mark --------------------------------- 自定义函数
//AR会话管理 (创建 小熊模型)
-(SCNNode *)loadPlanPandaModel{
    NSURL *sceneURL = [[NSBundle mainBundle] URLForResource:@"max" withExtension:@"scn" subdirectory:@"Assets.scnassets"];
    SCNReferenceNode *referenceNode = [SCNReferenceNode referenceNodeWithURL:sceneURL];
    [referenceNode load];
    return referenceNode;
}
//创建平面模型
-(SCNNode *)loadCustomNodeModel{
    SCNCone *cone = [SCNCone coneWithTopRadius:0.01 bottomRadius:0 height:0.05];
    cone.firstMaterial.diffuse.contents = [UIImage imageNamed:@"btn"];
    SCNNode *coneNode = [SCNNode nodeWithGeometry:cone];
    coneNode.position = SCNVector3Make(0,0,0);
    return coneNode;
}
//重置w轨迹
-(void)resetTracking{
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    [self.sceneView.session runWithConfiguration:configuration options:ARSessionRunOptionResetTracking|ARSessionRunOptionRemoveExistingAnchors];
}
//状态
-(void)updateSessionInfoLabel:(ARFrame *)frame Messege:(NSInteger)trackingState{
    NSString *message = @"";
    switch (trackingState) {
        case ARTrackingStateNotAvailable:
            message = @"跟踪不可用。";
            break;
        case ARTrackingStateLimited:
            message = @"初始化AR会话。跟踪限制-移动设备更慢。跟踪限制-点在一个区域与可见的表面细节，或改善照明条件。";
            break;
        case ARTrackingStateNormal:
            if ([self isEmpty:frame.anchors] && [self isEmpty:self.multipeerSession.connectedPeers]) {
                message = @"四处移动以映射环境，或等待加入共享会话。";
            }
            if (![self isEmpty:self.multipeerSession.connectedPeers] && self.mapProvider == nil) {
                message = [NSString stringWithFormat:@"Connected with %@",self.multipeerSession.connectedPeers[0].displayName];
            }
            break;
        default:
            break;
    }
    //NSLog(@"获取现在状态===%@",message);
}
//创建视图
-(void)createSubView{
    //地图
    self.sendMapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendMapButton.frame = CGRectMake(0, 30, 150, 50);
    [self.sendMapButton setTitle:@"开始录制" forState:UIControlStateNormal];
    [self.sendMapButton setBackgroundImage:[UIImage imageNamed:@"btn"] forState:UIControlStateNormal];
    [self.sendMapButton setBackgroundImage:[UIImage imageNamed:@"btn_gray"] forState:UIControlStateHighlighted];
    [self.sendMapButton setTintColor:UIColor.whiteColor];
    self.sendMapButton.clipsToBounds = YES;
    self.sendMapButton.layer.cornerRadius = 5;
    self.sendMapButton.center = CGPointMake(self.view.center.x, self.view.frame.size.height-200);
    [self.sendMapButton addTarget:self action:@selector(shareSession:) forControlEvents:UIControlEventTouchUpInside];
    
    //区域
    self.mappingStatusLabel = [[UILabel alloc] init];
    self.mappingStatusLabel.frame = CGRectMake(0, 0, self.view.frame.size.width, 50);
    self.mappingStatusLabel.center = CGPointMake(self.view.center.x, self.view.frame.size.height-300);
    self.mappingStatusLabel.textColor = UIColor.grayColor;
    
    
    //小图片显示
    self.videoView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 20, 100, 200)];
    self.videoView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.sceneView addSubview:self.sendMapButton];
    [self.sceneView addSubview:self.mappingStatusLabel];
    [self.sceneView addSubview:self.videoView];
}
//判断数组为空
-(BOOL)isEmpty:(NSArray *)array{
    if ([array isKindOfClass:[NSArray class]] && array.count > 0){
        return NO;
    }else{
        return YES;
    }
}


#pragma mark --------------------------------- 视频录制
//开始录制
-(void)startRecordScreen:(UIButton *)button{
    if (button.selected==YES) {
        button.selected = NO;
        [self stopRecord];
    }else{
       button.selected = YES;
        [self startCapture];
    }
}



//开始录制
-(void)startCapture {
    if (@available(iOS 11.0, *)) {
        [[RPScreenRecorder sharedRecorder]  startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
            if (CMSampleBufferDataIsReady(sampleBuffer) && bufferType == RPSampleBufferTypeVideo) {
                UIImage *image = [Common imageConvertForCMSampleBufferRef:sampleBuffer];
                //save 屏幕数据
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.videoView.image = image;
                });
            }
        } completionHandler:^(NSError * _Nullable error) {
            if (!error) {
                //NSLog(@"Recording started successfully.");
            }else{
                NSLog(@"Recording started error %@",error);
            }
        }];
    } else {
        // Fallback on earlier versions
    }
}

//结束录制
-(void)stopRecord{
    NSLog(@"正在结束录制");
    if (@available(iOS 11.0, *)) {
        [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
            NSLog(@"stopCaptureWithHandler error %@", error);
        }];
    } else {
        NSLog(@"CDPReplay:system < 11.0");
    }
}




@end
