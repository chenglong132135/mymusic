//
//  GKWYMusicTool.m
//  mymusic
//
//  Created by MyMAC on 2017/10/6.
//  Copyright © 2017年 MyMAC. All rights reserved.
//

#import "GKWYMusicTool.h"
#import "GKWYMusicModel.h"
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>

@implementation GKWYMusicTool
+ (NSArray *)localMusicList{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex: 0];
    NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSMutableArray *listarray = [NSMutableArray arrayWithCapacity:10];
    for (NSString *filename in tmplist) {
        NSString *fullpath = [documentsDirectory stringByAppendingPathComponent:filename];
        if ([self isFileExistAtPath:fullpath]) {
            if ([[filename pathExtension] isEqualToString:@"mp3"]) {
                [listarray  addObject:[self modelWithFilePath:fullpath]];
            }
        }
    }
    return listarray;
}
+ (GKWYMusicModel*)modelWithFilePath:(NSString*)path{
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    AVURLAsset *mp3Asset=[AVURLAsset URLAssetWithURL:fileUrl options:nil];
    NSString *singer;//歌手
    NSString *song;//歌曲名
    NSString *albumName;//专辑名
    for (NSString *format in [mp3Asset availableMetadataFormats]) {
        for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
            if([metadataItem.commonKey isEqualToString:@"title"]){
                song = (NSString *)metadataItem.value;//歌曲名
            }else if ([metadataItem.commonKey isEqualToString:@"artist"]){
                singer = (NSString *)metadataItem.value;//歌手
            }else if([metadataItem.commonKey isEqualToString:@"albumName"]){ // 专辑图片
                albumName = (NSString *)metadataItem.value;
            }
        }
    }
    GKWYMusicModel *model = [[GKWYMusicModel alloc]init];
    model.musicPath = path;
    model.musicName = song;
    model.musicArtist = singer;
    model.musicalbumName = albumName;
    return model;
}
+ (BOOL)deletMusicWithModel:(GKWYMusicModel*)model{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    BOOL isdelet;
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:model.musicPath];
    if (!blHave) {
        NSLog(@"no  have");
        isdelet = NO;
    }else {
        NSLog(@" have");
        BOOL blDele= [fileManager removeItemAtPath:model.musicPath error:nil];
        if (blDele) {
            NSLog(@"dele success");
        }else {
            NSLog(@"dele fail");
        }
        isdelet = blDele;
    }
    return isdelet;
}
+(BOOL)isFileExistAtPath:(NSString*)fileFullPath {
    BOOL isExist = NO;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:fileFullPath];
    return isExist;
}

@end
