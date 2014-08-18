//
//  StackedPageView.m
//  SSStackView
//
//  Created by HuangPeng on 6/13/14.
//  Copyright (c) 2014 Steven Stevenson. All rights reserved.
//

#import "StackedView.h"

@implementation StackablePage {
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selected = NO;
        _index = NSNotFound;
    }
    return self;
}

- (CGFloat)stackedHeight {
    return 40;
}

- (BOOL)reusable {
    return YES;
}

- (void)updateWithData:(NSDictionary *)data {
    
}

@end

@interface StackedView() <UIScrollViewDelegate, StackablePageDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic) NSRange visibleRange;

// 可重用的page，用户要show的View
@property (nonatomic, strong) NSMutableArray *reusablePages;

// 用户要show的View，可能会wrap一层shadow
@property (nonatomic, strong) NSMutableArray *visiblePages;

@property (nonatomic) CGFloat accumulatedYOffset;

// iOS7 automaticallyAdjustsScrollViewInsets leads to scrollViewDidScroll called,
// which will update StackView content, which may be unwanted
// set a loaded flag to prevent this
@property (nonatomic, readonly) BOOL loaded;

@end

@implementation StackedView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.visiblePages = [[NSMutableArray alloc] init];
    self.reusablePages = [[NSMutableArray alloc] init];
    self.visibleRange = NSMakeRange(0, 0);
    
    self.topMargin = 10;
    
    self.spaceBetweenExpanedPageAndPackedPages = 10;
    self.heightWhenPackedAtBottom = 5;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.decelerationRate = 0.8;
    NIDPRINT(@"%f", UIScrollViewDecelerationRateNormal);
    
    [self addSubview:self.scrollView];
    
     self.scrollView.delegate = self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.scrollView.height != self.bounds.size.height) {
        self.scrollView.frame = self.bounds;
        // 更新scrollView和卡片的layout，不刷新内容，以免选择失效，
        // TODO: 仍有问题，frame变化后，有可能需要增加一张卡片，所以要用selected index和解决选择
        
        [self reload];
    }
}

- (BOOL)loaded {
    return self.scrollView.contentSize.height > 10;
}

// reload
- (void)reload {
    CGFloat minHeight = self.height;
    CGFloat bottomMargin = 10;
    CGFloat contentHeight = MAX([self.dataSource numberOfPagesForStackView:self] * [self.delegate stackedHeightForPageAtIndex:0] + self.topMargin + bottomMargin, minHeight);
    
    NIDPRINT(@"%f", contentHeight);
    
    self.scrollView.showsVerticalScrollIndicator = self.showScrollIndicator;
    self.scrollView.bounces = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.contentSize = CGSizeMake(self.bounds.size.width, contentHeight);
    
    self.visibleRange = NSMakeRange(0, 0);
    while (self.visiblePages.count > 0) {
        [self popBackVisblePage];
    }
    
    // TODO: only need to be called when there's no visible pages
    //       needsToLayoutPages thus is not needed
    [self updateVisiblePageswWithContentOffset:self.scrollView.contentOffset.y];
    
    [self updateStackLayout:self.scrollView.contentOffset.y];
}

// select page at index
- (void)selectPageAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (![self pageAtIndexIsVisible:index]) {
        CGFloat yOffset = index * [self.delegate stackedHeightForPageAtIndex:0];
        
        // will update content if needed
        self.scrollView.contentOffset = CGPointMake(0, yOffset);
    }

    // select if the page to select is visible
    if ([self pageAtIndexIsVisible:index]) {
        NSInteger selectedIndex = index - self.visibleRange.location;
        
        [self selectPage:self.visiblePages[selectedIndex] animated:animated];
    }
}

- (BOOL)pageAtIndexIsVisible:(NSInteger)index {
    return index >= self.visibleRange.location && index < (self.visibleRange.location + self.visibleRange.length);
}

- (NSInteger)indexOfPage:(StackablePage *)page {
    NSInteger localIndex = [self.visiblePages indexOfObject:page];
    if (localIndex != NSNotFound) {
        return self.visibleRange.location + localIndex;
    }
    else {
        return NSNotFound;
    }
}

// select page
- (void)selectPage:(StackablePage*)page animated:(BOOL)animated {
    if (_selectedPage != page) {
        NSTimeInterval duration = animated ? 0.3 : 0;
        
        // deselect
        _selectedPage.selected = NO;
        StackablePage *tmp = _selectedPage;
        _selectedPage = nil;
        
        // notify client
        if (tmp) {
            NSInteger index = [self indexOfPage:tmp];
            if (index != NSNotFound) {
                if ([self.delegate respondsToSelector:@selector(stackedView:didDeselectPageAtIndex:)]) {
                    [self.delegate stackedView:self didDeselectPageAtIndex:index];
                }
            }
        }
        
        // select
        _selectedPage = page;
        _selectedPage.selected = YES;
        
        // notify client
        if (_selectedPage) {
            NSInteger index = [self indexOfPage:_selectedPage];
            if (index != NSNotFound) {
                if ([self.delegate respondsToSelector:@selector(stackedView:didSelectPageAtIndex:)]) {
                    [self.delegate stackedView:self didSelectPageAtIndex:index];
                }
            }
        }
        
        if (self.disableScrollWhenSelected) {
            self.scrollView.scrollEnabled = _selectedPage == nil;
        }
        
        // layout animation
        [UIView animateWithDuration:duration animations:^{
            [self updateStackLayout:self.scrollView.contentOffset.y withSelectedPage:_selectedPage];
        } completion:^(BOOL finished) {
            
        }];
    }
}

// update content
- (void)updateVisiblePageswWithContentOffset:(CGFloat)offset {
    // TODO: make sure after this updating, all visible pages are the ones should be visible, and all those should be visible are visible
    NSRange newRange = [self computeVisibleRange:offset];
    NSInteger startIdx = newRange.location;
    NSInteger endIdx = newRange.location + newRange.length;
    
    NSInteger oldStartIdx = self.visibleRange.location;
    NSInteger oldEndIdx = self.visibleRange.location + self.visibleRange.length;
    NSLog(@"index:%d, %d", startIdx, endIdx);
    if (startIdx != oldStartIdx || endIdx != oldEndIdx) {
        // move to resue
        // update visibleViews;
        for (int i = oldStartIdx; i < startIdx; ++i) {
            // remove pages at the begining
            [self popFrontVisiblePage];
        }
        for (int i = oldEndIdx - 1; i >= endIdx; --i) {
            // remove pages at the end
            [self popBackVisblePage];
        }
        
        for (int i = MAX(oldEndIdx, startIdx); i < endIdx; ++i) {
            // add pages
            [self addPageAtIndex:i fromBottom:YES];
        }
        
        for (int i = MIN(oldStartIdx - 1, endIdx - 1); i >= startIdx; --i) {
            // add pages
            [self addPageAtIndex:i fromBottom:NO];
        }
        self.visibleRange = NSMakeRange(startIdx, endIdx - startIdx);
    }
    
    for (int i = 0; i < self.visiblePages.count; ++i) {
        StackablePage *page = self.visiblePages[i];
        page.positionInVisiblePages = NSMakeRange(i, self.visiblePages.count);
    }
    
    NSLog(@"%d, %d", self.visiblePages.count, self.reusablePages.count);
}

// compute visible range
- (NSRange)computeVisibleRange:(CGFloat)offset {
    CGFloat endY = offset + CGRectGetHeight(self.scrollView.bounds) - self.topMargin;
    CGFloat startY = offset;
    
    NSInteger startIdx = 0;
    NSInteger endIdx = 0;
    
    if ([self.dataSource numberOfPagesForStackView:self] > 0) {
        startIdx = MAX(0, (NSInteger)(startY / [self.delegate stackedHeightForPageAtIndex:0]));
        endIdx = MAX(0, (NSInteger)(endY / [self.delegate stackedHeightForPageAtIndex:0]));
        
        startIdx = MAX(0, MIN(startIdx, [self.dataSource numberOfPagesForStackView:self] - 1));
        endIdx = MAX(0, MIN(endIdx, [self.dataSource numberOfPagesForStackView:self] - 1));
        return NSMakeRange(startIdx, endIdx - startIdx + 1);
    }
    else {
        return NSMakeRange(0, 0);
    }
}

// deque
- (UIView *)dequeueReusablePage {
    if (self.reusablePages.count > 0) {
        UIView *page = [self.reusablePages firstObject];
        [self.reusablePages removeObject:page];
        return page;
    }
    return nil;
}

// enqueue
- (void)reusePage:(StackablePage *)page {
    [self.visiblePages removeObject:page];
    
    [page removeFromSuperview];
    
    [self.reusablePages addObject:page];
}

// remove from bottom
- (StackablePage *)popFrontVisiblePage {
    if (self.visiblePages.count > 0) {
        StackablePage *page = self.visiblePages[0];
        [self reusePage:page];
        return page;
    }
    else {
        return nil;
    }
}

// remove from top
- (StackablePage *)popBackVisblePage {
    if (self.visiblePages.count > 0) {
        StackablePage *page = self.visiblePages.lastObject;
        [self reusePage:page];
        return page;
    }
    else {
        return nil;
    }
}

// add page
- (UIView *)addPageAtIndex:(NSInteger)index fromBottom:(BOOL)fromBottom {
    StackablePage *page = (StackablePage *)[self.dataSource stackView:self pageForIndex:index];
    
    page.index = index;
    
    page.layer.zPosition = index; // arrange the order of views TODO: remove this, zPosition will only affect visibility, doesn't affect the order of touch event handling
    
    page.delegate = self;
    
    if (fromBottom) {
        [self.scrollView addSubview:page];
        [self.visiblePages addObject:page];
    }
    else {
        [self.scrollView insertSubview:page atIndex:0];
        [self.visiblePages insertObject:page atIndex:0];
    }
    
    return page;
}

// update layout
- (void)updateStackLayout:(CGFloat)offset {
    CGFloat overlapHeight;
    CGFloat stackedHeight = [self.delegate stackedHeightForPageAtIndex:0];
    
    overlapHeight = MAX(0, offset - self.visibleRange.location * stackedHeight);
    
    CGFloat addedSpace = MAX(-offset, 0) * 3 / 12;
    if (self.visiblePages.count > 0) {
        CGFloat yOffset = self.topMargin;
        
        if ([self.dataSource numberOfPagesForStackView:self] > 1) { // 只有一页时，可以自由滑动
            yOffset += offset + addedSpace;
        }
        
        UIView *page = self.visiblePages[0];
        CGRect frame = page.frame;
        frame.origin.y = yOffset;
        NIDPRINT(@"%f, %f, %f, %f, %f, %d", offset, self.scrollView.height, self.scrollView.contentSize.height, yOffset, addedSpace, self.visiblePages.count);
        page.frame = frame;
        page.height = [self.delegate expandedHeightForPageAtIndex:self.visibleRange.location + 0];
        
        yOffset += stackedHeight + addedSpace - overlapHeight;
        
        for (int i = 1; i < self.visiblePages.count; ++i) {
            UIView *page = self.visiblePages[i];
            
            frame = page.frame;
            frame.origin.y = yOffset;
            page.frame = frame;
            page.height = [self.delegate expandedHeightForPageAtIndex:self.visibleRange.location + i];
            yOffset += stackedHeight + addedSpace;
        }
    }
}

// update layout with selected page
- (void)updateStackLayout:(CGFloat)offset withSelectedPage:(StackablePage *)selectedPage {
    NIDASSERT(selectedPage == self.selectedPage);
    
    if (selectedPage) {
        CGFloat yOffset = offset + self.topMargin;
        CGRect frame = selectedPage.frame;
        frame.origin.y = yOffset;
        selectedPage.frame = frame;
        yOffset += frame.size.height + self.spaceBetweenExpanedPageAndPackedPages;
        for (UIView *page in self.visiblePages) {
            if (page != selectedPage) {
                frame = page.frame;
                frame.origin.y = yOffset;
                page.frame = frame;
                yOffset += self.heightWhenPackedAtBottom;
            }
        }
    }
    else {
        // no selected page
        [self updateStackLayout:offset];
    }
}

#pragma mark  - StackablePage delegate
- (void)stackablePageRequiredToBeSelected:(StackablePage *)page {
    [self selectPage:page animated:YES];
}

- (void)stackablePageRequiredToBeDeselected:(StackablePage *)page {
    if (self.selectedPage == page) {
        [self selectPage:nil animated:YES];
    }
}

- (void)stackablePageRequiredToShowOthers:(UIView *)page {
    [self updateStackLayout:self.scrollView.contentOffset.y withSelectedPage:self.selectedPage];
}

- (void)stackablePageRequiredToHideOthers:(UIView *)page {
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *v in self.visiblePages) {
            if (v != page) {
                CGRect frame = v.frame;
                frame.origin.y = self.scrollView.contentOffset.y + 1000;
                v.frame = frame;
            }
        }
    }];

}

#pragma mark - scrollview delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.loaded) {
        return;
    }
    
    CGFloat offset = scrollView.contentOffset.y;
    [self updateVisiblePageswWithContentOffset:offset];
    
    // unselect page when scroll
    if (self.selectedPage) {
        [self selectPage:nil animated:NO];
    }

    if ([self shouldUpdateLayoutWithOffset:offset]) {
        offset = [self adjustOffset:offset];
        
        [self updateStackLayout:offset];
    }
}

- (BOOL)shouldUpdateLayoutWithOffset:(CGFloat)offset {
    return YES;
}

- (CGFloat)adjustOffset:(CGFloat)offset {
    return offset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        
    }
}

- (void)debug {
    for (StackablePage *page in self.visiblePages) {
        page.backgroundColor = [UIColor greenColor];
        NIDPRINT(@"%@", page.superview);
        NIDPRINT(@"%f, %f, %f, %f", page.left, page.top, page.width, page.height);
    }
}

@end

@implementation NetworkStackedView {

}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.disableScrollWhenSelected = YES;
    }
    return self;
}

- (void)setDisableScrollWhenSelected:(BOOL)disableScrollWhenSelected {
    if (disableScrollWhenSelected) {
        [super setDisableScrollWhenSelected:disableScrollWhenSelected];
    }
    else {
        NIDASSERT(NO);
    }
}

- (void)setRefreshIndicatorView:(RefreshIndicatorView *)refreshIndicatorView {
    if (_refreshIndicatorView != refreshIndicatorView) {
        [_refreshIndicatorView removeFromSuperview];
        
        _refreshIndicatorView = refreshIndicatorView;
        
        [_refreshIndicatorView setupWithScrollView:self.scrollView];
        
        [self insertSubview:_refreshIndicatorView belowSubview:self.scrollView];
    }
}

- (BOOL)shouldUpdateLayoutWithOffset:(CGFloat)offset {
    if (self.scrollView.isDragging) {
        return offset >= 0 || offset < -_refreshIndicatorView.bottom;
    }
    else {
        return YES;
    }
}

- (CGFloat)adjustOffset:(CGFloat)offset {
    if (offset < 0) {
        offset = MIN(0, offset + _refreshIndicatorView.bottom);
    }
    return offset;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [super scrollViewDidScroll:scrollView];
}

@end

@implementation RefreshIndicatorView {
    UIScrollView *_scrollView;
    BOOL _isLoading;
}

- (void)dealloc {
    [self clean];
}

- (void)clean {
    [_scrollView removeObserver:self forKeyPath:@"contentOffset" context:nil];
    _scrollView.topInset = 0;
    _scrollView = nil;
}

- (void)setupWithScrollView:(UIScrollView *)scrollView {
    [self clean];
    
    _scrollView = scrollView;
    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if (!_scrollView.isDragging && _scrollView.contentOffset.y < -self.bottom) {
            [self startRefresh];
        }
    }
}

- (void)finishedRefresh {
    [UIView animateWithDuration:0.2 animations:^{
         _scrollView.topInset = 0;
        _isLoading = NO;
    }];
}

- (BOOL)startRefresh {
    if (!_isLoading) {
        [self.delegate refreshIndicatorViewBeginRefresh:self];
        
        [UIView animateWithDuration:0.2 animations:^{
            _scrollView.topInset = self.bottom;
        } completion:^(BOOL finished) {
            
        }];
        _isLoading = YES;
        return YES;
    }
    return NO;
}

@end

@implementation RefreshIndicatorView2 {
    UIActivityIndicatorView *_activityView;
    UILabel *_titleLabel;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _activityView = [UIActivityIndicatorView new];
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self addSubview:_activityView];
    [self addSubview:_titleLabel];
    
    [self setState:NO];
}

- (void)setState:(BOOL)loading {
    if (loading) {
        _titleLabel.text = @"加载数据";
    }
    else {
        _titleLabel.text = @"松开刷新";
    }
    [_titleLabel sizeToFit];
    _titleLabel.center = CGPointMake(self.width / 2, self.height / 2);
    _activityView.right = _titleLabel.left - 10;
    _activityView.centerY = _titleLabel.centerY;
    
    if (loading) {
        [_activityView startAnimating];
    }
    else {
        [_activityView stopAnimating];
    }
}

- (BOOL)startRefresh {
    if ([super startRefresh]) {
        [self setState:YES];
        return YES;
    }
    return NO;
}

- (void)finishedRefresh {
    [super finishedRefresh];
    [self setState:NO];
}
@end



