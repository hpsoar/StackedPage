//
//  StackedViewDemo1.m
//  StackedPage
//
//  Created by HuangPeng on 8/18/14.
//  Copyright (c) 2014 HuangPeng. All rights reserved.
//

#import "StackedViewDemo1.h"
#import "StackedView.h"

@interface StackedPage1 : StackablePage {
    
}

@end


@implementation StackedPage1

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPage)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)selectPage {
    if (self.selected) {
        [self.delegate stackablePageRequiredToBeDeselected:self];
    }
    else {
        [self.delegate stackablePageRequiredToBeSelected:self];
    }
}

@end

@interface StackedViewDemo1 () <StackedViewDataSource, StackedViewDelegate>

@end

@implementation StackedViewDemo1 {
    NetworkStackedView *_stackedView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _stackedView = [[NetworkStackedView alloc] initWithFrame:NIRectShift(self.view.bounds, 0, 64)];
    _stackedView.delegate = self;
    _stackedView.dataSource = self;
    
    [self.view addSubview:_stackedView];
    
    [_stackedView reload];
}

- (StackablePage *)stackView:(StackedView *)stackView pageForIndex:(NSInteger)index {
    StackablePage *page = [stackView dequeueReusablePage];
    if (page == nil) {
        page = [[StackedPage1 alloc] initWithFrame:CGRectMake(10, 0, 300, 100)];
        NSArray *colors = @[[UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor yellowColor]];
        static NSInteger index = 0;
        page.backgroundColor = colors[index];
        
        index++;
        if (index >= colors.count) {
            index = 0;
        }
    }
    return page;
}

- (NSInteger)numberOfPagesForStackView:(StackedView *)stackView {
    return 20;
}

- (CGFloat)stackedHeightForPageAtIndex:(NSInteger)index {
    return 44.0;
}

- (CGFloat)expandedHeightForPageAtIndex:(NSInteger)index {
    return 360;
}

@end
