//
//  LocalPlayer.m
//  mymusic
//
//  Created by MyMAC on 2017/10/6.
//  Copyright © 2017年 MyMAC. All rights reserved.
//

#import "LocalPlayer.h"

static LocalPlayer *lPlayer;
@interface LocalPlayer()

@end

@implementation LocalPlayer

+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lPlayer = [[self alloc]init];
        [lPlayer addobserver];
    });
    return lPlayer;
}
- (void)addobserver{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(stopthtimer) name:@"musicIsPause" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(startthtimer) name:@"musicIsplaying" object:nil];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkAudioTimes) userInfo:nil repeats:YES];
}

- (void)stopthtimer{
    _timer.fireDate = [NSDate distantFuture];
}
- (void)startthtimer{
    _timer.fireDate = [NSDate distantPast];
}
- (void)playMusicWithPath:(NSString*)path filetype:(NSString *)type{
    if ([self.currentMusic isEqualToString:path]) {
        return;
    }
    self.currentMusic = path;
    [_player stop];
    _player = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
}
- (void)seekForward{
    if (_player) {
        static float step = 0.05;
        NSTimeInterval newCur = _player.currentTime + _player.duration*step;
        _player.currentTime = newCur;
    }
}
- (void)seekBackward{
    if (_player) {
        static float step = 0.05;
        NSTimeInterval newCur = _player.currentTime - _player.duration*step;
        if (newCur<0) {
            newCur = 0;
        }
        _player.currentTime = newCur;
    }
}
- (BOOL)play{
    if (_player.isPlaying) {
        return YES;
    }else{
       return [_player play];
    }
}
- (void)pause{
    if (_player.isPlaying) {
       return [_player pause];
    }
}
- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    _player.currentTime = _player.duration * progress;
    
}
- (void)checkAudioTimes{
    if (!_player) {
        return;
    }
    if ([self.timeDelegate respondsToSelector:@selector(playWihtMusicCurrentTime:andTotal:)]) {
        [self.timeDelegate playWihtMusicCurrentTime:self.player.currentTime andTotal:self.player.duration];
    }
}
@end
