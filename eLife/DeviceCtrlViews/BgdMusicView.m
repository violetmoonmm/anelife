//
//  BgdMusicView.m
//  eLife
//
//  Created by mac on 14-7-16.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BgdMusicView.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "NotificationDefine.h"

@implementation BgdMusicView
{
    IBOutlet UISlider *volumeSlider;
    
    IBOutlet UILabel *nameLbl;
    
    IBOutlet UIButton *onBtn;
    IBOutlet UIButton *offBtn;
    IBOutlet UIButton *playBtn;
    
    IBOutlet UIActivityIndicatorView *indicator;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [volumeSlider setMaximumTrackImage:[UIImage imageNamed:@"SliderGray"] forState:UIControlStateNormal];
    [volumeSlider setMinimumTrackImage:[UIImage imageNamed:@"SliderGreen"] forState:UIControlStateNormal];
    [volumeSlider setThumbImage:[UIImage imageNamed:@"SliderThumb"] forState:UIControlStateNormal];
    
    
    volumeSlider.continuous = NO;
}


- (void)dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


- (void)setDevice:(SHDevice *)device
{
    
    [super setDevice:device];
    
    if (device.name) {
        nameLbl.text = device.name;
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
    
    
    [volumeSlider setValue:[(SHBgdMusicState *)self.device.state volume] animated:NO];
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


- (IBAction)setVolume:(UISlider *)sender
{
    float volume = [(UISlider *)sender value];
    
    volume = floorf(volume+0.5);//四舍五入
    
    
    [[NetAPIClient sharedClient] bgdMusicSetVolume:self.device volume:volume successCallback:^{
        
        NSLog(@"bgdMusic %@ SetVolume %f ok",self.device.serialNumber,volume);
        
    }failureCallback:^{
        NSLog(@"bgdMusic %@ SetVolume %f failed",self.device.serialNumber,volume);
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)playNext:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] bgdMusicPlayNext:self.device successCallback:^{
        [indicator stopAnimating];
    }failureCallback:^{
        [indicator stopAnimating];
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)playLast:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] bgdMusicPlayLast:self.device successCallback:^{
        [indicator stopAnimating];
    }failureCallback:^{
        [indicator stopAnimating];
        
        [self showCtrlFailedHint];
    }];
}

- (IBAction)play:(id)sender
{
    [indicator startAnimating];
    
    if([[(SHBgdMusicState *)self.device.state playState] isEqualToString:@"Play"])
    {
        [[NetAPIClient sharedClient] bgdMusicPause:self.device successCallback:^{
            [indicator stopAnimating];
            
            [playBtn setImage:[UIImage imageNamed:@"MusicPlay"] forState:UIControlStateNormal];
            
        }failureCallback:^{
            [indicator stopAnimating];
            
            [self showCtrlFailedHint];
        }];
    }
    else {
        [[NetAPIClient sharedClient] bgdMusicResume:self.device successCallback:^{
            [indicator stopAnimating];
            
            [playBtn setImage:[UIImage imageNamed:@"MusicPause"] forState:UIControlStateNormal];
        }failureCallback:^{
            [indicator stopAnimating];
            
            [self showCtrlFailedHint];
        }];
    }

}

@end
