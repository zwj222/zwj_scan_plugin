//
//  QRMaskView.m
//  UseScanKitFrame
//
//  Created by shinho on 2021/5/19.
//  Copyright © 2021 shinho. All rights reserved.
//

#import "QRMaskView.h"

@implementation QRMaskView

/**
 根据蒙版的大小，视图扫码区域的大小创建蒙版
 
 @param maskFrame 蒙版在父视图中的大小
 @param scanFrame 扫码区域的大小
 @return 返回蒙版View
 */
- (instancetype)initMaskViewWithFrame:(CGRect)maskFrame
                        withScanFrame:(CGRect)scanFrame{
    self = [super initWithFrame:maskFrame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        
        [maskPath appendPath:[[UIBezierPath bezierPathWithRoundedRect:scanFrame cornerRadius:1] bezierPathByReversingPath]];
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        
        maskLayer.path = maskPath.CGPath;
        
        self.layer.mask = maskLayer;
    }
    return self;
}

@end
