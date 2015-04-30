//
//  ExpansiveView.h
//  eLife
//
//  Created by mac on 14-3-31.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HeaderView.h"

@class ExpansiveView;
@class ExpansiveCell;

@protocol ExpansiveViewDataSource <NSObject>

- (NSInteger)numberOfRowsInExpansiveView:(ExpansiveView *)expansiveView;

- (ExpansiveCell *)expansiveView:(ExpansiveView *)expansiveView cellForRow:(NSInteger)row;

@end

@protocol ExpansiveViewDelegate <NSObject>

- (void)expansiveView:(ExpansiveView *)expansiveView openHeader:(BOOL)yesOrNo atRow:(NSInteger)row;

- (NSUInteger)expansiveView:(ExpansiveView *)expansiveView heightForHeaderAtRow:(NSUInteger)row;

- (NSUInteger)expansiveView:(ExpansiveView *)expansiveView heightForContentAtRow:(NSUInteger)row;

@end

@interface ExpansiveView : UIView <HeaderViewDelegate>

@property (nonatomic,assign) id<ExpansiveViewDataSource> dataSource;
@property (nonatomic,assign) id<ExpansiveViewDelegate> delegate;
@property (nonatomic) NSInteger cellWidth;

- (void)reloadData;

- (void)reloadCellAtRow:(NSUInteger)row;

- (void)resizeContent:(CGSize)contentSize;

- (void)setContentInsets:(UIEdgeInsets)contentInsets;

- (CGSize)contentSize;

//- (void)displaySHDsiconnectView:(BOOL)yesOrNo;


@end
