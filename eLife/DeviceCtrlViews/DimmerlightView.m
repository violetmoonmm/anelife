//
//  DimmerlightView.m
//  eLife
//
//  Created by mac on 14-7-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "DimmerlightView.h"
#import "NotificationDefine.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"

@implementation DimmerlightView
{
    IBOutlet UISlider *brightnessSlider;

    IBOutlet UILabel *nameLabel;
    
    IBOutlet UIButton *onBtn;
    IBOutlet UIButton *offBtn;
  
    
     IBOutlet UIActivityIndicatorView *indicator;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [brightnessSlider setMaximumTrackImage:[UIImage imageNamed:@"SliderGray"] forState:UIControlStateNormal];
    [brightnessSlider setMinimumTrackImage:[UIImage imageNamed:@"SliderGreen"] forState:UIControlStateNormal];
    [brightnessSlider setThumbImage:[UIImage imageNamed:@"SliderThumb"] forState:UIControlStateNormal];
    
    
    brightnessSlider.continuous = NO;
    
}

- (void)dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self];

}





- (void)setDevice:(SHDevice *)device
{

    [super setDevice:device];
    
    if (device.name) {
        nameLabel.text = device.name;
    }
    

}



- (void)displayDeviceStatus
{
    
    if (self.device.state.powerOn) {
        onBtn.selected = YES;
        offBtn.selected = NO;
    }
    else {
        onBtn.selected = NO;
        offBtn.selected = YES;
    }
    

    [brightnessSlider setValue:[(SHDimmerLightState *)self.device.state brightness] animated:NO];
}




- (IBAction)turnOn:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] setPowerOn:self.device successCallback:^{
        [indicator stopAnimating];
    }failureCallback:^{
        [indicator stopAnimating];
        
         [self showCtrlFailedHint];
    }];

}


- (IBAction)turnOff:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] setPowerOff:self.device successCallback:^{
        [indicator stopAnimating];
        
    }failureCallback:^{
        [indicator stopAnimating];
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)lightSetBrightness:(UISlider *)sender
{
    
    int brightness = sender.value;
    NSLog(@"brightness %d",brightness);
    
    [[NetAPIClient sharedClient] lightSetBrightness:self.device level:brightness successCallback:^{
        
//        brightnessLbl.text = [NSString stringWithFormat:@"%d",brightness];
        
        NSLog(@"light id: %@ SetBrightness %d success",self.device.serialNumber,brightness);
        
    }failureCallback:^{
         NSLog(@"light id: %@ SetBrightness %d failed",self.device.serialNumber,brightness);
        
        [self showCtrlFailedHint];
    }];
    
}






@end
