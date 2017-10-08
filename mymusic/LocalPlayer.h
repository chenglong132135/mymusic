//
//  LocalPlayer.h
//  mymusic
//
//  Created by MyMAC on 2017/10/6.
//  Copyright © 2017年 MyMAC. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MediaPlayer;
@import AVFoundation;

#define localPlayer [LocalPlayer sharedInstance]

@protocol AudioCurrentTime <NSObject>

- (void)playWihtMusicCurrentTime:(NSTimeInterval)current andTotal:(NSTimeInterval)total;

@end

@interface LocalPlayer : NSObject<AVAudioPlayerDelegate>


@property (strong, nonatomic) AVAudioPlayer *player;
@property (nonatomic,assign)NSString *currentMusic;
@property (nonatomic,assign)CGFloat progress;
@property (nonatomic)NSTimer *timer;
@property (nonatomic,weak) id <AudioCurrentTime> timeDelegate;

+ (instancetype)sharedInstance;
- (void)playMusicWithPath:(NSString*)path filetype:(NSString*)type;
- (void)seekForward;
- (void)seekBackward;
- (BOOL)play;
- (void)pause;


@end
