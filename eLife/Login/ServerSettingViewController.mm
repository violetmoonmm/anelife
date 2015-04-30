//
//  ServerSettingViewController.m
//  eLife
//
//  Created by mac on 14-3-31.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ServerSettingViewController.h"
#import "NetAPIClient.h"
#import "Util.h"

@interface ServerSettingViewController ()
{
    IBOutlet UITextField *_ipText;
    IBOutlet UITextField *_portText;
    
    IBOutlet UIScrollView *_scrlView;
}

- (void)saveSetting;

@end

@implementation ServerSettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIImage *navImage = [UIImage imageNamed:@"navbar_bgd"];
    CGSize size = self.navigationController.navigationBar.frame.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
    [navImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:scaledImage forBarMetrics:UIBarMetricsDefault];
    
    self.title = @"服务器设置";
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame = CGRectMake(0, 0, 50, 30);
    [saveBtn addTarget:self action:@selector(saveSetting) forControlEvents:UIControlEventTouchUpInside];
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:saveBtn];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
    

    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack:)];


    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleKeyboardWillShow:(NSNotification *)ntf
{
    
//    scrlView.contentSize = scrlView.frame.size;
//    
//    
//    
//    NSDictionary *userInfo = [ntf userInfo];
//    NSValue *rectValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
//    CGRect keyboardRect = [rectValue CGRectValue];
//    NSInteger keyboardHeight = keyboardRect.size.height;
//    
//    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
//    
//    NSInteger spacing = CGRectGetHeight(scrlView.frame) - CGRectGetMaxY(authCodeBgdView.frame);
//    
//    NSInteger offY = keyboardHeight - spacing;
//    
//    
//    [scrlView setContentInset:UIEdgeInsetsMake(-offY, 0, keyboardHeight, 0)];
//    
//    if (offY > 0) {
//        
//        [UIView animateWithDuration:[duration floatValue] animations:^{
//            [scrlView setContentOffset:CGPointMake(0, offY)];
//            
//            
//        }completion:NULL];
//    }
    
}

- (void)handleKeyboardWillHide:(NSNotification *)ntf
{
//    NSDictionary *userInfo = [ntf userInfo];
//    NSNumber *duration = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
//    
//    scrlView.contentSize = CGSizeMake(0, 0);
//    scrlView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
//    
//    [UIView animateWithDuration:[duration floatValue] animations:^{
//        [scrlView setContentOffset:CGPointMake(0, 0)];
//        
//        
//    }completion:NULL];
    
}

- (void)hideKeyboard
{
    if ([_ipText isFirstResponder]) {
        [_ipText resignFirstResponder];
    }
    if ([_portText isFirstResponder]) {
        [_portText resignFirstResponder];
    }
    
}

- (void)saveSetting
{
//    [NetAPIClient sharedClient].serverIP = _ipText.text;
//    [NetAPIClient sharedClient].serverPort = _portText.text;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)goBack:(UIButton *)sender
{
    [self saveSetting];
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

@end
