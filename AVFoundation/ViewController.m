//
//  ViewController.m
//  AVFoundation
//
//  Created by xiong on 16/11/17.
//  Copyright © 2016年 xiong. All rights reserved.
//

#import "ViewController.h"
#import "VideoPlayerCell.h"
#import "VideoPlayView.h"


#define kHeaderViewHeight 500
#define kTitleImageHeight 64
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    CGRect _oldPlayerFrame;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSMutableArray *playViewArr;
@property (nonatomic, strong) UIView  *headerView;
@property (nonatomic, strong) UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *navView;
@property (strong, nonatomic) IBOutlet UIView *titleImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    _playViewArr = [NSMutableArray array];
    _dataArray = [NSMutableArray array];
    
    
    _headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kHeaderViewHeight)];
    _headerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = _headerView;
    
    _imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kHeaderViewHeight)];
    _imageView.image = [UIImage imageNamed:@"bbb"];
    [self.view addSubview:_imageView];
    
    [self.view bringSubviewToFront:self.tableView];
    
    [self.view bringSubviewToFront:self.navView];
    
    self.titleImageView.layer.cornerRadius = kTitleImageHeight/2;
    self.titleImageView.layer.masksToBounds = YES;
    
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    VideoPlayerCell *cell = [VideoPlayerCell cellWithTableView:tableView];
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"testvideo" ofType:@"mp4"]];
    
    url = [NSURL URLWithString:@"http://file3.data.weipan.cn.wscdns.com/3101888/95f124ed139d3c29a2ab36c1f03ff9cdeb49d0ef?ip=1479462153,180.166.212.58&ssig=HCTsqre3Dk&Expires=1479462753&KID=sae,l30zoo1wmz&fn=1-8%20%E7%B6%93%E5%85%B8%E9%96%B1%E8%AE%80%E7%A4%BA%E4%BE%8B%E4%B8%8B%20%2810-54%29.mp4"];
    
    url = [NSURL URLWithString:@"http://centavedio.file.alimmdn.com/video/estatevideo/CB443131-FB80-46F8-88BA-9EEA6CBF025C.mp4?t=1471507275826"];
    
    [cell cellWithVideoUrl:url];
    
    __weak typeof(self) weakSelf = self;
    
    cell.playVideoBlock = ^(VideoPlayerCell *cell) {
        
        [_playViewArr enumerateObjectsUsingBlock:^(VideoPlayView  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [weakSelf.playViewArr removeObject:obj];
            [obj remove];
                
        }];
        
        VideoPlayView *view = [[NSBundle mainBundle]loadNibNamed:@"VideoPlayView" owner:nil options:nil].lastObject;
        view.frame = cell.frame;
        [view createPlayerLayerWithUrl:url];
        [view showInView:self.tableView];
        
        [weakSelf.playViewArr addObject:view];
        
    };
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 190;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [_playViewArr enumerateObjectsUsingBlock:^(VideoPlayView  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (CGRectEqualToRect(cell.frame, _oldPlayerFrame)) {
            
            if (obj.videoPlayState == VideoPlayStatePlaying || obj.videoPlayState == VideoPlayStatePause) {
                
                [obj stopPictureInPicture];
            }
        }
    }];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [_playViewArr enumerateObjectsUsingBlock:^(VideoPlayView  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (CGRectEqualToRect(cell.frame, obj.frame)) {
            
            if (obj.videoPlayState == VideoPlayStatePlaying || obj.videoPlayState == VideoPlayStatePause) {
                
                _oldPlayerFrame = obj.frame;
                
                [obj startPictureInPicture];
                
            }
        }
    }];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if (offsetY > 0) {
        
        if (offsetY > kHeaderViewHeight) {
            return;
        }
        _imageView.frame = CGRectMake(0, -offsetY/3, kScreenWidth, kHeaderViewHeight);
        
        CGFloat width = kTitleImageHeight - kTitleImageHeight/2 * offsetY/(kHeaderViewHeight-kTitleImageHeight);
        CGFloat height = width;
        CGFloat x = (kScreenWidth - width)/2;
        CGFloat y = kTitleImageHeight/2;
        
        _titleImageView.frame = CGRectMake(x, y, width, height);
        _titleImageView.layer.cornerRadius = width/2;

    }else{
        
        _imageView.frame = CGRectMake(offsetY/2, 0, kScreenWidth-offsetY, kHeaderViewHeight-offsetY);
    }
}
@end
