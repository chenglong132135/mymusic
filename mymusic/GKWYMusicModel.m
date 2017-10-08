//
//  GKWYMusicModel.m
//  mymusic
//
//  Created by MyMAC on 2017/10/6.
//  Copyright © 2017年 MyMAC. All rights reserved.
//

#import "GKWYMusicModel.h"

@implementation GKWYMusicModel
- (instancetype)copyWithZone:(NSZone *)zone{
    GKWYMusicModel *model = [[self class]allocWithZone:zone];
    model.musicPath = _musicPath;
    model.musicName = _musicName;
    model.isPlaying = _isPlaying;
    model.musicArtist = _musicArtist;
    model.musicalbumName = _musicalbumName;
    return model;
}
@end
