//
//  PanelEditViewController.h
//  eLife
//
//  Created by mac mini on 14/10/30.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PanelEditViewController;

@protocol PanelEditViewControllerDelegate <NSObject>

- (void)panelEditViewController:(PanelEditViewController *)panelEditViewController deleteItemAtIndex:(NSInteger)index;


- (void)panelEditViewController:(PanelEditViewController *)panelEditViewController downloadFile:(NSString *)fileName path:(NSString *)filePath overwritten:(BOOL)yesOrNo;



- (void)panelEditViewControllerReorder;//重新排序



@end


@interface PanelEditViewController : UIViewController

@property (nonatomic,assign) id<PanelEditViewControllerDelegate> delegate;


- (void)setPanels:(NSArray *)panels;

@end
