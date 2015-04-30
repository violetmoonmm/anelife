//
//  MoreViewController.m
//  eLife
//
//  Created by mac on 14-3-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "MoreViewController.h"
#import "NetAPIClient.h"
#import "AppDelegate.h"
#import "LoginViewController.h"
#import "User.h"
#import "MBProgressHUD.h"
#import "AboutViewController.h"
#import "PublicDefine.h"
#import "DotView.h"
#import "UserInfoViewController.h"
#import "Util.h"
#import "SettingViewController.h"
#import "GatewayListViewController.h"

#define REQ_TIMEOUT 10

#define CELL_CONTENT_ORIGIN_Y 10
#define CELL_CONTENT_ORIGIN_X 10

#define INDICATOR_H 16
#define INDICATOR_W 16

#define TAG_INDICATOR 100//向上向下箭头

#define TAG_STATUS 200//显示网关在线状态

#define TAG_GATEWAY_NUM 300//显示网关总数

#define USER_VIEW_HEIGHT (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 60 : 84)
#define DEFAULT_CELL_HEIGHT (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 44 : 60)
#define CELL_WIDTH  (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 300 : 768)

@interface MoreViewController ()
{
    IBOutlet UITableView *_tblView;

    MBProgressHUD *_hud;
    
    BOOL _expand;//网关视图是否展开
    
    
    BOOL _reqFin;//获取网关以及网关状态完成
    
    BOOL _haveViewAbout;//已经点击过关于了，取消红点
    
    DotView *_dotView;
    
    NSMutableArray *_gateways;
    
    UIImageView *_upDownArr;//上下指示箭头
}



@end

@implementation MoreViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        _gateways = [NSMutableArray arrayWithCapacity:1];
        
//         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGetGatewayListNtf:) name:GetGatewayListNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [Util unifyStyleOfViewController:self withTitle:@"更多"];
    

    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    _tblView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    
    _tblView.backgroundView = nil;

}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    
    if ([Util clientIsLastVersion] || _haveViewAbout) {
        [_dotView removeFromSuperview];
    }
    
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    [navController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//- (void)handleGetGatewayListNtf:(NSNotification *)ntf
//{
//    
//    //NSLog(@"more view handleGetGatewayListNtf");
//    
//    if (_reqFin) {
//        return;
//    }
//    
//    _reqFin = YES;
//    
//
//    [_gateways removeAllObjects];
//    [_gateways addObjectsFromArray:[NetAPIClient sharedClient].gatewayList];
//    
//    [_tblView reloadData];
//    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
//    
//    if (_hud) {
//        [_hud hide:YES];
//        _hud = nil;
//    }
//    
//}
//
//- (void)showWaitingStatus
//{
//    
//    _hud = [[MBProgressHUD alloc] initWithView:self.view];
//    [self.view addSubview:_hud];
//    _hud.removeFromSuperViewOnHide = YES;
//   
//    _hud.mode = MBProgressHUDModeIndeterminate;
//    
//    [_hud show:YES];
//    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:REQ_TIMEOUT];
//}
//
////显示获取网关列表超时
//- (void)reqTimeout
//{
//    _hud.mode = MBProgressHUDModeText;
//	_hud.labelText = @"请求超时!";
//    
//    [_hud hide:YES afterDelay:1.5];
//    
//    _hud = nil;
//}




//查看设置
- (void)viewSetting
{
    NSString *nibName = [Util nibNameWithClass:[SettingViewController class]];
    SettingViewController *vc = [[SettingViewController alloc] initWithNibName:nibName bundle:nil];
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    [navController pushViewController:vc animated:YES];
    
    _haveViewAbout = YES;
    [(CustomTabBarController *)((AppDelegate *)[UIApplication sharedApplication].delegate).tabBarController displayTrackPoint:NO atIndex:3];
}

//用户信息
- (void)showUserInfo
{
    NSString *nibName = [Util nibNameWithClass:[UserInfoViewController class]];
    UserInfoViewController *viewController = [[UserInfoViewController alloc] initWithNibName:nibName bundle:nil];
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    
    [navController setNavigationBarHidden:NO];
    [navController pushViewController:viewController animated:YES];
    
}

- (void)enterGatewayList
{
    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
    NSString *nibName = [Util nibNameWithClass:[GatewayListViewController class]];
    
    GatewayListViewController *viewController = [[GatewayListViewController alloc] initWithNibName:nibName bundle:nil];
    
    [navController setNavigationBarHidden:NO];
    [navController pushViewController:viewController animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (0 == indexPath.section) {
        return USER_VIEW_HEIGHT;
    }
//    else if (1 == indexPath.section) {
//        return 44;
//    }
//    else {
//        if (0 == indexPath.row) {
//            <#statements#>
//        }
//    }
    return DEFAULT_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    for (UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    
    cell.selectionStyle = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleBlue;
    
    if (0 == indexPath.section) {
        //头像
        NSInteger imgMargin = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 3 : 10);
        UIImageView *profileView = [[UIImageView alloc] initWithFrame:CGRectMake(imgMargin, imgMargin, USER_VIEW_HEIGHT-2*imgMargin, USER_VIEW_HEIGHT-2*imgMargin)];
        profileView.image = [UIImage imageNamed:@"LoginProfile"];
        [cell.contentView addSubview:profileView];
        
        
        NSInteger nameHeight = 24;
        NSInteger vcHeight = 24;
        NSInteger spacingY = (USER_VIEW_HEIGHT-nameHeight-vcHeight)/2;
        
        //用户名
        NSInteger nameFontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 15 : 18);
        UIFont *nameFont = [UIFont systemFontOfSize:nameFontSize];
        CGSize size = [[User currentUser].name sizeWithFont:nameFont constrainedToSize:CGSizeMake(200, vcHeight)];
        UILabel *userLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(profileView.frame)+8, spacingY, size.width, nameHeight)];
        userLbl.text = [User currentUser].name;
        userLbl.highlightedTextColor = [UIColor whiteColor];
        userLbl.font = nameFont;
        userLbl.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:userLbl];
        
        //城市
        NSInteger fontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 15 : 18);
        UIFont *cityFont = [UIFont systemFontOfSize:fontSize];
        size = [[User currentUser].city sizeWithFont:cityFont constrainedToSize:CGSizeMake(200, USER_VIEW_HEIGHT)];
        UILabel *cityLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(userLbl.frame), CGRectGetMaxY(userLbl.frame), size.width, vcHeight)];
        cityLbl.text = [User currentUser].city;
        cityLbl.highlightedTextColor = [UIColor whiteColor];
        cityLbl.font = cityFont;
        cityLbl.backgroundColor = [UIColor clearColor];
        cityLbl.textColor = [UIColor darkGrayColor];
        [cell.contentView addSubview:cityLbl];
        
        //右箭头
        UIImageView *rightArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Userguide_enter_icon.png"]];
        rightArrow.frame = CGRectMake(0, 0, 20, 20);
        rightArrow.backgroundColor = [UIColor clearColor];
        cell.accessoryView = rightArrow;
    }
    else if (indexPath.section == 1) {
        
        NSInteger fontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 16 : 18);
        UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
        NSString *text = @"家居网关";
        CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(200, 30)];
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, (DEFAULT_CELL_HEIGHT-size.height)/2, size.width, size.height)];
        lbl.text = text;
        lbl.highlightedTextColor = [UIColor whiteColor];
        lbl.font = font;
        lbl.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:lbl];
        
        //右箭头
        UIImageView *rightArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Userguide_enter_icon.png"]];
        rightArrow.frame = CGRectMake(0, 0, 20, 20);
        rightArrow.backgroundColor = [UIColor clearColor];
        cell.accessoryView = rightArrow;
    }
    else {
        NSInteger fontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 16 : 18);
        UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
        NSString *text = @"设置";
        CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(200, 30)];
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, (DEFAULT_CELL_HEIGHT-size.height)/2, size.width, size.height)];
        lbl.text = text;
        lbl.highlightedTextColor = [UIColor whiteColor];
        lbl.font = font;
        lbl.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:lbl];
        
        //右箭头
        UIImageView *rightArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Userguide_enter_icon.png"]];
        rightArrow.frame = CGRectMake(0, 0, 20, 20);
        rightArrow.backgroundColor = [UIColor clearColor];
        cell.accessoryView = rightArrow;
        
        //红点
        if (![Util clientIsLastVersion] && !_haveViewAbout) {
            _dotView = [[DotView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(lbl.frame)+10, (DEFAULT_CELL_HEIGHT-10)/2, 10, 10)];
            _dotView.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:_dotView];
        }
        

    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0:

            [self showUserInfo];
            break;
       
        case 1:
            
            [self enterGatewayList];
            break;
            
        case 2:

            [self viewSetting];
            break;
        default:
            break;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}


@end
