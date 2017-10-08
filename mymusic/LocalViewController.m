//
//  LocalViewController.m
//  GKAudioPlayerDemo
//
//  Created by MyMAC on 2017/10/5.
//  Copyright © 2017年 高坤. All rights reserved.
//

#import "LocalViewController.h"
#import "GKWYMusicListCell.h"
#import "GKWYMusicTool.h"
#import "PlayerViewController.h"
@interface LocalViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,copy)NSArray *listArray;
@property (nonatomic,strong)UITableView *listTable;
@property (nonatomic,copy)GKWYMusicModel *currentModel;
@end

@implementation LocalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.listArray = [GKWYMusicTool localMusicList];
    NSLog(@"%@",_listArray);
    [self.view addSubview:self.listTable];
    [self setupNavigation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData:) name:@"WYPlayerChangeMusicNotification" object:nil];
}
- (void)setupNavigation{
    self.navigationItem.title = @"本地音乐";
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 32, 32)];
    [btn addTarget:self action:@selector(pushPlayerview) forControlEvents:UIControlEventTouchUpInside];
    [btn setImage:[UIImage imageNamed:@"cm2_list_icn_loading1"] forState:UIControlStateNormal];
    UIBarButtonItem *rightBtn = [[UIBarButtonItem alloc]initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = rightBtn;
}
- (void)pushPlayerview{
    PlayerViewController *playerVC = [PlayerViewController sharedInstance];
    [self.navigationController pushViewController:playerVC animated:YES];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.listTable reloadData];
}
- (void)loadData:(NSNotification*)notify{
    NSLog(@"%@",notify.userInfo);
    GKWYMusicModel *model = (GKWYMusicModel*)notify.userInfo;
    self.currentModel = model;
    [self loaddata];
}
- (GKWYMusicModel*)currentModel{
    if (!_currentModel) {
        _currentModel = [[GKWYMusicModel alloc]init];
    }
    return _currentModel;
}
- (void)loaddata{
    self.listArray = [GKWYMusicTool localMusicList];
    [self.listArray enumerateObjectsUsingBlock:^(GKWYMusicModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.musicPath isEqualToString:self.currentModel.musicPath]) {
            obj.isPlaying = YES;
            *stop = YES;
        }
    }];
    [self.listTable reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.listTable.refreshControl endRefreshing];
    });
}
- (NSArray*)listArray{
    if (!_listArray) {
        _listArray = [NSMutableArray arrayWithCapacity:10];
    }
    return _listArray;
}
- (UITableView*)listTable{
    if (!_listTable) {
        _listTable = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _listTable.delegate = self;
        _listTable.dataSource = self;
        _listTable.rowHeight = 54;
         UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
        refreshControl.tintColor = [UIColor redColor];
        refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:@"刷新"];
        [refreshControl addTarget:self action:@selector(loaddata) forControlEvents:UIControlEventValueChanged];
        _listTable.refreshControl = refreshControl;
        [_listTable registerClass:[GKWYMusicListCell class] forCellReuseIdentifier:kWYMusicListCellID];
    }
    return _listTable;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.listArray.count;
}
- (UITableViewCell* )tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    GKWYMusicListCell *cell = [tableView dequeueReusableCellWithIdentifier:kWYMusicListCellID forIndexPath:indexPath];
    cell.row   = indexPath.row;
    
    cell.model = self.listArray[indexPath.row];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    PlayerViewController *playvc = [PlayerViewController sharedInstance];
    [playvc playWithIndex:indexPath.row withList:self.listArray];
    [self.navigationController pushViewController:playvc animated:YES];
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSLog(@"indexPath--%ld",indexPath.row);
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        BOOL isdelet = [GKWYMusicTool deletMusicWithModel:self.listArray[indexPath.row]];
        if (isdelet) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"删除成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [self loaddata];
        }
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

