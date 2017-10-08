//
//  GKWYMusicTool.h
//  mymusic
//
//  Created by MyMAC on 2017/10/6.
//  Copyright © 2017年 MyMAC. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GKWYMusicModel;

@interface GKWYMusicTool : NSObject
+ (NSArray*)localMusicList;
+ (BOOL)deletMusicWithModel:(GKWYMusicModel*)model;
@end
