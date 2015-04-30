//
//  FtpServerEditViewController.m
//  eLife
//
//  Created by mac on 14-9-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "FtpServerEditViewController.h"
#import "FtpResourceViewController.h"
#import "Util.h"
#import "DeviceData.h"


@interface FtpServerEditViewController ()
{
    IBOutlet UITextField *ipText;
    IBOutlet UITextField *portText;
    IBOutlet UITextField *userText;
    IBOutlet UITextField *pswdText;
    
    IBOutlet UIImageView *ipBgdView;
    IBOutlet UIImageView *portBgdView;
    IBOutlet UIImageView *userBgdView;
    IBOutlet UIImageView *pswdBgdView;
}

@end

@implementation FtpServerEditViewController

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
    // Do any additional setup after loading the view from its nib.
    
    
    [Util unifyStyleOfViewController:self withTitle:self.gateway.name];
    

    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    pswdBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    ipBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    portBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    userBgdView.image = [UIImage imageNamed:@"input_bgd.png"];
    
    ipText.text = self.gateway.addr;
    portText.text = @"21";
    userText.text = self.gateway.user;
    pswdText.text = self.gateway.pswd;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)connectServer:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[FtpResourceViewController class]];
    FtpResourceViewController *viewController = [[FtpResourceViewController alloc] initWithNibName:nibName bundle:nil];
    
//    [viewController setIp:ipText.text port:[portText.text intValue] user:[userText text] pswd:pswdText.text];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
