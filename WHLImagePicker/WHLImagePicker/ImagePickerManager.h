//
//  ImagePickerManager.h
//  WHLImagePicker
//
//  Created by 王海龙 on 2020/3/26.
//  Copyright © 2020 王海龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define PhotoLibrary  @"1"
#define Camera        @"2"

@interface ImagePickerManager : NSObject

+ (instancetype)sharedInstance;

- (void)openWithSource:(NSString *)source;

@end

NS_ASSUME_NONNULL_END
