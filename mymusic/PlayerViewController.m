//
//  PlayerViewController.m
//  mymusic
//
//  Created by MyMAC on 2017/10/6.
//  Copyright © 2017年 MyMAC. All rights reserved.
//

#import "PlayerViewController.h"

#import "GKWYMusicListView.h"
#import "GKWYMusicCoverView.h"
#import "GKWYMusicControlView.h"

#import "GKWYMusicModel.h"
#import "GKWYMusicTool.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LocalPlayer.h"
@interface PlayerViewController ()<GKWYMusicControlViewDelegate,AudioCurrentTime>
/*****************UI**********************/
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *artistLabel;

@property (nonatomic, strong) UIImageView *bgImageView;
/** 歌词视图 */
@property (nonatomic, strong) GKWYMusicControlView *controlView;
@property (nonatomic, strong) GKWYMusicListView *listView;
@property (nonatomic, strong) GKWYMusicCoverView *coverImgView;
/** 音乐播放列表 */
@property (nonatomic, strong) NSArray *musicList;
@property (nonatomic, strong) GKWYMusicModel *model;


@property (nonatomic, assign) GKWYPlayerPlayStyle playStyle; // 循环类型

@property (nonatomic, assign) BOOL isAutoPlay;   // 是否自动播放
@property (nonatomic, assign) BOOL isDraging;    // 是否正在拖拽
@property (nonatomic, assign) BOOL isSeeking;    // 是否在快进快退

@property (nonatomic, assign) NSTimeInterval duration;      // 总时间
@property (nonatomic, assign) NSTimeInterval currentTime;   // 当前时间;锁屏时的滑杆时间

@property (nonatomic, strong) NSTimer *seekTimer;  // 快进、快退定时器

@property (nonatomic, assign) NSInteger currentIndex; //当前播放index
/** 是否立即播放 */
@property (nonatomic, assign) BOOL ifNowPlay;

@end

@implementation PlayerViewController
+ (instancetype)sharedInstance {
    static PlayerViewController *playerVC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        playerVC = [PlayerViewController new];
    });
    return playerVC;
}
#pragma mark - Life Cycle
- (instancetype)init {
    if (self = [super init]) {
        
        [self.view addSubview:self.bgImageView];
        [self.view addSubview:self.coverImgView];
        [self.view addSubview:self.controlView];
        [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.view);
            //            make.height.mas_equalTo(150);
            make.height.mas_equalTo(170);
        }];
        
        [self.coverImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view).offset(64);
            make.bottom.equalTo(self.controlView.mas_top).offset(20);
        }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.backgroundColor = [UIColor redColor];
    [self setupLockScreenMediaInfoNull];
    [self setupLockScreenControlInfo];
    localPlayer.timeDelegate = self;
    [self addNotifications];
    // Do any additional setup after loading the view.
}
- (void)dealloc{
    [self removeNotifications];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playWithIndex:(NSInteger)index withList:(NSArray*)listary{
    
    self.musicList = listary;
    self.currentIndex = index;
    self.model = self.musicList[index];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WYPlayerChangeMusicNotification" object:nil userInfo:self.model];
    
    [localPlayer playMusicWithPath:_model.musicPath filetype:@"mp3"];
    NSURL *fileUrl = [NSURL fileURLWithPath:_model.musicPath];
    AVURLAsset *mp3Asset=[AVURLAsset URLAssetWithURL:fileUrl options:nil];
    UIImage *image;//图片
    for (NSString *format in [mp3Asset availableMetadataFormats]) {
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
            if([metadataItem.commonKey isEqualToString:@"artwork"]){ // 专辑图片
                NSData *imageData = (NSData *)metadataItem.value;
                image = [UIImage imageWithData:imageData];
            }
        }
    }
    if (image) {
        self.coverImgView.imgView.image = image;
    }else{
        self.coverImgView.imgView.image = [UIImage imageNamed:@"cm2_icn_img_loading"];
    }
    
    [self playMusic];
}

- (void)addNotifications {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    // 插拔耳机
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    // 播放打断
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    
}
- (void)removeNotifications {
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
}

#pragma mark - Notifications

- (void)audioSessionRouteChange:(NSNotification *)notify {
    NSDictionary *interuptionDict = notify.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"耳机插入");
            // 继续播放音频，什么也不用做
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            NSLog(@"耳机拔出");
            // 注意：拔出耳机时系统会自动暂停你正在播放的音频，因此只需要改变UI为暂停状态即可
            if (self.isPlaying) {
                [self pauseMusic];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)audioSessionInterruption:(NSNotification *)notify {
    NSDictionary *interuptionDict = notify.userInfo;
    
    NSInteger interruptionType = [interuptionDict[AVAudioSessionInterruptionTypeKey] integerValue];
    NSInteger interruptionOption = [interuptionDict[AVAudioSessionInterruptionOptionKey] integerValue];
    
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        // 收到播放中断的通知，暂停播放
        if (self.isPlaying) {
            [self pauseMusic];
        }
    }else {
        // 中断结束，判断是否需要恢复播放
        if (interruptionOption == AVAudioSessionInterruptionOptionShouldResume) {
            if (!self.isPlaying) {
                [self playMusic];
            }
        }
    }
}
- (void)playMusic{
    if (self.musicList.count == 0 ) {
        self.musicList = [GKWYMusicTool localMusicList];
        [self playWithIndex:0 withList:self.musicList];
        return;
    }
    [self.coverImgView playedWithAnimated:YES];
    [localPlayer play];
    self.isPlaying = YES;
    [self.controlView setupPlayBtn];
    [self setupLockScreenMediaInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"musicIsplaying" object:nil];
}

- (void)pauseMusic{
    [localPlayer pause];
    [self.controlView setupPauseBtn];
    self.isPlaying = NO;
    [self.coverImgView pausedWithAnimated:YES];
    // 更新锁屏界面
    [self setupLockScreenMediaInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"musicIsPause" object:nil];
}
- (void)playPrevMusic{
    
    _currentIndex -=1;
    if (_currentIndex == self.musicList.count - 1) {
        _currentIndex +=1;
        return;
    }
    
    if (self.isPlaying) {
        [self pauseMusic];
    }
    
    [self playWithIndex:_currentIndex withList:self.musicList];
}
- (void)playNextMusic{
    _currentIndex += 1;
    if (_currentIndex >= self.musicList.count){
        _currentIndex -=1;
        [self playWithIndex:0 withList:self.musicList];
        return;
    }
    if (self.isPlaying) {
        [self pauseMusic];
    }
    [self playWithIndex:_currentIndex withList:self.musicList];

}
#pragma mark - 懒加载
- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        _bgImageView.userInteractionEnabled = NO;
        _bgImageView.clipsToBounds = YES;
        // 添加模糊效果
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blur];
        effectView.frame = _bgImageView.bounds;
        [_bgImageView addSubview:effectView];
    }
    return _bgImageView;
}
- (GKWYMusicCoverView *)coverImgView {
    if (!_coverImgView) {
        _coverImgView = [GKWYMusicCoverView new];
    }
    return _coverImgView;
}
- (GKWYMusicControlView *)controlView {
    if (!_controlView) {
        _controlView = [GKWYMusicControlView new];
        _controlView.delegate = self;
    }
    return _controlView;
}

- (void)playWihtMusicCurrentTime:(NSTimeInterval)current andTotal:(NSTimeInterval)total{
    self.currentTime = current;
    self.duration = total;
    self.controlView.currentTime = [GKTool timeStrWithSecTime:current];
    self.controlView.totalTime = [GKTool timeStrWithSecTime:total];
    self.controlView.value = current/total;
    if (current <= total && current >= total - 1.5) {
        [self playNextMusic];
    }
    
    // 更新锁屏界面
    [self setupLockScreenMediaInfo];
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickComment:(UIButton *)commentBtn {
    NSLog(@"评论");
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickDownload:(UIButton *)downloadBtn {
     NSLog(@"下载");
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickList:(UIButton *)listBtn {
     NSLog(@"列表");
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickLoop:(UIButton *)loopBtn {
    if (self.playStyle == GKWYPlayerPlayStyleLoop) {  // 循环->单曲
        self.playStyle = GKWYPlayerPlayStyleOne;
    }else if (self.playStyle == GKWYPlayerPlayStyleOne) { // 单曲->随机
        self.playStyle = GKWYPlayerPlayStyleRandom;
    }else { // 随机-> 循环
        self.playStyle = GKWYPlayerPlayStyleLoop;
    }
    self.controlView.style = self.playStyle;
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.playStyle forKey:kPlayerPlayStyleKey];
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickLove:(UIButton *)loveBtn {
     NSLog(@"didClickLove");
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickMore:(UIButton *)moreBtn {
     NSLog(@"didClickMore");
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickNext:(UIButton *)nextBtn {
     NSLog(@"playNextMusic");
    [self playNextMusic];
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickPlay:(UIButton *)playBtn {
     NSLog(@"didClickPlay");
    if (!self.isPlaying) {
        [self playMusic];
    }else{
        [self pauseMusic];
    }
}

- (void)controlView:(GKWYMusicControlView *)controlView didClickPrev:(UIButton *)prevBtn {
    [self playPrevMusic];
}

- (void)controlView:(GKWYMusicControlView *)controlView didSliderTapped:(float)value {
    
    self.controlView.currentTime = [GKTool timeStrWithSecTime:(self.duration * value)];
    localPlayer.progress = value;
}

- (void)controlView:(GKWYMusicControlView *)controlView didSliderTouchBegan:(float)value {
    
    localPlayer.progress = value;
}
- (void)controlView:(GKWYMusicControlView *)controlView didSliderTouchEnded:(float)value {
    self.isDraging = NO;
    localPlayer.progress = value;
}
- (void)controlView:(GKWYMusicControlView *)controlView didSliderValueChange:(float)value {
    
    self.controlView.currentTime = [GKTool timeStrWithSecTime:(self.duration * value)];
}


- (void)setupLockScreenControlInfo {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    // 锁屏播放
    __weak typeof(id) weakSelf = self;
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        if (!_isPlaying) [weakSelf playMusic];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    // 锁屏暂停
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (_isPlaying) {
            [weakSelf pauseMusic];
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.stopCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakSelf pauseMusic];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 播放和暂停按钮（耳机控制）
    MPRemoteCommand *playPauseCommand = commandCenter.togglePlayPauseCommand;
    playPauseCommand.enabled = YES;
    [playPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        if (_isPlaying) {
            NSLog(@"暂停哦哦哦");
            [weakSelf pauseMusic];
        }else {
            NSLog(@"播放哦哦哦");
            [weakSelf playMusic];
        }
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 上一曲
    MPRemoteCommand *previousCommand = commandCenter.previousTrackCommand;
    [previousCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        [weakSelf playPrevMusic];
        NSLog(@"上一曲");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    // 下一曲
    MPRemoteCommand *nextCommand = commandCenter.nextTrackCommand;
    nextCommand.enabled = YES;
    [nextCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
//        self.isAutoPlay = NO;
        
        [weakSelf playNextMusic];
        NSLog(@"---下一曲");
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    
    // 拖动进度条
    if ([UIDevice currentDevice].systemVersion.doubleValue >= 9.0) {
        [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            
            MPChangePlaybackPositionCommandEvent *positionEvent = (MPChangePlaybackPositionCommandEvent *)event;
            
            if (positionEvent.positionTime != self.currentTime) {
                _currentTime = positionEvent.positionTime;
                
                localPlayer.progress = (float)self.currentTime / self.duration;
                self.controlView.value = (float)self.currentTime / self.duration;
            }
            
            return MPRemoteCommandHandlerStatusSuccess;
        }];
    }
}

- (void)setupLockScreenMediaInfoNull {
    // 2. 获取锁屏界面中心
    MPNowPlayingInfoCenter *playingCenter = [MPNowPlayingInfoCenter defaultCenter];
    // 3. 设置展示的信息
    NSMutableDictionary *playingInfo = [NSMutableDictionary new];
    playingInfo[MPMediaItemPropertyAlbumTitle] = self.model.musicalbumName;
    playingInfo[MPMediaItemPropertyTitle]      = self.model.musicName;
    playingInfo[MPMediaItemPropertyArtist]     = self.model.musicArtist;
    
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"cm2_fm_bg-ip6"]];
    playingInfo[MPMediaItemPropertyArtwork] = artwork;
    
    // 当前播放的时间
    playingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithFloat:0];
    // 进度的速度
    playingInfo[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
    // 总时间
    playingInfo[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithFloat:0 ];
    if ([UIDevice currentDevice].systemVersion.doubleValue >= 10.0) {
            playingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = [NSNumber numberWithFloat:1.0];
    }
    playingCenter.nowPlayingInfo = playingInfo;
}
- (void)setupLockScreenMediaInfo {
    // 1. 获取当前播放的歌曲的信息
    
    // 2. 获取锁屏界面中心
    MPNowPlayingInfoCenter *playingCenter = [MPNowPlayingInfoCenter defaultCenter];
    // 3. 设置展示的信息
    NSMutableDictionary *playingInfo = [NSMutableDictionary new];
    playingInfo[MPMediaItemPropertyAlbumTitle] = self.model.musicalbumName;
    playingInfo[MPMediaItemPropertyTitle]      = self.model.musicName;
    playingInfo[MPMediaItemPropertyArtist]     = self.model.musicArtist;
    
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.coverImgView.imgView.image];
    playingInfo[MPMediaItemPropertyArtwork] = artwork;
    
    // 当前播放的时间
    playingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = [NSNumber numberWithFloat:self.currentTime];
//    NSLog(@"%f",self.currentTime);
    // 进度的速度
    playingInfo[MPNowPlayingInfoPropertyPlaybackRate] = [NSNumber numberWithFloat:1.0];
    // 总时间
    playingInfo[MPMediaItemPropertyPlaybackDuration] = [NSNumber numberWithFloat:self.duration];
    if ([UIDevice currentDevice].systemVersion.doubleValue >= 10.0) {
            playingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = [NSNumber numberWithFloat:self.controlView.value];
    }
    playingCenter.nowPlayingInfo = playingInfo;
}
@end
