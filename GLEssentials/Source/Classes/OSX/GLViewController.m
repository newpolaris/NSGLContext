//
//  GLViewController.m
//  GLEssentials-OSX
//
//  Created by Mac_kdy on 2019. 11. 27..
//  Copyright © 2019년 Dan Omachi. All rights reserved.
//

#import "GLViewController.h"

@interface GLViewController ()

@end

@implementation GLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
}

@end
