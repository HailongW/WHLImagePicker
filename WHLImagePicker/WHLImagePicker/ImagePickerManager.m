//
//  ImagePickerManager.m
//  WHLImagePicker
//
//  Created by 王海龙 on 2020/3/26.
//  Copyright © 2020 王海龙. All rights reserved.
//

#import "ImagePickerManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>

#define PhotoAuthorizationMsg   @"halo App没有权限使用你的相册请在iPhone的\"设置-隐私-照片\"中开启"
#define CameraAuthorizationMsg  @"halo App没有权限使用你的相机请在iPhone的\"设置-隐私-相机\"中开启"

static ImagePickerManager *imagePickerManager;

@interface ImagePickerManager () <UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, strong)   UIImage                 *uploadImage;
@property (nonatomic, copy)     NSString                *currentSource;
@property (nonatomic, strong)   UIImagePickerController *pickerController;

@end

@implementation ImagePickerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imagePickerManager = [[ImagePickerManager alloc] init];
    });
    return imagePickerManager;
}

- (void)openWithSource:(NSString *)source {
    if ([source isEqualToString:PhotoLibrary]) {
        [self openPhotoLibrary];
    }else if ([source isEqualToString:Camera]) {
        [self openCamera];
    }
}

- (void)openCamera {
    if ([self isCanUseCamera]) {
        if ([self isCameraAvailable] && [self cameraSupportTakingPhotos]) {
            self.pickerController = [[UIImagePickerController alloc] init];
            self.pickerController.delegate = self;
            self.pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
//            [[MARouterNavigator currentNavController] presentViewController:self.pickerController animated:NO completion:NULL];
        }
    }else {
        [self alertAuthorizationTips:CameraAuthorizationMsg title:@"开启相机权限"];
    }
}

- (void)openPhotoLibrary {
    if ([self isCanUsePhotoLibrary]) {
        if ([self isPhotoLibraryAvailabel]) {
            self.pickerController = [[UIImagePickerController alloc] init];
            self.pickerController.delegate = self;
            self.pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.pickerController.modalPresentationStyle = UIModalPresentationFullScreen;
            [[self getCurrentViewController].navigationController presentViewController:self.pickerController animated:YES completion:NULL];
        }
    }else {
        [self alertAuthorizationTips:PhotoAuthorizationMsg title:@"开启相册权限"];//相册
    }
}

- (BOOL)isCanUseCamera {
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) {
        return NO;
    }
    return YES;
}

- (BOOL)isCanUsePhotoLibrary {
    PHAuthorizationStatus author = [PHPhotoLibrary authorizationStatus];
    if (author == PHAuthorizationStatusRestricted || author == PHAuthorizationStatusDenied){
        return NO;
    }
    return YES;
}

- (void)alertAuthorizationTips:(NSString *)message title:(NSString *)title{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        NSURL*url =[NSURL URLWithString:@"prefs:root=General&path=Bluetooth"];
//        if (@available(iOS 10.0, *)) {// 使用apple 私有api 审核不通过
//            url = [NSURL URLWithString:@"App-Prefs:root=Bluetooth"];
//        }
//        if ([[UIApplication sharedApplication] canOpenURL:url]) {
//
//             [[UIApplication sharedApplication] openURL:url];
//        };
//    }];
    UIAlertAction *alertAction = nil;
    if (@available(iOS 10.0, *)) {
        alertAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }];
    }else {
        alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
    }
    [alertController addAction:alertAction];
    [[self getCurrentViewController].navigationController presentViewController:self.pickerController animated:YES completion:NULL];
}

#pragma mark - 判断设备是否有摄像头
- (BOOL)isCameraAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

#pragma mark - 判断设备前面摄像头是否可用
- (BOOL)isFrontCameraAvailabel {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

#pragma mark - 判断设备后面摄像头是否可用
- (BOOL)isRearCameraAvailabel {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

#pragma mark - 判断是否支持某种多媒体类型：拍照，视频
- (BOOL)cameraSupportsMedia:(NSString*)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if (paramMediaType.length == 0) {
        NSLog(@"Medis type is empty");
        return NO;
    }
    NSArray *availabelMediaType = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availabelMediaType enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]) {
            result = YES;
            *stop  = YES;
        }
    }];
    return result;
}

/*检查摄像头是否支持录像
 在此处注意我们要将MobileCoreServices 框架添加到项目中，
 然后将其导入：#import <MobileCoreServices/MobileCoreServices.h> 。不然后出现错误使用未声明的标识符 'kUTTypeMovie'
 */
- (BOOL)cameraSupportShootingVideos {
    return [self cameraSupportsMedia:(NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypeCamera];
}

#pragma mark - 检查摄像头是否支持拍照
- (BOOL)cameraSupportTakingPhotos {
    return [self cameraSupportsMedia:(NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

#pragma mark - 相册是否可用
- (BOOL)isPhotoLibraryAvailabel {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
}

#pragma mark - 判断是否可以在相册中选视频
- (BOOL)canUserPickVideosFromPhontoLibrary {
    return [self cameraSupportsMedia:(NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

#pragma mark - 判断是否可以在相册中选择图片
- (BOOL)canUserPickPhotosFromPhotoLibrary {
    return [self cameraSupportsMedia:(NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}


#pragma mark - PickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    //获取拍照后的相片 上传到服务器
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    UIImage *image = nil;
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        if ([picker allowsEditing]) {
            image = [info objectForKey:UIImagePickerControllerEditedImage];
        }else {
            image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
    }
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        //保存到相册， SEL 是必须有参数的回调
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
       
    }
    self.uploadImage = image;
    [self.pickerController dismissViewControllerAnimated:NO completion:^{
//       [self uploadImageRequest];
    }];
}

- (void)image: (UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存图片失败");
    }else {
        NSLog(@"保存图片成功");
    }
}

- (UIViewController *)getCurrentViewController {
    UIViewController *result = nil;
    // 获取默认的window
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    // app默认windowLevel是UIWindowLevelNormal，如果不是，找到它。
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    // 获取window的rootViewController
    result = window.rootViewController;
    while (result.presentedViewController) {
        result = result.presentedViewController;
    }
    if ([result isKindOfClass:[UINavigationController class]]) {
        result = [(UINavigationController *)result visibleViewController];
    }
    if ([result isKindOfClass:[UITabBarController class]]) {
        result = [(UITabBarController *)result selectedViewController];
    }
    return result;
}

@end
