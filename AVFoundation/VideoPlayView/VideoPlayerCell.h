//
//  VideoPlayerCell.h
//  AVFoundation
//
//  Created by xiong on 16/11/17.
//  Copyright © 2016年 xiong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoPlayerCell;

typedef void(^PlayVideoBlock)(VideoPlayerCell *);

@interface VideoPlayerCell : UITableViewCell
@property (nonatomic, copy) PlayVideoBlock playVideoBlock;
+ (VideoPlayerCell *)cellWithTableView:(UITableView *)tableView;
- (void)cellWithVideoUrl:(NSURL *)url;

@end
