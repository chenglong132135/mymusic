//
//  GKWYMusicModel.h
//  mymusic
//
//  Created by MyMAC on 2017/10/6.
//  Copyright © 2017年 MyMAC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GKWYMusicModel : NSObject<NSCopying>
@property (nonatomic,copy)NSString *musicPath;
@property (nonatomic,copy)NSString *musicName;
@property (nonatomic,copy)NSString *musicArtist;
@property (nonatomic,copy)NSString *musicalbumName;
@property (nonatomic,assign)BOOL isPlaying;
@end
