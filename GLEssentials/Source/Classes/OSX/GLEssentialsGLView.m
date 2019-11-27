/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 OpenGL view subclass.
 */

#import "GLEssentialsGLView.h"

#import "LegacyGLRenderer.h"
#import "OpenGLRenderer.h"
#include "NSGLRenderer.h"

#define SUPPORT_RETINA_RESOLUTION 1

@interface GLEssentialsGLView ()
{
    NSOpenGLContext* _coreContext;
    NSOpenGLContext* _glContext;
    id<NSGLRenderer> _glRenderer;
    
    id<NSGLRenderer> _renderer;
}
@end

@implementation GLEssentialsGLView


- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
    // There is no autorelease pool when this method is called
    // because it will be called from a background thread.
    // It's important to create one or app can leak objects.
    @autoreleasepool {
        // [REPLACE]
        
        [self drawSlideShow:nil];
        
        // [10.12.6] make current not required. contextlock required
        // [self willPresentRenderbuffer];
        [self drawSlideShowAnimation];
        // [self didPresentRenderBuffer];
    }
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp* now,
                                      const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags* flagsOut,
                                      void* displayLinkContext)
{
    CVReturn result = [(__bridge GLEssentialsGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void)awakeFromNib
{
    [self setContext];
    [self setWantsLayer:YES];
    [self.layer setBackgroundColor:[NSColor blackColor].CGColor];
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        [self setContext];
        [self setWantsLayer:YES];
        [self.layer setBackgroundColor:[NSColor blackColor].CGColor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
    }
    return self;
}

- (void)setContext
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
    
    _coreContext = _glContext = context;
    
    context.view = self;
    
    // [OK in 10.12.6]
    // [Framebuffer smaller in 10.14.6]
    // [self setOpenGLContext:context];
    
    context.view = self;
    
    [self setup];
    
    
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);
    
    // Set the display link for the current renderer
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    
    // Activate the display link
    CVDisplayLinkStart(displayLink);
    
    // Register to be notified when the window closes so we can stop the displaylink
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self window]];
}

- (void)setup
{
    [self setupContext];
    [self setupRenderer];
}

- (void)setupContext
{
    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] =
    {
        // [REPLACE]
        // NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersionLegacy,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        0
    };
    NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
    _glContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
    _glContext.view = self;
    [_glContext makeCurrentContext];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [_glContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    //[self setOpenGLContext:_glContext];
}

- (void)setupRenderer
{
    NSRect presentWindowRect = [self convertRectToBacking:self.bounds];
    NSRect backingBound =  NSMakeRect(0, 0, presentWindowRect.size.width, presentWindowRect.size.height);
    
    _glRenderer = [[LegacyGLRenderer alloc] initWithDefaultFBO:0 withContext:_glContext];
}

- (NSOpenGLContext*)openGLContext
{
    return _glContext;
}

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
    // Make all the OpenGL calls to setup rendering
    //  and build the necessary rendering objects
    [self initGL];
    
  
}

- (void)windowWillClose:(NSNotification*)notification
{
    // Stop the display link when the window is closing because default
    // OpenGL render buffers will be destroyed.  If display link continues to
    // fire without renderbuffers, OpenGL draw calls will set errors.
    
    CVDisplayLinkStop(displayLink);
}

- (void)initGL
{
    // The reshape function may have changed the thread to which our OpenGL
    // context is attached before prepareOpenGL and initGL are called.  So call
    // makeCurrentContext to ensure that our OpenGL context current to this
    // thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
    // to [self openGLContext])
    [_coreContext makeCurrentContext];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [_coreContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    // Init our renderer.  Use 0 for the defaultFBO which is appropriate for
    // OSX (but not iOS since iOS apps must create their own FBO)
    _renderer = [[OpenGLRenderer alloc] initWithDefaultFBO:0 withContext:_coreContext];
}

-(void) swapContext
{
    [_coreContext makeCurrentContext];
    
    // initialize view to make the view update when assigning self again.
    
    // [??]
    // [_coreContext setView:nil];
    
    [_coreContext setView:self];
    
    [_glContext setView:self];
}

- (void)reshape
{
    [super reshape];
    
    // We draw on a secondary thread through the display link. However, when
    // resizing the view, -drawRect is called on the main thread.
    // Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing.
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    // Get the view size in Points
    NSRect viewRectPoints = [self bounds];
    
#if SUPPORT_RETINA_RESOLUTION
    
    // Rendering at retina resolutions will reduce aliasing, but at the potential
    // cost of framerate and battery life due to the GPU needing to render more
    // pixels.
    
    // Any calculations the renderer does which use pixel dimentions, must be
    // in "retina" space.  [NSView convertRectToBacking] converts point sizes
    // to pixel sizes.  Thus the renderer gets the size in pixels, not points,
    // so that it can set it's viewport and perform and other pixel based
    // calculations appropriately.
    // viewRectPixels will be larger than viewRectPoints for retina displays.
    // viewRectPixels will be the same as viewRectPoints for non-retina displays
    NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
    
#else //if !SUPPORT_RETINA_RESOLUTION
    
    // App will typically render faster and use less power rendering at
    // non-retina resolutions since the GPU needs to render less pixels.
    // There is the cost of more aliasing, but it will be no-worse than
    // on a Mac without a retina display.
    
    // Points:Pixels is always 1:1 when not supporting retina resolutions
    NSRect viewRectPixels = viewRectPoints;
    
#endif // !SUPPORT_RETINA_RESOLUTION
    
    // Set the new dimensions in our renderer
    // [REPLACE]
    [_glRenderer resizeWithWidth:viewRectPixels.size.width
                     AndHeight:viewRectPixels.size.height];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)renewGState
{
    // Called whenever graphics state updated (such as window resize)
    
    // OpenGL rendering is not synchronous with other rendering on the OSX.
    // Therefore, call disableScreenUpdatesUntilFlush so the window server
    // doesn't render non-OpenGL content in the window asynchronously from
    // OpenGL content, which could cause flickering.  (non-OpenGL content
    // includes the title bar and drawing done by the app with other APIs)
    [[self window] disableScreenUpdatesUntilFlush];
    
    [super renewGState];
}

- (void)drawRect: (NSRect) theRect
{
    // Called during resize operations
    
    // Avoid flickering during resize by drawiing
    [self drawView];
}

- (void)drawView
{
    [[self openGLContext] makeCurrentContext];
    
    // We draw on a secondary thread through the display link
    // When resizing the view, -reshape is called automatically on the main
    // thread. Add a mutex around to avoid the threads accessing the context
    // simultaneously when resizing
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    // [REPLACE]
    [_glRenderer render];
    
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)useCurrentContext
{
    [_glContext makeCurrentContext];
}

- (void)notUseCurrentContext
{
    [[self openGLContext] makeCurrentContext];
}

- (void)willPresentRenderbuffer
{
    [self useCurrentContext];
}

- (void)didPresentRenderBuffer
{
    [self notUseCurrentContext];
}

- (void)willRequestBuffer
{
    [self useCurrentContext];
}

- (void)didRequestBuffer
{
    [self notUseCurrentContext];
}

- (void)drawSlideShowAnimation
{
    CGLLockContext([[self openGLContext] CGLContextObj]);
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
}

-(void)renderFlush
{
    [self drawSlideShowAnimation];
}

- (void)drawSlideShow:(unsigned char *)image
{
    CGLLockContext([[self openGLContext] CGLContextObj]);

    // [[self openGLContext] setView:nil];
    // [[self openGLContext] setView:self];
    
    [self willPresentRenderbuffer];
    // [self lockFocus];
    [self render:image];
    // [self flush];
    // [self unlockFocus];
    [self didPresentRenderBuffer];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)render:(unsigned char *)image
{
    // [REPLACE]
    // [glRenderer requestRender:image];
    [_glRenderer render];
}

- (void)flush
{
    [_glContext makeCurrentContext];
    [_glContext flushBuffer];
}

// [10.11.6] NSInternalInconsistencyException
// [10.12.6] Error some times; (access violation)
- (void)lockFocus
{
    [super lockFocus];
    if ([_glContext view] != self) {
        _glContext.view = self;
    }
    [_glContext makeCurrentContext];
}

- (void) dealloc
{
    // Stop the display link BEFORE releasing anything in the view
    // otherwise the display link thread may call into the view and crash
    // when it encounters something that has been release
    CVDisplayLinkStop(displayLink);
    
    CVDisplayLinkRelease(displayLink);
}
@end

