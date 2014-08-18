//
//  StackedPageView.h
//  SSStackView
//
//  Created by HuangPeng on 6/13/14.
//  Copyright (c) 2014 Steven Stevenson. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 * use StackedView
 * 1. create StackedView instance
 * 2. set parameters
 * 3. set dataSource
 * 4. set delegate
 * 5. reload
 * 6. other public interface, such as selectPageAtIndex:...
 * 7. interaction with the holded pages
 *
 * use NetworkStackedView
 * 1. same as 1-4 above
 * 2. create RefreshIndicatorView
 * 3. add RefreshIndicatorView to NetworkStackedView
 * 4. set RefreshIndicatorView delegate
 * 5. reload
 * 6 ...
 * a. the dataSource can be a network dataSource
 * b. Client should implement RefreshIndicatorViewDelegate to begin loading, and call RefreshIndicatorView:stopAnimation after loading
 
 * BASICALLY, client need to do 4 things:
 * 1. create StackedView, RefreshIndicatorView
 * 2. provide dataSource, delegate to StackedView
 * 3. provide delegate to RefreshIndicatorView
 * 4. provide RefreshIndicatorView to StackedView
 */

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

@optional

- (void)stackedView:(StackedView *)stackedView didSelectPageAtIndex:(NSInteger)index;

- (void)stackedView:(StackedView *)stackedView didDeselectPageAtIndex:(NSInteger)index;

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

#pragma mark - network

@class RefreshIndicatorView;

@interface NetworkStackedView : StackedView

@property (nonatomic, strong) RefreshIndicatorView *refreshIndicatorView;

@end


#pragma mark - refresh
@protocol RefreshIndicatorViewDelegate <NSObject>

- (void)refreshIndicatorViewBeginRefresh:(RefreshIndicatorView *)refreshIndicatorView;

@end

@interface RefreshIndicatorView : UIView

- (void)setupWithScrollView:(UIScrollView *)scrollView;

- (BOOL)startRefresh;

- (void)finishedRefresh;

@property (nonatomic, weak) id<RefreshIndicatorViewDelegate> delegate;

@end

@interface RefreshIndicatorView2 : RefreshIndicatorView

@end


