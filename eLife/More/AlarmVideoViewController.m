//
//  AlarmVideoViewController.m
//  eLife
//
//  Created by 陈杰 on 15/5/12.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "AlarmVideoViewController.h"
#import "User.h"
#import "Util.h"
#import "UserDBManager.h"

#define CELL_H 44

@interface AlarmVideoViewController ()

@end

@implementation AlarmVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [Util unifyStyleOfViewController:self withTitle:@"联动视频"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifier = @"alarmsetting";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    NSString *txt = nil;
    switch (indexPath.row) {
        case 0:
            txt = @"2G/3G/4G和WiFi下开启视频";
            break;
        case 1:
            txt = @"仅WiFi下开启视频";
            break;
        case 2:
            txt = @"不联动";
            break;
            
        default:
            break;
    }

    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 220, CELL_H)];
    lbl.text = txt;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor blackColor];
    lbl.font = [UIFont boldSystemFontOfSize:15];
    [cell.contentView addSubview:lbl];
    
    
    if (indexPath.row == [User currentUser].alarmVideo)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
    
    //自定义分割线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CELL_H-1, CGRectGetWidth(tableView.frame), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.2;
    [cell.contentView addSubview:sep];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    

    [User currentUser].alarmVideo = indexPath.row;
    [[UserDBManager defaultManager] updateUser:[User currentUser]];
    
    [tableView reloadData];
    
    [self goBack];
}


@end
