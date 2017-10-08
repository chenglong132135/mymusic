//
//  PlayerViewController.h
//  mymusic
//
//  Created by MyMAC on 2017/10/6.
//  Copyright © 2017年 MyMAC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerViewController : UIViewController
/** 是否正在播放 */
@property (nonatomic, assign) BOOL isPlaying;

+ (instancetype)sharedInstance;
- (void)playWithIndex:(NSInteger)index withList:(NSArray*)listary;
@end
