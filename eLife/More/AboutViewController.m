//
//  AboutViewController.m
//  eLife
//
//  Created by mac on 14-6-25.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "AboutViewController.h"
#import "NetAPIClient.h"
#import "DotView.h"
#import "PublicDefine.h"
#import "Util.h"
#import "ServiceContractViewController.h"

@interface AboutViewController () <UIAlertViewDelegate,UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UITableView *tblView;
    IBOutlet UILabel *versionLbl;
    IBOutlet UILabel *buildLbl;
    IBOutlet UILabel *copyRight;
}

@end

@implementation AboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    

    [Util unifyStyleOfViewController:self withTitle:@"关于"];
    

    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    //版本
    //versionLbl.textColor = [UIColor lightGrayColor];
 
    versionLbl.text = [NSString stringWithFormat:@"v%@",CLIENT_VERSION];
  
    buildLbl.text = [NSString stringWithFormat:@"build %s",__DATE__];
    
    //copyRight.textColor = [UIColor lightGrayColor];
//    copyRight.shadowColor = [UIColor whiteColor];
//    copyRight.shadowOffset = CGSizeMake(0, 1);
    

    tblView.backgroundView = nil;
    tblView.backgroundColor = [UIColor clearColor];
    tblView.scrollEnabled = NO;
    [tblView reloadData];
    
    
    //self.view.backgroundColor = [UIColor colorWithRed:179/255. green:179/255. blue:179/255. alpha:1];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AboutCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    for (UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    
    
    //右箭头
    UIImageView *rightArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Userguide_enter_icon.png"]];
    rightArrow.frame = CGRectMake(0, 0, 20, 20);
    rightArrow.backgroundColor = [UIColor clearColor];
    cell.accessoryView = rightArrow;

    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
    
    if (0 == indexPath.row) {
        cell.textLabel.text = @"使用帮助";
    }
    else if (1 == indexPath.row) {
        cell.textLabel.text = @"意见反馈";
    }
    else if (2 == indexPath.row) {
        cell.textLabel.text = @"服务使用协议";
    }
//    else {
//        cell.textLabel.text = @"版本更新";
//        
//        
//        if (![Util clientIsLastVersion]) {//提示更新
//            UIFont *font = [UIFont systemFontOfSize:14];
//            NSString *text = @"有新版本可用";
//            CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(120, 44)];
//            UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(rightArrow.frame)-size.width-8, (44-size.height)/2, size.width, size.height)];
//            info.font = font;
//            info.text = text;
//            info.textColor = [UIColor grayColor];
//            info.backgroundColor = [UIColor clearColor];
//            [cell.contentView addSubview:info];
//        }
//    }
    

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tblView deselectRowAtIndexPath:indexPath animated:YES];

    if (2 == indexPath.row) {
        NSString *nibName = [Util nibNameWithClass:[ServiceContractViewController class]];
        ServiceContractViewController *vc = [[ServiceContractViewController alloc] initWithNibName:nibName bundle:nil];
        vc.registering = NO;
        [self.navigationController pushViewController:vc animated:YES];
    }
//    else if (3 == indexPath.row) {
//        if ([Util clientIsLastVersion]) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"当前版本已经是最新！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
//            [alert show];
//        }
//        else {
//            VersionInfo *versionInfo = [NetAPIClient sharedClient].versionInfo;
//            NSString *title = [NSString stringWithFormat:@"新版本%@",versionInfo.versionName];
//            
//            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//            [formatter setDateFormat:@"YYYY年MM月dd日"];
//            NSString *strDate = [formatter stringFromDate:versionInfo.publishDate];
//            
//            NSString *msg = [NSString stringWithFormat:@"发布日期:%@",strDate];
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"前往下载", nil];
//            [alert show];
//        }
//    }

}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"前往下载"]) {
        
  
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:APP_URL]];
        
    }
    else {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    }
}

@end
