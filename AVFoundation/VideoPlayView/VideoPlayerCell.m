//
//  VideoPlayerCell.m
//  AVFoundation
//
//  Created by xiong on 16/11/17.
//  Copyright © 2016年 xiong. All rights reserved.
//

#import "VideoPlayerCell.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface VideoPlayerCell ()

@property (weak, nonatomic) IBOutlet UIImageView *defaultImage;
@property (weak, nonatomic) IBOutlet UIButton *defaultPlayBtn;

@end

@implementation VideoPlayerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code

    
}


+ (VideoPlayerCell *)cellWithTableView:(UITableView *)tableView {
    
    VideoPlayerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoPlayerCell"];
    
    if (!cell) {
        
        [tableView registerNib:[UINib nibWithNibName:@"VideoPlayerCell" bundle:nil] forCellReuseIdentifier:@"VideoPlayerCell"];
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"VideoPlayerCell"];
    }
    return cell;
}

- (void)cellWithVideoUrl:(NSURL *)url {
    self.defaultPlayBtn.hidden = NO;
    
    dispatch_async(dispatch_queue_create("123123123", DISPATCH_QUEUE_SERIAL), ^{
        
        UIImage *image  = [self thumbnailImageForVideo:url atTime:arc4random_uniform(500)];
        if (image) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.defaultImage.image = image;
            });
        }
    });
}

- (IBAction)didClickPlayBtn:(UIButton *)sender {
    sender.hidden = YES;
    if (self.playVideoBlock) {
        self.playVideoBlock(self);
    }
    
}

- (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 1) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    UIImage*thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage: thumbnailImageRef] : nil;
    
    return thumbnailImage;
}




@end
