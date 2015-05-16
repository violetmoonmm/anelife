//
//  QRCodeEncoderViewController.m
//  eLife
//
//  Created by 陈杰 on 15/5/16.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "QRCodeEncoderViewController.h"
#import "QREncoder.h"
#import "DataMatrix.h"
#import "Util.h"

@interface QRCodeEncoderViewController ()

@end

@implementation QRCodeEncoderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [Util unifyStyleOfViewController:self withTitle:@"授权二维码"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    //the qrcode is square. now we make it 250 pixels wide
    int qrcodeImageDimension = 250;
    
    //the string can be very long
    NSString* aVeryLongURL = @"http://thelongestlistofthelongeststuffatthelongestdomainnameatlonglast.com/";
    
    //first encode the string into a matrix of bools, TRUE for black dot and FALSE for white. Let the encoder decide the error correction level and version
    DataMatrix* qrMatrix = [QREncoder encodeWithECLevel:QR_ECLEVEL_AUTO version:QR_VERSION_AUTO string:aVeryLongURL];
    
    //then render the matrix
    UIImage* qrcodeImage = [QREncoder renderDataMatrix:qrMatrix imageDimension:qrcodeImageDimension];
    
    //put the image into the view
    UIImageView* qrcodeImageView = [[UIImageView alloc] initWithImage:qrcodeImage];
    CGRect parentFrame = self.view.frame;

    //center the image
    CGFloat x = (parentFrame.size.width - qrcodeImageDimension) / 2.0;
    CGFloat y = (parentFrame.size.height - qrcodeImageDimension) / 2.0;
    CGRect qrcodeImageViewFrame = CGRectMake(x, y, qrcodeImageDimension, qrcodeImageDimension);
    [qrcodeImageView setFrame:qrcodeImageViewFrame];
    
    //and that's it!
    [self.view addSubview:qrcodeImageView];

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

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
