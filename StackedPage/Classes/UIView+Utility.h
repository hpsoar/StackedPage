//
//  UIView+Utility.h
//  StackedPage
//
//  Created by HuangPeng on 8/18/14.
//  Copyright (c) 2014 HuangPeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Utility)

@property (nonatomic) CGFloat width, height;

@property (nonatomic) CGFloat left, top, right, bottom;

@property (nonatomic) CGFloat centerX, centerY;

@end

@interface UIScrollView (Utility)

@property (nonatomic) CGFloat topInset;

@end
