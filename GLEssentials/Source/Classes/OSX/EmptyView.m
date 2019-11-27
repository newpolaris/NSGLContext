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
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if(self = [super initWithCoder:decoder])
    {
        [self initCommon];
    }
    return self;
}

- (void)awakeFromNib
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        // Must specify the 3.2 Core Profile to use OpenGL 3.2
#if ESSENTIAL_GL_PRACTICES_SUPPORT_GL3
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
#endif
        0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    
    [self setPixelFormat:pf];
    
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    [self setOpenGLContext:context];

    NSRect rect = NSMakeRect(100, 50, 200, 200);
    view = [[GLEssentialsGLView alloc] initWithFrame:rect];
    [self addSubview:view];
    // [view removeFromSuperview];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    
    // [view setFrameSize:newSize];
    
    CGLLockContext([[view openGLContext] CGLContextObj]);
    
    [[view openGLContext] makeCurrentContext];
    // FRAME BUFFER UPDATE
    [[view openGLContext] update];
    
    CGLUnlockContext([[view openGLContext] CGLContextObj]);
}

- (void)drawRect:(NSRect)dirtyRect {
    // no need
    // [super drawRect:dirtyRect];
    
    CGLLockContext([[view openGLContext] CGLContextObj]);
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    [[self openGLContext] makeCurrentContext];
    static float k = 0;
    k+= 0.05f;
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glClearColor(sin(k), 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    

    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[view openGLContext] CGLContextObj]);
}

@end
