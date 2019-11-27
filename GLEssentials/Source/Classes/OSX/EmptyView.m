//
//  EmptyView.m
//  GLEssentials-OSX
//
//  Created by Mac_kdy on 2019. 11. 27..
//  Copyright © 2019년 Dan Omachi. All rights reserved.
//

#import "EmptyView.h"
#import "GLEssentialsGLView.h"

@implementation EmptyView
{
    GLEssentialsGLView* view;
}

- (void)initCommon
{
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor whiteColor].CGColor;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if((self = [super initWithFrame:frameRect]))
    {
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if(self = [super initWithCoder:decoder])
    {
    }
    return self;
}

- (void)awakeFromNib
{
    view = [[GLEssentialsGLView alloc] initWithFrame:NSZeroRect];
    [self addSubview:view];
}

- (void)setFrameSize:(NSSize)newSize
{

    [super setFrameSize:newSize];
    
    CGLLockContext([[view openGLContext] CGLContextObj]);
    
    [view setFrameSize:newSize];
    

    [[view openGLContext] makeCurrentContext];
    [[view openGLContext] update];
    
    CGLUnlockContext([[view openGLContext] CGLContextObj]);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
