//
//  RemoteControlView.m
//  eLife
//
//  Created by 陈杰 on 15/5/22.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "RemoteControlView.h"
#import "NetAPIClient.h"

@interface RemoteControlView ()
{
    IBOutlet UILabel *nameLabel;
    IBOutlet UIActivityIndicatorView *indicator;
    IBOutlet UIView *displayView;
    IBOutlet UIView *keyboardView;
    IBOutlet UIView *bottomView;
    IBOutlet UIButton *keyboardBtn;
    
    BOOL hideKeyboard;
}

@end

@implementation RemoteControlView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.view bringSubviewToFront:bottomView];
    
    hideKeyboard = YES;
    [self setHideKeyboard:hideKeyboard animated:NO];
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

- (void)setHideKeyboard:(BOOL)yesOrNo animated:(BOOL)animated
{
    keyboardView.hidden = NO;
    
    CGRect frame = self.view.frame;
    NSInteger keyboardH = CGRectGetHeight(keyboardView.bounds);
    
    
    if (yesOrNo) {
        frame.size.height = CGRectGetHeight(frame) - keyboardH;
        frame.origin.y += keyboardH;
        
        [keyboardBtn setTitle:@"显示数字键盘" forState:UIControlStateNormal];
    }
    else {
        frame.size.height = CGRectGetHeight(frame) + keyboardH;
        frame.origin.y -= keyboardH;
        
        [keyboardBtn setTitle:@"隐藏数字键盘" forState:UIControlStateNormal];
    }
    
    CGRect bottomViewFrame = bottomView.frame;
    bottomViewFrame.origin.y = frame.size.height - CGRectGetHeight(bottomViewFrame);
    bottomView.frame = bottomViewFrame;
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.view.frame = frame;
            
        }completion:^(BOOL f){
           
            keyboardView.hidden = yesOrNo;
            
        }];
    }
    else {
        self.view.frame = frame;
    }


}

- (IBAction)showOrHideKeyboard:(UIButton *)sender
{
    hideKeyboard = !hideKeyboard;
    
    [self setHideKeyboard:hideKeyboard animated:YES];
    
}

- (IBAction)ctrlSTU:(id)sender
{
    [indicator startAnimating];
    
    NSString *keyName = [(SHInfraredRemoteControlState *)self.device.state STUOn] ? @"STUOff" : @"STUOn";
    
    [[NetAPIClient sharedClient] remoteControl:(SHInfraredRemoteControl *)self.device key:keyName successCallback:^{
        
        [indicator stopAnimating];
        
        ((SHInfraredRemoteControlState *)self.device.state).STUOn = !((SHInfraredRemoteControlState *)self.device.state).STUOn;
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)ctrlTV:(id)sender
{
    [indicator startAnimating];
    
    NSString *keyName = [(SHInfraredRemoteControlState *)self.device.state STUOn] ? @"TVOff" : @"TVOn";
    
    [[NetAPIClient sharedClient] remoteControl:(SHInfraredRemoteControl *)self.device key:keyName successCallback:^{
        
        [indicator stopAnimating];
        
         ((SHInfraredRemoteControlState *)self.device.state).TVOn = !((SHInfraredRemoteControlState *)self.device.state).TVOn;
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        
        [self showCtrlFailedHint];
    }];
}



- (IBAction)ctrlChannelPlus:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] remoteControl:(SHInfraredRemoteControl *)self.device key:@"Channel+" successCallback:^{
        
        [indicator stopAnimating];
        
        
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)ctrlChannelDec:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] remoteControl:(SHInfraredRemoteControl *)self.device key:@"Channel-" successCallback:^{
        
        [indicator stopAnimating];
        
        
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)ctrlVolumePlus:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] remoteControl:(SHInfraredRemoteControl *)self.device key:@"Volume+" successCallback:^{
        
        [indicator stopAnimating];
        
        
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)ctrlVolumeDec:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] remoteControl:(SHInfraredRemoteControl *)self.device key:@"Volume-" successCallback:^{
        
        [indicator stopAnimating];
        
        
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        
        [self showCtrlFailedHint];
    }];
}

@end
