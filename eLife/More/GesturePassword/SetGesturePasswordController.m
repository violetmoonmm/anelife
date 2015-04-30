//
//  SetGesturePasswordController.m
//  eLife
//
//  Created by 陈杰 on 15/1/20.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "SetGesturePasswordController.h"
#import "User.h"
#import "Util.h"
#import "LLLockPassword.h"
#import "LLLCreatePasswordController.h"
#import "NotificationDefine.h"

#define CELL_H 44

@interface SetGesturePasswordController ()

@end

@implementation SetGesturePasswordController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    self.tableView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    
    self.tableView.backgroundView = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    [Util unifyStyleOfViewController:self withTitle:@"设置手势密码"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)goBack
{
    //[self.navigationController popViewControllerAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SetLockPasswordGobackNotification object:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    
    if (![LLLockPassword isEnableLockPassword] && section == 1) {
        return 0;
    }
    
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return 24;
    }
    
    return 0;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        UILabel *tipLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 24)];
        tipLbl.text = @"锁屏或退出应用后,重新打开需输入手势密码";
        tipLbl.backgroundColor = [UIColor clearColor];
        tipLbl.textColor = [UIColor grayColor];
        tipLbl.textAlignment = NSTextAlignmentCenter;
        tipLbl.font = [UIFont systemFontOfSize:15];
        
        return tipLbl;
    }
    
    
    return nil;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    for (UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    
    // Configure the cell...
    
    NSString *txt = nil;
    if (indexPath.section == 0) {
        txt = @"开启手势密码";
    }
    else {
        txt = @"重置手势密码";
    }
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 150, CELL_H)];
    lbl.text = txt;
    lbl.textColor = [UIColor blackColor];
    lbl.font = [UIFont boldSystemFontOfSize:15];
    [cell.contentView addSubview:lbl];
    
    if (indexPath.section == 0) {
        
        NSInteger switchWidth = 80;
        NSInteger switchHeight = 28;
        NSInteger rightMargin = 18;
        
        UISwitch *aswitch = [[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetWidth(tableView.bounds)-rightMargin-switchWidth, (CELL_H-switchHeight)/2, switchWidth, switchHeight)];
        aswitch.on = [LLLockPassword isEnableLockPassword]  ? YES : NO;
        [aswitch addTarget:self action:@selector(toggleGestPswd:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:aswitch];
    }
    
    return cell;
}

- (void)toggleGestPswd:(UISwitch *)sender
{

    [LLLockPassword setEnableLockPassword:sender.on];
    
    NSIndexPath *indx = [NSIndexPath indexPathForRow:0 inSection:1];
    
    if (sender.on) {
//        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationTop];
        

        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indx] withRowAnimation:UITableViewRowAnimationTop];
    }
    else {
//        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationBottom];
        
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indx] withRowAnimation:UITableViewRowAnimationTop];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        NSString *nibName = [Util nibNameWithClass:[LLLCreatePasswordController class]];
        
        LLLCreatePasswordController *vc = [[LLLCreatePasswordController alloc] initWithNibName:nibName bundle:nil];
        vc.viewType = LLLockViewTypeModify;
        
        [self.navigationController pushViewController:vc animated:YES];
    }

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
