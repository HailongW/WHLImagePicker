//
//  ViewController.m
//  WHLImagePicker
//
//  Created by 王海龙 on 2020/3/24.
//  Copyright © 2020 王海龙. All rights reserved.
//

#import "ViewController.h"
#import "ImagePickerManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[ImagePickerManager sharedInstance] openWithSource:PhotoLibrary];
    
}


@end
