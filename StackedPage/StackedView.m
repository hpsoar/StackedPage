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

// shadow wrapper，为了正确处理圆角和shadow
@property (nonatomic, strong) NSMutableArray *shadowContainers;

@property (nonatomic, strong) NSMutableArray *tapOverlays;

@property (nonatomic) CGFloat accumulatedYOffset;

@property (nonatomic, strong) StackablePage *innerSelectedPage;

@property (nonatomic) BOOL needsToLayoutPages;

@property (nonatomic, strong) UIView *topView;

@property (nonatomic) BOOL shouldPinTopView;

@property (nonatomic) BOOL topViewDidShow;

@end

@implementation StackedView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.visiblePages = [[NSMutableArray alloc] init];
    self.reusablePages = [[NSMutableArray alloc] init];
    self.shadowContainers = [[NSMutableArray alloc] init];
    self.visibleRange = NSMakeRange(0, 0);
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.delegate = self;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.decelerationRate = 0.8;
    NIDPRINT(@"%f", UIScrollViewDecelerationRateNormal);
    
    [self addSubview:self.scrollView];
    
    self.topMargin = 10;
    
    self.spaceBetweenExpanedPageAndPackedPages = 10;
    self.heightWhenPackedAtBottom = 5;
    
    self.toggleSelection = NO;
}

- (void)reload {
    [self reloadClearOldPages:YES];
}

- (void)reloadClearOldPages:(BOOL)clearOldPages {
    CGFloat minHeight = self.height;
    CGFloat bottomMargin = 10;
    CGFloat contentHeight = MAX([self.delegate numberOfPagesForStackView:self] * [self.delegate stackedHeightForPageAtIndex:0] + self.topMargin + bottomMargin, minHeight);
    NIDPRINT(@"%f", contentHeight);
    
    self.scrollView.showsVerticalScrollIndicator = self.showScrollIndicator;
    self.scrollView.bounces = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.contentSize = CGSizeMake(self.bounds.size.width, contentHeight);
    
    if (self.topView) {
        [self.topView removeFromSuperview];
        self.topView = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(headerViewForStackedView:)]) {
        self.topView = [self.delegate headerViewForStackedView:self];
        [self.scrollView addSubview:self.topView];
        self.topView.hidden = YES;
    }
    
    {
        if (clearOldPages) {
            self.visibleRange = NSMakeRange(0, 0);
            while (self.visiblePages.count > 0) {
                [self popBackVisblePage];
            }
            
            // TODO: only need to be called when there's no visible pages
            //       needsToLayoutPages thus is not needed
            [self updateVisiblePageswWithContentOffset:self.scrollView.contentOffset.y];
        }
        
        if (self.toggleSelection) {
            [self toggleSelectedPage:NO];
        }
        else {
            if (self.innerSelectedPage) {
                [self updateStackLayout:self.scrollView.contentOffset.y withSelectedPage:self.innerSelectedPage];
            }
            else {
                [self updateStackLayout:self.scrollView.contentOffset.y];
            }
        }
    }
}

- (void)selectPageAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < self.visibleRange.location || index >= (self.visibleRange.location + self.visibleRange.length)) {
        CGFloat yOffset = index * [self.delegate stackedHeightForPageAtIndex:0];
        self.scrollView.contentOffset = CGPointMake(0, yOffset);
    }
    NSInteger selectedIndex = index - self.visibleRange.location;
    
    [self selectPage:self.visiblePages[selectedIndex] animated:animated];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.scrollView.height != self.bounds.size.height) {
        self.scrollView.frame = self.bounds;
        // 更新scrollView和卡片的layout，不刷新内容，以免选择失效，
        // TODO: 仍有问题，frame变化后，有可能需要增加一张卡片，所以要用selected index和解决选择
        [self reloadClearOldPages:NO];
    }
}

- (NSRange)computeVisibleRange:(CGFloat)offset {
    CGFloat endY = offset + CGRectGetHeight(self.scrollView.bounds) - self.topMargin;
    CGFloat startY = offset;
    
    NSInteger startIdx = 0;
    NSInteger endIdx = 0;
    
    if ([self.delegate numberOfPagesForStackView:self] > 0) {
        startIdx = MAX(0, (NSInteger)(startY / [self.delegate stackedHeightForPageAtIndex:0]));
        endIdx = MAX(0, (NSInteger)(endY / [self.delegate stackedHeightForPageAtIndex:0]));
        
        startIdx = MAX(0, MIN(startIdx, [self.delegate numberOfPagesForStackView:self] - 1));
        endIdx = MAX(0, MIN(endIdx, [self.delegate numberOfPagesForStackView:self] - 1));
        return NSMakeRange(startIdx, endIdx - startIdx + 1);
    }
    else {
        return NSMakeRange(0, 0);
    }
}

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

- (void)updateStackLayout:(CGFloat)offset {
    NIDPRINT(@"%f, %f, %f", offset, self.scrollView.height, self.scrollView.contentSize.height);
    CGFloat overlapHeight;
    CGFloat stackedHeight = [self.delegate stackedHeightForPageAtIndex:0];
    
    overlapHeight = MAX(0, offset - self.visibleRange.location * stackedHeight);
    
    // 如果有topView，要等topView可见了，才有拉伸效果
    if (self.visibleRange.location == 0 && self.topView && offset < 0) {
        offset = MIN(self.topView.height + offset, 0);
    }
    
    CGFloat addedSpace = MAX(-offset / self.visiblePages.count, 0) * 3;
    if (self.visiblePages.count > 0) {
        CGFloat yOffset = self.topMargin;
        if ([self.delegate numberOfPagesForStackView:self] > 1) { // 只有一页时，可以自由滑动
            yOffset += offset + addedSpace;
        }
        
        UIView *page = self.visiblePages[0];
        CGRect frame = page.frame;
        frame.origin.y = yOffset;
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
    
    self.needsToLayoutPages = NO;
}

- (void)updateStackLayout:(CGFloat)offset withSelectedPage:(StackablePage *)selectedPage {
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
    self.needsToLayoutPages = NO;
}
- (UIView *)dequeueReusablePage {
    if (self.reusablePages.count > 0) {
        UIView *page = [self.reusablePages firstObject];
        [self.reusablePages removeObject:page];
        return page;
    }
    return nil;
}

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

- (void)reusePage:(StackablePage *)page {
    if (page == self.innerSelectedPage) {
        self.innerSelectedPage.selected = NO;
        _innerSelectedPage = nil;
    }
    
    [self.visiblePages removeObject:page];
    
    [page removeFromSuperview];
    
    [self.reusablePages addObject:page];
}

- (UIView *)addPageAtIndex:(NSInteger)index fromBottom:(BOOL)fromBottom {
    StackablePage *page = (StackablePage *)[self.delegate stackView:self pageForIndex:index];
    
    page.index = index;
    
    page.layer.zPosition = index; // arrange the order of views TODO: remove this, zPosition will only affect visibility, doesn't affect the order of touch event handling
    
    page.delegate = self;
    
    if (fromBottom) {
        [self.scrollView addSubview:page];
        [self.visiblePages addObject:page];
    }
    else {
        [self.scrollView insertSubview:page aboveSubview:self.topView];
        [self.visiblePages insertObject:page atIndex:0];
    }
    
    self.needsToLayoutPages = YES;
    
    return page;
}

#pragma mark  - StackablePage delegate
- (void)stackablePageSelected:(UIView *)page {
    NIDPRINTMETHODNAME();
    if (self.toggleSelection) {
        [self toggleSelectedPage:YES];
    }
    else {
        if (self.innerSelectedPage) {
            self.innerSelectedPage = nil;
        }
        else {
            self.innerSelectedPage = (StackablePage*)page;
        }
    }
}

- (void)stackablePageRequiredToShowOthers:(UIView *)page {
    if (page != _innerSelectedPage) {
        return;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self updateStackLayout:self.scrollView.contentOffset.y withSelectedPage:_innerSelectedPage];
    }];
}

- (void)stackablePageRequiredToHideOthers:(UIView *)page {
    if (page != _innerSelectedPage) {
        return;
    }
    
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

// when a cell is tapped
- (void)setSelectedIndex:(NSInteger)selectedIndex {
    
}

- (UIView *)pageAtIndex:(NSInteger)index {
    return nil;
}

- (NSInteger)indexOfPage:(UIView *)page {
    return NSNotFound;
}

- (StackablePage *)selectedPage {
    return self.innerSelectedPage;
}

- (void)setInnerSelectedPage:(StackablePage *)selectedPage {
    if (_innerSelectedPage == selectedPage) {
        return;
    }
    
    if (_innerSelectedPage) {
        _innerSelectedPage.selected = NO;
        _innerSelectedPage = nil;
    }
    
    if (selectedPage) {
        selectedPage.selected = YES;
        _innerSelectedPage = selectedPage;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        if (selectedPage) {
            [self updateStackLayout:self.scrollView.contentOffset.y withSelectedPage:selectedPage];
        }
        else {
            [self updateStackLayout:self.scrollView.contentOffset.y];
        }
    } completion:^(BOOL finished) {
        if (selectedPage) {
            if (self.disableScrollWhenSelected) {
                self.scrollView.scrollEnabled = self.visiblePages.count < 2;
            }
        }
        else {
            if (self.disableScrollWhenSelected) {
                self.scrollView.scrollEnabled = YES;
            }
        }
    }];
}

#pragma mark - scrollview delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offset = scrollView.contentOffset.y;
    NIDPRINT(@"offset: %f", offset);
    
    [self updateVisiblePageswWithContentOffset:offset];
    
    // 排列卡片
    if (self.toggleSelection) {
        [self toggleSelectedPage:YES];
    }
    else {
        if (self.innerSelectedPage) {
            self.innerSelectedPage = nil;
        }
        else {
            [self updateStackLayout:offset];
        }
    }
    
    // headerView相关事件
    if (self.topView.hidden && offset <= -5) {
        if ([self.delegate respondsToSelector:@selector(stackedView:willShowHeaderView:)]) {
            [self.delegate stackedView:self willShowHeaderView:self.topView];
        }
    }
    
    if (!self.topView.hidden && offset > -5) {
        if ([self.delegate respondsToSelector:@selector(stackedView:didHideHeaderView:)]) {
            [self.delegate stackedView:self didHideHeaderView:self.topView];
        }
    }
    
    if (self.topView && self.scrollView.isDragging && -offset >= self.topView.height && !self.topViewDidShow) {
        self.topViewDidShow = YES;
        if ([self.delegate respondsToSelector:@selector(stackedView:didShowHeaderView:)]) {
            [self.delegate stackedView:self didShowHeaderView:self.topView];
        }
    }
    
    if (self.topView && self.topViewDidShow && !self.scrollView.isDragging && -offset < self.topView.height) {
        self.topViewDidShow = NO;
        if ([self.delegate respondsToSelector:@selector(stackedView:willHideHeaderView:)]) {
            [self.delegate stackedView:self willHideHeaderView:self.topView];
        }
    }
    
    self.topView.hidden = offset > -5;
    if (self.topView) {
        self.topView.top = offset + self.topMargin;
        self.topView.centerX = self.scrollView.width / 2;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        
    }
}

- (void)toggleSelectedPage:(BOOL)animated {
    // 有可能页面上度会变
    for (UIView *v in self.visiblePages) {
        v.height = [self.delegate expandedHeightForPageAtIndex:0];
    }
    
    StackablePage *page;
    for (UIView *v in self.visiblePages) {
        if (v != self.innerSelectedPage) {
            page = (StackablePage *)v;
            break;
        }
    }
    if (page) {
        [self selectPage:page animated:animated];
    }
}

- (void)selectPage:(StackablePage *)page animated:(BOOL)animated {
    if (self.innerSelectedPage == page ) {
        return;
    }
    
    if (animated) {
        self.innerSelectedPage = page;
    }
    else {
        if (_innerSelectedPage) {
            _innerSelectedPage.selected = NO;
        }
        _innerSelectedPage = page;
        _innerSelectedPage.selected = YES;
        
        [self updateStackLayout:self.scrollView.contentOffset.y withSelectedPage:page];
        
        if (self.disableScrollWhenSelected) {
            self.scrollView.scrollEnabled = self.visiblePages.count < 2;
        }
    }
}

- (void)debug {
    for (StackablePage *page in self.visiblePages) {
        page.backgroundColor = [UIColor greenColor];
        NIDPRINT(@"%@", page.superview);
        NIDPRINT(@"%f, %f, %f, %f", page.left, page.top, page.width, page.height);
    }
}

- (void)pinTopView {
    self.scrollView.topInset = self.topView.height;
    self.shouldPinTopView = YES;
}

- (void)unpinTopView {
    [UIView animateWithDuration:0.5 animations:^{
        self.scrollView.topInset = 0;
        self.shouldPinTopView = NO;
    } completion:^(BOOL finished) {
        
    }];
}

@end
