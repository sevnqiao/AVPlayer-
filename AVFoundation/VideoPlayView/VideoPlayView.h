//
//  VideoPlayView.h
//  AVFoundation
//
//  Created by xiong on 16/11/17.
//  Copyright © 2016年 xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayerLayer;

typedef NS_ENUM(NSInteger, VideoPlayState){
    VideoPlayStateFaild = 1,
    VideoPlayStatePlaying,
    VideoPlayStatePause,
    VideoPlayStateFinish,
};

@interface VideoPlayView : UIView

@property (nonatomic, strong) AVPlayerLayer *playLayer;
@property (nonatomic, assign) VideoPlayState videoPlayState;

- (void)createPlayerLayerWithUrl:(NSURL *)url;

- (void)showInView:(UIView *)view;

- (void)remove;

- (void)startPictureInPicture;

- (void)stopPictureInPicture;
@end
