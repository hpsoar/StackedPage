//
//  StackedPageView.h
//  SSStackView
//
//  Created by HuangPeng on 6/13/14.
//  Copyright (c) 2014 Steven Stevenson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utility2.h"

@class StackablePage;

// StackablePageDelegate
@protocol StackablePageDelegate <NSObject>

- (void)stackablePageSelected:(StackablePage *)page;

@optional
- (void)stackablePageRequiredToHideOthers:(StackablePage *)page;

- (void)stackablePageRequiredToShowOthers:(StackablePage *)page;

- (NSRange)stackablePagePositionInVisiablePages:(StackablePage *)page;

@end

#pragma mark - StackablePage
@interface StackablePage : UIView

@property (nonatomic, readonly) CGFloat stackedHeight;

- (void)updateWithData:(NSDictionary *)data;

@property (nonatomic, readonly) BOOL reusable;

@property (nonatomic) BOOL selected;

@property (nonatomic) NSRange positionInVisiblePages;

@property (nonatomic) NSInteger index;

@property (nonatomic, weak) id<StackablePageDelegate> delegate;

@end

#pragma mark - StackedViewDelegate
@class StackedView;

@protocol StackedViewDelegate <NSObject>

///method for setting the current page at the index
- (UIView*)stackView:(StackedView *)stackView pageForIndex:(NSInteger)index;

///total number of pages to present in the stack
- (NSInteger)numberOfPagesForStackView:(StackedView *)stackView;

- (CGFloat)stackedHeightForPageAtIndex:(NSInteger)index;

- (CGFloat)expandedHeightForPageAtIndex:(NSInteger)index;

// TODO: 去掉updatePage...
@optional
- (UIView *)headerViewForStackedView:(StackedView *)stackedView;

- (void)stackedView:(StackedView *)stackedView willShowHeaderView:(UIView *)headerView;
- (void)stackedView:(StackedView *)stackedView didShowHeaderView:(UIView *)headerView;
- (void)stackedView:(StackedView *)stackedView willHideHeaderView:(UIView *)headerView;
- (void)stackedView:(StackedView *)stackedView didHideHeaderView:(UIView *)headerView;


// 现在下面这些没什么用
//- (void)stackView:(StackedPageView *)stackView didSelectPage:(UIView *)page atIndex:(NSInteger)index;
//
//- (void)stackView:(StackedPageView *)stackView willSelectPage:(UIView *)page atIndex:(NSInteger)index;
//
//- (void)stackView:(StackedPageView *)stackView willDeselectPage:(UIView *)page atIndex:(NSInteger)index;
//
//- (void)stackView:(StackedPageView *)stackView didDeselectPage:(UIView *)page atIndex:(NSInteger)index;

@end

#pragma mark - StackedView
@interface StackedView : UIView

@property (nonatomic) CGFloat topMargin;

@property (nonatomic) CGFloat heightWhenPackedAtBottom;

@property (nonatomic) CGFloat spaceBetweenExpanedPageAndPackedPages;

@property (nonatomic) BOOL disableScrollWhenSelected;

@property (nonatomic) BOOL toggleSelection;

@property (nonatomic, weak) id<StackedViewDelegate> delegate;

@property (nonatomic) NSInteger selectedIndex;

@property (nonatomic, readonly) StackablePage *selectedPage;

@property (nonatomic) BOOL showScrollIndicator;

// TODO: use StackablePage
- (StackablePage*)dequeueReusablePage;

// 删除所有page，重新加载
- (void)reload;

- (void)selectPageAtIndex:(NSInteger)index animated:(BOOL)animated;

// TODO: implement
- (StackablePage*)pageAtIndex:(NSInteger)index;

- (NSInteger)indexOfPage:(StackablePage *)page;

- (void)debug;

- (void)pinTopView;

- (void)unpinTopView;

@end
