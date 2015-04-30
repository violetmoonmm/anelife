//
//  GatewayListViewController.m
//  eLife
//
//  Created by mac on 14-8-13.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "FtpShareViewController.h"
#import "Util.h"
#import "User.h"
#import "NotificationDefine.h"
#import "NetAPIClient.h"

#import "FtpResourceViewController.h"
#import "FtpServerEditViewController.h"


#define DEFAULT_FTP_IP @"192.168.1.100"
#define FTP_IP @"ftp_ip"

#define CELL_H 44

#define BTN_TAG 100

@interface FtpShareViewController () <UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray *gatewayList;
    IBOutlet UITableView *tblView;
}

@end

@implementation FtpShareViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        gatewayList = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    
    [Util unifyStyleOfViewController:self withTitle:@"资源共享"];
    
 
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    

    [gatewayList addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
    
    
//    
//    //默认网关,远程ftp
//    if ([NetAPIClient sharedClient].serverAddr)
//    {
//        SHGateway *gateway = [[SHGateway alloc] init];
//        gateway.name = @"云服务器";
//        gateway.user = @"AppPanel";
//        gateway.pswd = @"Zwan!@#abc";
//
//        gateway.addr = [NetAPIClient sharedClient].serverAddr;
//        [gatewayList addObject:gateway];
//        
//    }
    
 
    
    tblView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    tblView.backgroundView = nil;
    
    [tblView reloadData];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"%@",NSStringFromCGRect(tblView.frame));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    tblView.delegate = nil;
    tblView.dataSource = nil;
}

- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}



- (void)editGateway:(UIButton*)sender
{
    NSInteger index = sender.tag - BTN_TAG;
    
    if ([gatewayList count]) {
        SHGateway *gateway = [gatewayList objectAtIndex:index];
        
        NSString *nibName = [Util nibNameWithClass:[FtpServerEditViewController class]];
        
        FtpServerEditViewController *vc = [[FtpServerEditViewController alloc] initWithNibName:nibName bundle:nil];
        vc.gateway = gateway;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_H;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [gatewayList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifier = @"gatewaylist";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    SHGateway *gateway = [gatewayList objectAtIndex:indexPath.row];
    
    //网关名
    NSString *titleTxt = gateway.name;
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 16);
    CGSize size = [titleTxt sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(200, 30)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, (CELL_H-size.height)/2, size.width, size.height)];
    titleLabel.text = titleTxt;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.highlightedTextColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [cell.contentView addSubview:titleLabel];
    
//    //ip
//    NSString *detailTxt = gateway.addr;
//    NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 4 : 4);
//    fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13: 13);
//    size = [detailTxt sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(200, 24)];
//    UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(titleLabel.frame)+spacingY, size.width, size.height)];
//    detailLabel.text = detailTxt;
//    detailLabel.textColor = [UIColor blackColor];
//    detailLabel.highlightedTextColor = [UIColor whiteColor];
//    detailLabel.backgroundColor = [UIColor clearColor];
//    detailLabel.font = [UIFont systemFontOfSize:fontSize];
//    [cell.contentView addSubview:detailLabel];
    
  
//    NSInteger btnH = 40;
//    NSInteger btnW = 40;
//    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    editBtn.frame  = CGRectMake(CGRectGetWidth(tblView.frame)-btnW-30, (CELL_H-btnH)/2, btnW, btnH);
//    [editBtn setImage:[UIImage imageNamed:@"pen"] forState:UIControlStateNormal];
//    [editBtn addTarget:self action:@selector(editGateway:) forControlEvents:UIControlEventTouchUpInside];
//    editBtn.tag = BTN_TAG + indexPath.row;
//    [cell.contentView addSubview:editBtn];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SHGateway *gateway = [gatewayList objectAtIndex:indexPath.row];
    
    NSString *nibName = [Util nibNameWithClass:[FtpResourceViewController class]];
    FtpResourceViewController *viewController = [[FtpResourceViewController alloc] initWithNibName:nibName bundle:nil];
    viewController.gateway = gateway;
   // [viewController setIp:gateway.addr port:21 user:gateway.user pswd:gateway.pswd];
    
    [self.navigationController pushViewController:viewController animated:YES];
}


@end
