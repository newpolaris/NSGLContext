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

// in OSX 10.12.6 ~ 10.11.6
// viewDidLoad - framebuffer state or invalid framebuffer error ocurrs
//             & gl create setcontext not working - shows empty window
- (void)viewDidAppear
{
    [super viewDidAppear];
    
    GLEssentialsView* view = (GLEssentialsView*)self.view;
    [view configure];
}

@end
