//
//  StackedPageView.h
//  SSStackView
//
//  Created by HuangPeng on 6/13/14.
//  Copyright (c) 2014 Steven Stevenson. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StackablePage;

// StackablePageDelegate
@protocol StackablePageDelegate <NSObject>

- (void)stackablePageRequiredToBeSelected:(StackablePage *)page;

- (void)stackablePageRequiredToBeDeselected:(StackablePage *)page;

- (void)stackablePageRequiredToHideOthers:(StackablePage *)page;

- (void)stackablePageRequiredToShowOthers:(StackablePage *)page;

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

- (CGFloat)stackedHeightForPageAtIndex:(NSInteger)index;

- (CGFloat)expandedHeightForPageAtIndex:(NSInteger)index;

@end

#pragma mark - StackedViewDataSource

@protocol StackedViewDataSource <NSObject>

///method for setting the current page at the index
- (StackablePage*)stackView:(StackedView *)stackView pageForIndex:(NSInteger)index;

///total number of pages to present in the stack
- (NSInteger)numberOfPagesForStackView:(StackedView *)stackView;

@end

#pragma mark - StackedView
@interface StackedView : UIView

@property (nonatomic) CGFloat topMargin;

@property (nonatomic) CGFloat heightWhenPackedAtBottom;

@property (nonatomic) CGFloat spaceBetweenExpanedPageAndPackedPages;

@property (nonatomic) BOOL disableScrollWhenSelected;

@property (nonatomic) BOOL showScrollIndicator;

@property (nonatomic, readonly) StackablePage *selectedPage;

@property (nonatomic, weak) id<StackedViewDelegate> delegate;
@property (nonatomic, weak) id<StackedViewDataSource> dataSource;

- (StackablePage*)dequeueReusablePage;

// 删除所有page，清除选中状态，重新加载
- (void)reload;

- (void)selectPageAtIndex:(NSInteger)index animated:(BOOL)animated;

- (void)debug;

@end

@interface NetworkStackedView : StackedView

@end

@interface RefreshIndicator : UIView

- (void)setupWithScrollView:(UIScrollView *)scrollView;

@end

