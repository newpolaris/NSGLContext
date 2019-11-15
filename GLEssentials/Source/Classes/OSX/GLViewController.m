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

- (id)init
{
    self = [super init];
    
    if(self)
    {
        [self initCommon];
    }
    return self;
}

// Called when loaded from nib
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

// called when loaded from storyboard
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

- (void)initCommon
{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // in OSX 10.11.6 framebuffer state or invalid framebuffer error ocurrs
    GLEssentialsView* view = (GLEssentialsView*)self.view;
    [view configure];
}


@end
