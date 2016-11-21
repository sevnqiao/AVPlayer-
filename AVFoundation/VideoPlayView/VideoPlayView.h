//
//  VideoPlayView.h
//  AVFoundation
//
//  Created by xiong on 16/11/17.
//  Copyright © 2016年 xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVPlayer;

@interface VideoPlayView : UIView

- (void)createPlayerLayerWithUrl:(NSURL *)url;

- (void)showInView:(UIView *)view;

- (void)remove;
@end
