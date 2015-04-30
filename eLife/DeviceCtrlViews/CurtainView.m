//
//  CurtainView.m
//  eLife
//
//  Created by mac on 14-10-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "CurtainView.h"
#include "NetAPIClient.h"
#import "MBProgressHUD.h"

@interface CurtainView ()
{
    IBOutlet UISlider *slider;
    IBOutlet UILabel *nameLabel;
    IBOutlet UILabel *openLabel;
    IBOutlet UILabel *closeLabel;
    
    
    IBOutlet UIButton *openBtn;
    IBOutlet UIButton *closeBtn;
    IBOutlet UIButton *stopBtn;

    
    IBOutlet UIActivityIndicatorView *indicator;
}

@end


@implementation CurtainView
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [slider setMaximumTrackImage:[UIImage imageNamed:@"SliderGray"] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage imageNamed:@"SliderGreen"] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage imageNamed:@"SliderThumb"] forState:UIControlStateNormal];
    
    
    slider.continuous = NO;
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
  

    id components = device.range;
    if ([components isKindOfClass:[NSArray class]]) {
        if ([components count] == 2) {//可调行程窗帘
            
            openLabel.hidden = NO;
            slider.hidden = NO;
            closeLabel.hidden = NO;
            
            
            NSInteger min = self.device.minRange;
            NSInteger max = self.device.maxRange;
            
            int currentValue = [(SHCurtainState *)self.device.state shading];
          
            if (currentValue > max) {
                currentValue = max;
            }
            
            if (currentValue < min) {
                currentValue = min;
            }
            
            slider.maximumValue = max;
            slider.minimumValue = min;
            slider.value = currentValue;
            
            
        }
    }
    else {
        openLabel.hidden = YES;
        slider.hidden = YES;
        closeLabel.hidden = YES;
        

    }


}


- (void)displayDeviceStatus
{
    
    [slider setValue:[(SHCurtainState *)self.device.state shading] animated:NO];
}

- (IBAction)ChangeValue:(id)sender
{
    float shading = [(UISlider *)sender value];
    
    NSLog(@"slider value :%f",shading);
    
    shading = floorf(shading+0.5);//四舍五入
    
    NSLog(@"curtain %@ SetShading %f",self.device.serialNumber,shading);
    
    [[NetAPIClient sharedClient] curtainSetShading:self.device level:shading successCallback:^{
        
        NSLog(@"curtain %@ SetShading %f ok",self.device.serialNumber,shading);
        
    }failureCallback:^{
        NSLog(@"curtain %@ SetShading %f failed",self.device.serialNumber,shading);
        
        [self showCtrlFailedHint];
    }];
}


- (IBAction)onCurtainOpen:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] setPowerOn:self.device successCallback:^{
        [indicator stopAnimating];
        
        NSLog(@"curtainOpen %@ ok",self.device.serialNumber);
    }failureCallback:^{
        
        [indicator stopAnimating];
        
        NSLog(@"curtainOpen %@ failed",self.device.serialNumber);
        
        [self showCtrlFailedHint];
    }];
}


- (IBAction)onCurtainClose:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] setPowerOff:self.device successCallback:^{
        NSLog(@"curtainClose %@ ok",self.device.serialNumber);
        
        [indicator stopAnimating];
    }failureCallback:^{
        NSLog(@"curtainClose %@ failed",self.device.serialNumber);
        
        [indicator stopAnimating];
        
        [self showCtrlFailedHint];
    }];
}


- (IBAction)onCurtainStop:(id)sender
{
    [indicator startAnimating];
    
    [[NetAPIClient sharedClient] curtainStop:self.device successCallback:^{
        NSLog(@"curtainStop %@ ok",self.device.serialNumber);
        
        [indicator stopAnimating];
    }failureCallback:^{
        NSLog(@"curtainStop %@ failed",self.device.serialNumber);
        [indicator stopAnimating];
        
        [self showCtrlFailedHint];
    }];
}



@end
