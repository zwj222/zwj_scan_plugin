//
//  QRMaskView.h
//  UseScanKitFrame
//
//  Created by shinho on 2021/5/19.
//  Copyright © 2021 shinho. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QRMaskView : UIView

/**
 根据蒙版的大小，视图扫码区域的大小创建蒙版

 @param maskFrame 蒙版在父视图中的大小
 @param scanFrame 扫码区域的大小
 @return 返回蒙版View
 */
- (instancetype)initMaskViewWithFrame:(CGRect)maskFrame
                        withScanFrame:(CGRect)scanFrame;

@end

NS_ASSUME_NONNULL_END
