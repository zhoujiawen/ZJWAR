//
//  Common.h
//  ARKit研究
//
//  Created by Apple on 2018/12/6.
//  Copyright © 2018年 zhoujiawen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>
#import <ReplayKit/ReplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Common : NSObject
+(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
//SampleBufferRef转黑白UIImage
+(UIImage *)imageFromSampleBuffer1:(CMSampleBufferRef) sampleBuffer;
//CVPixelBufferRef 转 Image
+(UIImage*)imageConvertForCVPixelBufferRef:(CVPixelBufferRef) pixelBufffer;
//CMSampleBufferRef 转 Image
+ (UIImage *)imageConvertForCMSampleBufferRef:(CMSampleBufferRef)sampleBuffer;


@end

NS_ASSUME_NONNULL_END
