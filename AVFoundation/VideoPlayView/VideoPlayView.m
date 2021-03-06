//
//  VideoPlayView.m
//  AVFoundation
//
//  Created by xiong on 16/11/17.
//  Copyright © 2016年 xiong. All rights reserved.
//

#import "VideoPlayView.h"
#import <AVFoundation/AVFoundation.h>

static NSString *MedioPlayStatus = @"status";                       // 播放状态
static NSString *MedioLoadedTimeRanges = @"loadedTimeRanges";       // 缓冲进度
static NSString *MedioBufferCanPlay = @"playbackLikelyToKeepUp";    // 缓冲部分可以播放
static NSString *MedioBufferPlayDone = @"playbackBufferEmpty";      // 缓冲部分播放完毕, 需继续缓冲

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface VideoPlayView ()
{
    UIView *_supView;  // 父视图
    CGRect _tempFrame; // 相对于 keyWindow 的 frame
    CGRect _oldFrame;  // 相对于_supView 的 frame
    BOOL _isFullScreen;
    BOOL _isHideToolBar;
    BOOL _isPip;
}

@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIButton *replayBtn;

//@property (nonatomic, strong) AVPlayerLayer *playLayer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation VideoPlayView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [_sliderView addTarget:self action:@selector(sliderValueWillChange) forControlEvents:UIControlEventTouchDown];
    
    [_sliderView addTarget:self action:@selector(sliderValueDidChange) forControlEvents:UIControlEventTouchUpInside];
    
    _replayBtn.layer.cornerRadius = 6;
    
    _replayBtn.layer.masksToBounds = YES;
    
    _replayBtn.hidden = YES;
    
    _activityIndicatorView.layer.cornerRadius = 6;
    
    _activityIndicatorView.layer.masksToBounds = YES;
    
    _toolBarView.hidden = YES;
    
    [self addGestureRecognizer];
}

#pragma mark - 初始化 videoPlayer
/// 添加手势
- (void)addGestureRecognizer {
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    
    UIRotationGestureRecognizer *rotation = [[UIRotationGestureRecognizer alloc]initWithTarget:self action:@selector(rotation:)];
    
    [self.playView addGestureRecognizer:tap];
    
    [self.playView addGestureRecognizer:doubleTap];
    
    [self.playView addGestureRecognizer:rotation];
    
    [tap requireGestureRecognizerToFail:doubleTap];
}

/// 创建 playerLayer
- (void)createPlayerLayerWithUrl:(NSURL *)url {
    
    self.player = [AVPlayer playerWithURL:url];
    
    self.playLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    self.playLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    self.playLayer.frame = self.playView.frame;

    [self addAvPlayerObserver];
    
}

/// 添加监听
- (void)addAvPlayerObserver{
    
    [_playLayer.player.currentItem addObserver:self forKeyPath:MedioPlayStatus options:NSKeyValueObservingOptionNew context:nil];
    
    [_playLayer.player.currentItem addObserver:self forKeyPath:MedioLoadedTimeRanges options:NSKeyValueObservingOptionNew context:nil];
    
    [_playLayer.player.currentItem addObserver:self forKeyPath:MedioBufferCanPlay options:NSKeyValueObservingOptionNew context:nil];
    
    [_playLayer.player.currentItem addObserver:self forKeyPath:MedioBufferPlayDone options:NSKeyValueObservingOptionNew context:nil];
    
    __weak typeof(self)weakSelf = self;
    
    // 添加播放进度的监听
    [_playLayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        [weakSelf updateProgress ];
    }];
}

#pragma mark - 播放相关事件
/// 点击了播放按钮
- (IBAction)didClickPlayBtn:(UIButton *)sender {
    
    [self play:self.player.rate == 0];
    
}

/// 播放完成后点击了 replay 按钮
- (IBAction)didClickReplayBtn:(UIButton *)sender {
    
    sender.hidden = YES;
    
    [self.activityIndicatorView startAnimating];
    
    [self.playLayer.player seekToTime:CMTimeMake(1, 1) completionHandler:^(BOOL finished) {
       
        if (finished) {
            
            [self play:YES];
        }
    }];
    
}


/**
 播放 / 暂停

 @param isPlay  true:play  false:pause
 */
- (void)play:(BOOL)isPlay {
    
    if (isPlay) {
        
        self.videoPlayState = VideoPlayStatePlaying;
        
        [self.activityIndicatorView stopAnimating];
        
        [self.player play];
        
        [self.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
        
        self.toolBarView.hidden = NO;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:7 target:self selector:@selector(hideToolBarView) userInfo:nil repeats:NO];
        
    }else{
        
        self.videoPlayState = VideoPlayStatePause;
        
        [self.activityIndicatorView stopAnimating];
        
        [self.player pause];
        
        [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        
        [_timer invalidate];
    }
}

/// 刷新播放进度条 和 时间
- (void)updateProgress{
    
    _timeLabel.text = [self getTimeStrWithTimeInterval:CMTimeGetSeconds(_playLayer.player.currentItem.duration) - CMTimeGetSeconds(_playLayer.player.currentItem.currentTime)];
    
    _sliderView.value = CMTimeGetSeconds(_playLayer.player.currentItem.currentTime)/CMTimeGetSeconds(_playLayer.player.currentItem.duration);
    
    /// 播放完成后执行操作
    if (CMTimeCompare(_playLayer.player.currentItem.duration, _playLayer.player.currentItem.currentTime) <= 0) {
        
        _replayBtn.hidden = NO;
        
        [_timer invalidate];
        
        _toolBarView.alpha = 1;
        
        self.videoPlayState = VideoPlayStateFinish;
        
        /// 若处于画中画状态则播放完后关掉画中画
        if (_isPip) {
             [self stopPictureInPicture];
        }
    }
}

/// 将时间戳装话为指定格式时间字符串
- (NSString *)getTimeStrWithTimeInterval:(CGFloat)timeInterval{
    
    if (isnan(timeInterval)) {
        
        return @"00:00";
    }
    int m = (timeInterval)/60;
    
    int s = timeInterval-m*60;
    
    return [NSString stringWithFormat:@"%02d:%02d",m,s];
}

#pragma mark - 监听 status
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:MedioPlayStatus]) {
        
        if ([[change objectForKey:NSKeyValueChangeNewKey]  isEqual: @(AVPlayerStatusReadyToPlay)]) {
            
            [self updateProgress];
            
            [self.playView.layer addSublayer:self.playLayer];
            
            [self play:YES];
            
        }else if ([[change objectForKey:NSKeyValueChangeNewKey]  isEqual: @(AVPlayerStatusFailed)]) {
            
            self.videoPlayState = VideoPlayStateFaild;
        }
    }else if ([keyPath isEqualToString:MedioLoadedTimeRanges]) {
        
        NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
        
        if (timeRanges && [timeRanges count]) {
            
            CMTimeRange timerange = [[timeRanges objectAtIndex:0] CMTimeRangeValue];
            
            /// 更新缓冲进度条
            _progressView.progress = CMTimeGetSeconds(CMTimeAdd(timerange.start, timerange.duration))/CMTimeGetSeconds(_playLayer.player.currentItem.duration);
            
        }
    }else if ([keyPath isEqualToString:MedioBufferPlayDone]) {
        
        [self.activityIndicatorView startAnimating];
        
    }else if ([keyPath isEqualToString:MedioBufferCanPlay]) {
        
        [self.activityIndicatorView stopAnimating];
        
    }
}



#pragma mark -  手动拖动播放进度
- (void)sliderValueWillChange{
    
    [_playLayer.player pause];
}

- (void)sliderValueDidChange{
    
    [_playLayer.player seekToTime:CMTimeMakeWithSeconds(_sliderView.value * CMTimeGetSeconds(_playLayer.player.currentItem.duration), NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        
        _timeLabel.text = [self getTimeStrWithTimeInterval:_sliderView.value * CMTimeGetSeconds(_playLayer.player.currentItem.duration)];
        
        [self play:YES];
        
    }];
}

#pragma mark - 全屏的处理
/// 点击了全屏按钮
- (IBAction)didClickFullScreenBtn:(UIButton *)sender {
    
    self.toolBarView.hidden = YES;
    
    if (_isFullScreen) {
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        
        [UIView animateWithDuration:0.5 animations:^{
            
            self.transform = CGAffineTransformMakeRotation(0);
            
            self.frame = _tempFrame;
            
            self.playLayer.frame = CGRectMake(0, 0, _tempFrame.size.width, _tempFrame.size.height);
            
        }completion:^(BOOL finished) {
            
            [_supView addSubview:self];
            
            self.frame = _oldFrame;
            
            self.toolBarView.hidden = NO;
        }];
        
    }else {

        _tempFrame = [_supView convertRect:self.frame toView:[UIApplication sharedApplication].keyWindow];
        
        self.frame = _tempFrame;
        
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        
        [UIView animateWithDuration:0.5 animations:^{
            
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
            
            self.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
            
            self.playLayer.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
            
        }completion:^(BOOL finished) {
            
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            
            self.toolBarView.hidden = NO;
        }];
    }
    
    _isFullScreen = !_isFullScreen;
}


# pragma mark - 手势处理
- (void)tap:(UITapGestureRecognizer *)gesture {
    
    if (!_isHideToolBar) {
        
        [self hideToolBarView];
        
        return;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        
        self.toolBarView.alpha = 1;
        
    }completion:^(BOOL finished) {
        
        _isHideToolBar = NO;
    }];
    
    if (self.playLayer.player.rate != 0) {
        
        [_timer invalidate];
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:7 target:self selector:@selector(hideToolBarView) userInfo:nil repeats:NO];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)gesture {
    
    if (self.player.rate != 1) {
        return;
    }
    
    [self didClickFullScreenBtn:self.fullScreenBtn];
}

- (void)rotation:(UIRotationGestureRecognizer *)gesture {
    
    if (gesture.state==UIGestureRecognizerStateEnded) {
        
        [self didClickFullScreenBtn:self.fullScreenBtn];
    }
    
}


#pragma mark - 显示模式的设置
/// 开启画中画
- (void)startPictureInPicture {
    
    self.frame = CGRectMake(kScreenWidth/2, 64, kScreenWidth/2, 95);
    
    self.playLayer.frame = CGRectMake(0, 0, kScreenWidth/2, 95);
    
    self.toolBarView.hidden = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    _isPip = YES;
}

/// 退出画中画
- (void)stopPictureInPicture {
    
    self.frame = _oldFrame;
    
    self.playLayer.frame = CGRectMake(0, 0, kScreenWidth, 190);
    
    self.toolBarView.hidden = NO;
    
    [_supView addSubview:self];
    
    _isPip = NO;
}

- (void)showInView:(UIView *)view {
    
    _supView = view;
    
    _oldFrame = self.frame;
    
    [view addSubview:self];
}

- (void)remove {
    
    [self.player pause];
    
    [self removeFromSuperview];
    
}

- (void)hideToolBarView {
    
    [UIView animateWithDuration:0.25 animations:^{
        
        self.toolBarView.alpha = 0;
        
    }completion:^(BOOL finished) {
        
        _isHideToolBar = YES;
    }];
}

- (void)dealloc {
    
    [_playLayer.player.currentItem removeObserver:self forKeyPath:MedioPlayStatus];
    
    [_playLayer.player.currentItem removeObserver:self forKeyPath:MedioLoadedTimeRanges];
    
    [_playLayer.player.currentItem removeObserver:self forKeyPath:MedioBufferCanPlay];
    
    [_playLayer.player.currentItem removeObserver:self forKeyPath:MedioBufferPlayDone];
}
@end


