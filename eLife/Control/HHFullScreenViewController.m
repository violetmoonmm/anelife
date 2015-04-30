//
//  HHFullScreenViewController.m
//  Here
//
//  Created by here004 on 11-12-30.
//  Copyright (c) 2011年 Tian Tian Tai Mei Net Tech (Bei Jing) Lt.d. All rights reserved.
//

#import "HHFullScreenViewController.h"
#define DEGREES_TO_RADIANS(d) (d * M_PI / 180)


#import <QuartzCore/QuartzCore.h>

static CATransform3D CATransform3DMakePerspective(CGFloat z) {
    CATransform3D t = CATransform3DIdentity;
    t.m34 = - 1.0 / z;
    return t;
}

@interface HHFullScreenViewController() {
}
-(void)changeImgView:(UIImageView *)orgImage;
- (void)fullSrceen:(CALayer *)layer ;
@end

@implementation HHFullScreenViewController
@synthesize fromView,toView;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        isHorizontal = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)setShowImage:(UIImage *)image withOrgImage:(UIImage *)orgImage withX:(float)x withY:(float)y
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    CALayer *layer = [CALayer layer];
    //        layer.anchorPoint = CGPointMake(0.0, 0.0);
    layer.frame = CGRectMake(x, y, image.size.width, image.size.height);
    layer.backgroundColor = [UIColor redColor].CGColor;
    layer.borderColor = [UIColor blackColor].CGColor;
    layer.opacity = 1.0f;
    layer.contents = (id)[image CGImage];
    [self.view.layer addSublayer:layer];
    //[self performSelector:@selector(changeImgView:)  withObject:imageView   afterDelay:0.3];
    float k =  orgImage.size.width/orgImage.size.height;
    //float k =  image.size.width/image.size.height;
    
    isHorizontal = (k>1);
    if (k <= 1) {
        //竖屏的图片放大
        if (k <= 32.0/48.0) {
            _width = 320;
            _height = _width/k;
        } else {
            _height = 480;
            _width = _height*k;
        }
    } else {
        //横屏的图片旋转
        if (k < 48.0/32.0) {
            _height = 480;
            _width = _height/k;
        } else {
            _width = 320;
            _height = _width*k;
        }
    }
    [self performSelector:@selector(fullSrceen:)  withObject:layer   afterDelay:0.1];
    
}

-(void)changeImgView:(UIImageView *)imagesView
{
    [self.view addSubview:imagesView];
   
}
- (void)fullSrceen:(CALayer *)layer 
{
    CATransform3D transform;
    if(isHorizontal){
       transform = CATransform3DMakeRotation(-M_PI/2, 0.0,0.0,1.0);
    }else{
         transform = CATransform3DMakeRotation(0, 0.0,0.0,1.0);
    }
    layer.transform = transform;
    layer.frame =CGRectMake((320-_width)/2, (480-_height)/2, _width, _height);
    
    NSLog(@" [%f,%f]",_width,_height);
}

//-(void)setShowImage:(UIImage *)image withOrgImage:(UIImage *)orgImage withX:(float)x withY:(float)y
//{
//    NSLog(@"setShowImage %f %f",x,y);
//    
//    CALayer *layer =[[CALayer layer] retain];
//    layer.backgroundColor = [UIColor blackColor].CGColor;
//    layer.opacity = 1.0f;
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
//    layer.frame = CGRectMake(x, y, image.size.width, image.size.height);
//    layer.contents = (id)[image CGImage];
//            [self performSelector:@selector(fullSrceen:)  withObject:orgImage  afterDelay:0.3];
//    [self.view.layer addSublayer:layer];
//    [layer release];
//}

-(IBAction)viewDismiss:(id)sender
{
//    if (animationSyte == 1)
//    {
//        toView.center = cerr;
//        fromView.center = cerr;
//        [self.view bringSubviewToFront:toView];  
//        
//        float direction = 0;
//        if (translationX<0)
//        {
//            direction = -1;
//        }
//        
//        [self.fromView.layer addAnimation:[self getAnimation:scaleX toScaleX:1.0 fromScaleY:scaleY tofromScaleY:1.0 fromTranslationX:translationX toTranslationX:0.0 fromTranslationY:translationY toTranslationY:0.0 fromTranslationZ:0.0 toTranslationZ:2.0 fromRotation:direction * 180.0 toRotation:0.0 removedOnCompletion:YES] forKey:@"endfromView"];
//        [self.toView.layer addAnimation:[self getAnimation:1.0 toScaleX:1.0/scaleX fromScaleY:1.0 tofromScaleY:1.0/scaleY fromTranslationX:translationX toTranslationX:0.0 fromTranslationY:translationY toTranslationY:0.0 fromTranslationZ:0.0 toTranslationZ:1.0 fromRotation:direction * 360.0 toRotation:direction * 180.0 removedOnCompletion:NO] forKey:@"endtoView"];
//        [opacityLayer addAnimation:[self getOpacityAnimation:0.5
//                                                   toOpacity:0.0] forKey:@"opacity"];
//        animationSyte = 2;
//    }
    
    
    [UIView animateWithDuration:0.3 animations:^{
        
        fromView.frame = OriginalFrame;
        opacityLayer.opacity = 0.0;
        
    }completion:^(BOOL f){
        
    }];
    
}

- (void)dismiss
{
    NSLog(@"viewDismiss");
   [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    //self.view.layer.sublayers = nil;
    [self.view removeFromSuperview];
}



//- (void)fullSrceen:(CALayer *)layer rect:(CGRect)rect transform:(CATransform3D)transform {
//- (void)fullSrceen:(UIImage *)orgImage{
//    CALayer *superlayer = [[CALayer layer] retain];
//    superlayer.backgroundColor = [UIColor blackColor].CGColor;
//    superlayer.opacity = 1.0f;
//
//    _transform = CATransform3DMakeRotation(0, 0.0,0.0,1.0);
//    float k =  orgImage.size.width/orgImage.size.height;
//    float width,height;
//    if (k <= 1) {
//        //竖屏的图片放大
//        width = 320;
//        height = width/k;
//        superlayer.frame = CGRectMake(0 ,(480-height)/2, width, height);
//        superlayer.contents =(id)[orgImage CGImage];
//
//    } else {
//        //横屏的图片旋转
//        height = 480;
//        width = height/k;
//        UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,orgImage.size.width, orgImage.size.height)];
//        CGAffineTransform t = CGAffineTransformMakeRotation(M_PI/2);
//        rotatedViewBox.transform = t;
//        CGSize rotatedSize = rotatedViewBox.frame.size;
//        [rotatedViewBox release];
//        UIGraphicsBeginImageContext(rotatedSize);
//        CGContextRef bitmap = UIGraphicsGetCurrentContext();
//        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
//        CGContextRotateCTM(bitmap, -M_PI/2);
//        CGContextScaleCTM(bitmap, 1.0, -1.0);
//        CGContextDrawImage(bitmap, CGRectMake(-orgImage.size.width / 2, -orgImage.size.height / 2, orgImage.size.width, orgImage.size.height), [orgImage CGImage]);
//        
//        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        superlayer.frame = CGRectMake((320-width)/2,0,width,height);
//        superlayer.contents =(id)[newImage CGImage];
//    }
//     NSLog(@"super k[%f] [%f,%f]",k,width,height);
//    self.view.layer.sublayers = nil;
//    [self.view.layer addSublayer:superlayer];
//    self.view.layer.transform = _transform;    
//    [superlayer release];
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(100, 100, 100, 100);
    self.view.layer.sublayerTransform = CATransform3DMakePerspective(1000);
    //[self.view addSubview:button];
    
	
}

- (void)startAnimation
{
    CGRect bounds = [UIScreen mainScreen].bounds;
    CGRect toViewFrame = CGRectMake((CGRectGetWidth(bounds)-toViewSize.width)/2, (CGRectGetHeight(bounds)-toViewSize.height)/2, toViewSize.width, toViewSize.height);
    opacityLayer.opacity = 0;
    
    [UIView animateWithDuration:0.3 animations:^{

        fromView.frame = toViewFrame;
        opacityLayer.opacity = 1;
        
    }completion:^(BOOL f){
        fromView.hidden = YES;
        toView.frame = toViewFrame;
    }];
}


- (void)startFirstAnimation
{
    
   // [self.fromView.layer addAnimation:[self getAnimation:0 toValue:180 fromez:0 toz:10] forKey:@"fdsaf"];
    //[self.toView.layer addAnimation:[self getAnimation:180 toValue:360 fromez:0 toz:11] forKey:@"fdsafd"];
    float direction = 0;
    if (translationX<0)
    {
        direction = -1;
    }
    
    [self.fromView.layer addAnimation:[self getAnimation:1.0 toScaleX:scaleX fromScaleY:1.0 tofromScaleY:scaleY fromTranslationX:-translationX toTranslationX:0.0 fromTranslationY:-translationY toTranslationY:0.0 fromTranslationZ:0.0 toTranslationZ:1.0 fromRotation:0.0 toRotation:direction * 180.0 removedOnCompletion:YES] forKey:@"startfromView"];
    [self.toView.layer addAnimation:[self getAnimation:1.0/scaleX toScaleX:1.0 fromScaleY:1.0/scaleY tofromScaleY:1.0 fromTranslationX:-translationX toTranslationX:0.0 fromTranslationY:-translationY toTranslationY:0.0 fromTranslationZ:0.0 toTranslationZ:2.0 fromRotation:direction * 180.0 toRotation:direction * 360.0 removedOnCompletion:YES] forKey:@"starttoView"];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
    [opacityLayer addAnimation:[self getOpacityAnimation:0.0
                                            toOpacity:0.5] forKey:@"opacity"];
    animationSyte = 0;
}

- (void)setFromView:(UIView *)fView toView:(UIView *)tView withX:(float)x withY:(float)y
{

    
    
    OriginalFrame = fView.frame;
    superView = fView.superview;
    
    
    opacityLayer = [CALayer layer];
    opacityLayer.backgroundColor = [UIColor blackColor].CGColor;
    opacityLayer.frame = [UIScreen mainScreen].bounds;
    opacityLayer.opacity  = 0.0;
    opacityLayer.transform = CATransform3DScale(CATransform3DMakeTranslation(0.0,0.0,-200),2,2,1);
    [self.view.layer insertSublayer:opacityLayer atIndex:0];

    
    fromView = fView;
    fromViewSize = fView.frame.size;
    startX = x;
    startY = y;
    fromView.frame = CGRectMake(x, y, fView.frame.size.width, fView.frame.size.height);
    NSLog(@"%@",NSStringFromCGRect(fromView.frame));
   cerr = fView.center;
    toViewSize = tView.frame.size;
    self.toView = tView;
    //toView.frame = fromView.frame;
    fromView.center = self.view.center;
    toView.center = fromView.center;
    
    scaleX = toViewSize.width/fromViewSize.width;
    scaleY = toViewSize.height/fromViewSize.height;
    //toView.layer.transform = CATransform3DMakeScale(1.0/scaleX,1.0/scaleY,1);
    [self.view addSubview:toView];
    [self.view addSubview:fromView];
    
    
    
    translationX =  (320 - toViewSize.width)/2.0 - startX + (scaleX - 1) * (fromViewSize.width/2.0);
    translationY =  (480 - toViewSize.height)/2.0 - startY+ (scaleY - 1) * (fromViewSize.height/2.0);

    
    
   // [self.view.layer addSublayer:fromView.layer];
}



- (CAAnimation *)getOpacityAnimation:(CGFloat)fromOpacity
                           toOpacity:(CGFloat)toOpacity
{
    CABasicAnimation *pulseAnimationx = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulseAnimationx.duration = 1.0;
    pulseAnimationx.fromValue = [NSNumber numberWithFloat:fromOpacity];
    pulseAnimationx.toValue = [NSNumber numberWithFloat:toOpacity];
    
    pulseAnimationx.autoreverses = NO;
    pulseAnimationx.fillMode=kCAFillModeForwards;
    pulseAnimationx.removedOnCompletion = NO;
    pulseAnimationx.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    return pulseAnimationx;
    
}

- (CAAnimation *)getAnimation:(float)fromScaleX 
                     toScaleX:(float)toScaleX
                   fromScaleY:(float)fromScaleY
                 tofromScaleY:(float)toScaleY
              fromTranslationX:(float)fromTranslationX 
                toTranslationX:(float)toTranslationX 
             fromTranslationY:(float)fromTranslationY
               toTranslationY:(float)toTranslationY
             fromTranslationZ:(float)fromTranslationZ
               toTranslationZ:(float)toTranslationZ
                 fromRotation:(float)fromRotation
                   toRotation:(float)toRotation
          removedOnCompletion:(BOOL)isRemove
{
    
    CAAnimationGroup *anim;
    
    CABasicAnimation *pulseAnimationx = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    //  CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.z"];
    pulseAnimationx.duration = 1.0;
    pulseAnimationx.fromValue = [NSNumber numberWithFloat:fromScaleX];
    pulseAnimationx.toValue = [NSNumber numberWithFloat:toScaleX];
    
    CABasicAnimation *pulseAnimationy = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    //  CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.z"];
    pulseAnimationy.duration = 1.0;
    pulseAnimationy.fromValue = [NSNumber numberWithFloat:fromScaleY];
    pulseAnimationy.toValue = [NSNumber numberWithFloat:toScaleY];
    
    CABasicAnimation *translationx = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    translationx.duration = 1.0;
    translationx.fromValue = [NSNumber numberWithFloat:fromTranslationX];
    translationx.toValue = [NSNumber numberWithFloat:toTranslationX];
    
    CABasicAnimation *translationy = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    translationy.duration = 1.0;
    translationy.fromValue = [NSNumber numberWithFloat:fromTranslationY];
    translationy.toValue = [NSNumber numberWithFloat:toTranslationY];
    
    CABasicAnimation *pulseAnimationz = [CABasicAnimation animationWithKeyPath:@"transform.translation.z"];
    pulseAnimationz.duration = 1.0;
    pulseAnimationz.beginTime = 0.5;
    pulseAnimationz.fromValue = [NSNumber numberWithFloat:fromTranslationZ];
    pulseAnimationz.toValue = [NSNumber numberWithFloat:toTranslationZ];
    
    
    CABasicAnimation *rotateLayerAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    rotateLayerAnimation.duration = 1.0;
    rotateLayerAnimation.beginTime = 0.0;
    rotateLayerAnimation.fillMode = kCAFillModeBoth;
    rotateLayerAnimation.fromValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(fromRotation)];
    rotateLayerAnimation.toValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(toRotation)];
    
    anim = [CAAnimationGroup animation];
    anim.animations = [NSArray arrayWithObjects:pulseAnimationx,pulseAnimationy,translationx,translationy,pulseAnimationz, rotateLayerAnimation, nil];
    anim.duration = 1.0;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    anim.autoreverses = NO;
    anim.fillMode=kCAFillModeForwards;
    anim.removedOnCompletion = isRemove;
    anim.delegate = self;
    //[self.view bringSubviewToFront:faceView];
    return anim;
    
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (flag&&animationSyte == 0)
    {
        toView.layer.transform = CATransform3DIdentity;
        fromView.layer.transform = CATransform3DIdentity;
        toView.center = CGPointMake(160,240);
        fromView.center = CGPointMake(160,240);
        [self.view bringSubviewToFront:toView];  
        NSLog(@"%@,%@",NSStringFromCGRect(toView.frame),NSStringFromCGRect(toView.bounds));
        animationSyte = 1;
        /*
         CAAnimationGroup *anim;
         CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
         //  CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.z"];
         pulseAnimation.duration = 0.4;
         pulseAnimation.fromValue = [NSNumber numberWithFloat:3];
         pulseAnimation.toValue = [NSNumber numberWithFloat:4];
         
         CABasicAnimation *translationx = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
         translationx.duration = 0.4;
         translationx.fromValue = [NSNumber numberWithFloat:20];
         translationx.toValue = [NSNumber numberWithFloat:80];
         
         CABasicAnimation *translationy = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
         translationy.duration = 0.4;
         translationy.fromValue = [NSNumber numberWithFloat:60];
         translationy.toValue = [NSNumber numberWithFloat:135];
         
         CABasicAnimation *rotateLayerAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
         rotateLayerAnimation.duration = 0.4;
         rotateLayerAnimation.beginTime = 0.0;
         rotateLayerAnimation.fillMode = kCAFillModeBoth;
         rotateLayerAnimation.fromValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(-90)];
         rotateLayerAnimation.toValue = [NSNumber numberWithFloat:DEGREES_TO_RADIANS(0.)];
         rotateLayerAnimation.fillMode=kCAFillModeForwards ;
         rotateLayerAnimation.removedOnCompletion = NO;
         
         anim = [CAAnimationGroup animation];
         anim.animations = [NSArray arrayWithObjects:pulseAnimation,translationx,translationy, rotateLayerAnimation, nil];
         anim.duration = 0.4;
         anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
         anim.autoreverses = NO;
         anim.fillMode=kCAFillModeForwards ;
         anim.removedOnCompletion = NO;
         [self.faceView.layer addAnimation:anim forKey:@"fsdjkjaf"];
         */
    }
    else if(flag&&animationSyte == 2)
    {
        [self dismiss];
        fromView.frame = OriginalFrame;
        [superView addSubview:fromView];
        
        
    }
    
}


@end
