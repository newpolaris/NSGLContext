//
//  NSViewController+GLViewController.m
//  GLEssentials-OSX
//
//  Created by peter.d.kim on 14/11/2019.
//  Copyright © 2019 Dan Omachi. All rights reserved.
//

#import "GLViewController.h"

#import <AppKit/AppKit.h>
#import "GLEssentialsView.h"


@implementation GLViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    GLEssentialsView* view = (GLEssentialsView*)self.view;
    [view configure];
}


@end
