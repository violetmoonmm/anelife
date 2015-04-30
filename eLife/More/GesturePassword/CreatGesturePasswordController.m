//
//  CreatGesturePasswordController.m
//  eLife
//
//  Created by 陈杰 on 15/1/20.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "CreatGesturePasswordController.h"
#import "Util.h"

#import "LLLCreatePasswordController.h"

@interface CreatGesturePasswordController ()

@end

@implementation CreatGesturePasswordController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    [Util unifyStyleOfViewController:self withTitle:@"创建手势密码"];
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

- (IBAction)creatGesturePassword:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[LLLCreatePasswordController class]];
    LLLCreatePasswordController *vc = [[LLLCreatePasswordController alloc] initWithNibName:nibName bundle:nil];
    vc.viewType = LLLockViewTypeCreate;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
