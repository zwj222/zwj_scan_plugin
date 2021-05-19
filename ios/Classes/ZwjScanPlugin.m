#import "ZwjScanPlugin.h"

#import <ScanKitFrameWork/ScanKitFrameWork.h>
#import "QueuingEventSink.h"

#import "QRMaskView.h"
#import "QRScanAnimationView.h"

#define FormatTypeSize 14
static uint scanFormatTypes[FormatTypeSize] = {
    ALL, QR_CODE, AZTEC, DATA_MATRIX, PDF_417,CODE_39,
    CODE_93,CODE_128,EAN_13,EAN_8,ITF,UPC_A,UPC_E,CODABAR,
};

@interface ZwjScanPlugin ()<DefaultScanDelegate,FlutterStreamHandler, CustomizedScanDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    
    CGFloat SCREEN_WIDTH;
    CGFloat SCREEN_HEIGHT;
    
    QueuingEventSink *_eventSink;
    FlutterMethodChannel *_channel;
    FlutterEventChannel *_eventChannel;
    id<FlutterPluginRegistrar> _registrar;
    
    //扫码相关的
    HmsCustomScanViewController *hmsCustomScanViewController;
    
    UIButton *backBtn;
    UIButton *albemBtn;
    UILabel *tipLab;
    
    CGRect scan_frame_;
    QRMaskView * qr_mask_view_;  //顶部蒙版视图
    QRScanAnimationView * qr_scan_animation_view_; //扫码动画视图
}

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end

@implementation ZwjScanPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"zwj_scan_plugin/method"
            binaryMessenger:[registrar messenger]];
  ZwjScanPlugin* instance = [[ZwjScanPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar{
    self = [super init];
    if (self) {
        SCREEN_WIDTH = [UIScreen mainScreen].bounds.size.width;
        SCREEN_HEIGHT = [UIScreen mainScreen].bounds.size.height;
        
        _eventSink = [QueuingEventSink new];
        
        _eventChannel = [FlutterEventChannel eventChannelWithName:@"zwj_scan_plugin/event" binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
    if ([@"startScan" isEqualToString:call.method]) {
        NSDictionary *args = call.arguments;
        NSArray *scanTypes= args[@"scan_types"];
        //解析需要的格式
        HmsScanOptions *options = [[HmsScanOptions alloc] initWithScanFormatType:[self getScanFormatType:scanTypes] Photo:FALSE];

        hmsCustomScanViewController = [[HmsCustomScanViewController alloc] initCustomizedScanWithFormatType:options];
        hmsCustomScanViewController.customizedScanDelegate = self;
        hmsCustomScanViewController.backButtonHidden = YES;
        hmsCustomScanViewController.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        
        UIViewController *topViewCtrl = [self topViewControler];
        [topViewCtrl.view addSubview:hmsCustomScanViewController.view];
        [topViewCtrl addChildViewController:hmsCustomScanViewController];
        [hmsCustomScanViewController didMoveToParentViewController:topViewCtrl];
        
        [self realStartScanWithVC:topViewCtrl scanVC:hmsCustomScanViewController];

        result([NSNumber numberWithInt:0]);
    } else {
      result(FlutterMethodNotImplemented);
    }
}

- (uint)getScanFormatType:(NSArray *)typeIndex{
    NSUInteger len = typeIndex.count;
    NSNumber *item = typeIndex[0];
    uint ret = 0;
    if (len == 1 && item.intValue != scanFormatTypes[0]) {
        return scanFormatTypes[item.intValue];
    }else if(len == 1 && item.intValue == scanFormatTypes[0]){
        for (int i = 1; i<FormatTypeSize; i++) {
            ret |= scanFormatTypes[i];
        }
        return ret;
    }else{
        for (NSNumber *num in typeIndex) {
            ret |= scanFormatTypes[num.intValue];
        }
        return ret;
    }
}

- (void)defaultScanDelegateForDicResult:(NSDictionary *)resultDic{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *str = [NSString stringWithFormat:@"%@", resultDic[@"text"]];
        [self->_eventSink success:str];
      });
}

- (void)defaultScanImagePickerDelegateForImage:(UIImage *)image{
    NSDictionary *dic = [HmsBitMap bitMapForImage:image withOptions:[[HmsScanOptions alloc] initWithScanFormatType:ALL Photo:true]];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *str = [NSString stringWithFormat:@"%@", dic[@"text"]];
        [self->_eventSink success:str];
   });
}

- (UIViewController *)topViewControler{
    //获取根控制器
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *parent = root;
    while ((parent = root.presentedViewController) != nil ) {
        root = parent;
    }
    return root;
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events{
    [_eventSink setDelegate:events];
    return nil;
}


- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments{
    [_eventSink setDelegate:nil];
    return nil;
}


- (void)backBtnClick{
    //返回按钮点击
    [hmsCustomScanViewController.view removeFromSuperview];
    [hmsCustomScanViewController removeFromParentViewController];
    hmsCustomScanViewController = nil;
}

- (void)albemBtnClick {
    //相册按钮点击
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
    _imagePickerController.allowsEditing = NO;
    _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //全屏弹出
//    _imagePickerController.modalInPresentation =
    [[self topViewControler] presentViewController:_imagePickerController animated:YES completion:^{
        
    }];
}

//自定义view的扫码
- (void)realStartScanWithVC:(UIViewController *)topVC scanVC:(HmsCustomScanViewController *)scanVC{
    if (topVC.navigationController) {
        [topVC.navigationController setNavigationBarHidden:YES];
    }
    
    //首先创建限制区域的大小和frame，如果需要修改限制区域的位置，只需要修改此处的frame即可
    qr_scan_animation_view_ = [[QRScanAnimationView alloc] initWithFrame:CGRectMake(0.1*SCREEN_WIDTH, (SCREEN_HEIGHT - 0.8*SCREEN_WIDTH)/2.0, 0.8*SCREEN_WIDTH, 0.8*SCREEN_WIDTH)];
    [scanVC.view addSubview:qr_scan_animation_view_];
    
    
    //这个是用来设置扫描区域的frame的，这个frame需要注意的是，必须是AVCaptureVideoPreviewLayer所在的layer上的frame
    scan_frame_ = CGRectMake(qr_scan_animation_view_.frame.origin.x,
                             qr_scan_animation_view_.frame.origin.y,
                             qr_scan_animation_view_.bounds.size.height,
                             qr_scan_animation_view_.bounds.size.height);
    //设置扫码检测区域
    scanVC.cutArea = scan_frame_;
    //创建蒙版的View
    qr_mask_view_ = [[QRMaskView alloc] initMaskViewWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) withScanFrame:scan_frame_];
    [scanVC.view addSubview:qr_mask_view_];
    
    NSInteger screenScale = (NSInteger)([UIScreen mainScreen].scale);
    
    //这里的返回按钮需要自定义，
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(12, 44, 44, 44);
    NSString *backImagePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"zwj_scan_plugin_back@%ldx",screenScale] ofType:@"png"];
    [backBtn setImage:[UIImage imageWithContentsOfFile:backImagePath] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [scanVC.view addSubview:backBtn];
    
    //选取照片需要自定义，
    albemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    albemBtn.frame = CGRectMake(SCREEN_WIDTH - (12 + 44), 44, 44, 44);
    NSString *albemImagePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"zwj_scan_plugin_albem@%ldx",screenScale] ofType:@"png"];
    [albemBtn setImage:[UIImage imageWithContentsOfFile:albemImagePath] forState:UIControlStateNormal];
    [albemBtn addTarget:self action:@selector(albemBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [scanVC.view addSubview:albemBtn];
    
    //扫码提示自定义
    tipLab = [[UILabel alloc] init];
    tipLab.frame = CGRectMake(qr_scan_animation_view_.frame.origin.x,
                              qr_scan_animation_view_.frame.origin.y - 40,
                              qr_scan_animation_view_.frame.size.width, 30);
    tipLab.textColor = [UIColor whiteColor];
    tipLab.textAlignment = NSTextAlignmentCenter;
    tipLab.font = [UIFont systemFontOfSize:16];
    tipLab.text = @"将码放入取景框，既可自动扫码";
    [scanVC.view addSubview:tipLab];
    
    //开启动画
    [qr_scan_animation_view_ startAnimation];
}

//CustomizedScan Delegate
- (void)customizedScanDelegateForResult:(NSDictionary *)resultDic{
    //返回结果
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *str = [NSString stringWithFormat:@"%@", resultDic[@"text"]];
        [self->_eventSink success:str];
    });
    
    //停止动画
    [qr_scan_animation_view_ stopAnimation];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSDictionary *dic = [HmsBitMap bitMapForImage:image withOptions:[[HmsScanOptions alloc] initWithScanFormatType:ALL Photo:true]];
    
    //返回结果
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *str = [NSString stringWithFormat:@"%@", dic[@"text"]];
        [self->_eventSink success:str];
    });
    //退出页面
    __weak typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf topViewControler].navigationController != nil) {
            [[strongSelf topViewControler].navigationController popViewControllerAnimated:NO];
        }else{
            [strongSelf backBtnClick];
        }
    }];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    // id 类型不能点语法,所以要先去取出数组中对象
    AVMetadataMachineReadableCodeObject *object = [metadataObjects lastObject];

    if (object == nil) return;
    if ([object.type isEqualToString:AVMetadataObjectTypeQRCode] ){
        NSLog(@"得到的qr字符串为：%@",object.stringValue);
        //返回结果
        
        // .....
    }
}

@end
