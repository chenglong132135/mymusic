//
//  GKWYMusicListCell.m
//  GKAudioPlayerDemo
//
//  Created by QuintGao on 2017/9/7.
//  Copyright © 2017年 高坤. All rights reserved.
//

#import "GKWYMusicListCell.h"

@interface GKWYMusicListCell()

@property (nonatomic, strong) UIButton *numberBtn;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *artistLabel;

@property (nonatomic, strong) UIView *lineView;


@end

@implementation GKWYMusicListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.numberBtn];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.artistLabel];
        [self.contentView addSubview:self.lineView];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(50);
            make.top.equalTo(self.contentView).offset(6);
        }];
        
        [self.artistLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.nameLabel.mas_left);
            make.bottom.equalTo(self.contentView).offset(-6);
        }];
        
        [self.numberBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.centerX.equalTo(self.nameLabel.mas_left).offset(-25);
        }];

        [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.nameLabel.mas_left);
            make.right.bottom.equalTo(self.contentView);
            make.height.mas_equalTo(0.5);
        }];
        
    }
    return self;
}

- (void)setModel:(GKWYMusicModel *)model {
    _model = model;
    
    self.nameLabel.text   = model.musicName;
    self.artistLabel.text = model.musicArtist;
    
    if (model.isPlaying) {
        [self.numberBtn setImage:[UIImage imageNamed:@"cm2_icn_volume"] forState:UIControlStateNormal];
        [self.numberBtn setTitle:nil forState:UIControlStateNormal];
        
        self.nameLabel.textColor = GKColorRGB(200, 38, 39);
        self.artistLabel.textColor = GKColorRGB(200, 38, 39);
    }else {
        NSString *num = [NSString stringWithFormat:@"%02zd", self.row + 1];
        
        [self.numberBtn setTitle:num forState:UIControlStateNormal];
        [self.numberBtn setImage:nil forState:UIControlStateNormal];
        
        self.nameLabel.textColor = [UIColor blackColor];
        self.artistLabel.textColor = [UIColor grayColor];
    }
}

- (void)likeBtnClick:(id)sender {
    !self.likeClicked ? : self.likeClicked(self.model);
}

#pragma mark - 懒加载
- (UIButton *)numberBtn {
    if (!_numberBtn) {
        _numberBtn = [UIButton new];
        [_numberBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        _numberBtn.userInteractionEnabled = NO;
    }
    return _numberBtn;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [UILabel new];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.font = [UIFont systemFontOfSize:16];
    }
    return _nameLabel;
}

- (UILabel *)artistLabel {
    if (!_artistLabel) {
        _artistLabel = [UILabel new];
        _artistLabel.textColor = [UIColor grayColor];
        _artistLabel.font = [UIFont systemFontOfSize:13];
    }
    return _artistLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [UIView new];
        _lineView.backgroundColor = GKColorRGB(200, 200, 200);
    }
    return _lineView;
}



@end
