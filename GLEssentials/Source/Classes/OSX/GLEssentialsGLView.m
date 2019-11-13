/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 OpenGL view subclass.
 */

#import "GLEssentialsGLView.h"
#import "NSGLRenderer.h"
#import "OpenGLRenderer.h"
#import "LegacyGLRenderer.h"

#define SUPPORT_RETINA_RESOLUTION 1

@interface GLEssentialsGLView ()
{
    bool _isLeagacy;
    NSOpenGLContext* _currentContext;
    id<NSGLRenderer> _renderer;
    
    NSOpenGLContext* legacyContext;
    NSOpenGLContext* coreContext;
    id<NSGLRenderer> _legacyRenderer;
    id<NSGLRenderer> _coreRenderer;
}
@end

@implementation GLEssentialsGLView


- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	// There is no autorelease pool when this method is called
	// because it will be called from a background thread.
    // It's important to create one or app can leak objects.
    @autoreleasepool {
        [self drawView];
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

- (void) createLegayContext
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersionLegacy,
        0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
        
    if (!pf)
    {
        NSLog(@"No OpenGL pixel format");
    }
    NSOpenGLContext* context = legacyContext = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    [legacyContext makeCurrentContext];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [context setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    [context setView:self];
}

// TODO: NSopenGLViewBackingLayer display call this function
- (NSOpenGLContext*)openGLContext
{
    return _currentContext;
}

- (void)lockFocus
{
    NSOpenGLContext* context;
    [super lockFocus];
    
    context = [self openGLContext];
    if ([context view] != self) {
        [context setView:self];
    }
}

// this works find in version 10.14, but in 10.11.6, a frame operation
// error occurs during renderer initialization. but, it seems to work
// fine.
// in the case of setOpenGLContext in sample project, the prepareOpenGL
// function is called. It works find in that function.
- (void) awakeFromNib
{
    [self setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
    
    [self createLegayContext];
    _legacyRenderer = [[LegacyGLRenderer alloc] initWithDefaultFBO:0
                                                       withContext:legacyContext];
    
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
	
	if (!pf)
	{
		NSLog(@"No OpenGL pixel format");
	}
	   
    NSOpenGLContext* context = coreContext = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    
#if ESSENTIAL_GL_PRACTICES_SUPPORT_GL3 && defined(DEBUG)
	// When we're using a CoreProfile context, crash if we call a legacy OpenGL function
	// This will make it much more obvious where and when such a function call is made so
	// that we can remove such calls.
	// Without this we'd simply get GL_INVALID_OPERATION error for calling legacy functions
	// but it would be more difficult to see where that function was called.
	CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
#endif

    // The reshape function may have changed the thread to which our OpenGL
    // context is attached before prepareOpenGL and initGL are called.  So call
    // makeCurrentContext to ensure that our OpenGL context current to this
    // thread (i.e. makeCurrentContext directs all OpenGL calls on this thread
    // to [self openGLContext])
    [context makeCurrentContext];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [context setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    [context setView:self];
 
    // Init our renderer.  Use 0 for the defaultFBO which is appropriate for
    // OSX (but not iOS since iOS apps must create their own FBO)
    _coreRenderer = [[OpenGLRenderer alloc] initWithDefaultFBO:0 withContext:context];
    
#if SUPPORT_RETINA_RESOLUTION
    // Opt-In to Retina resolution
    [self setWantsBestResolutionOpenGLSurface:YES];
#endif // SUPPORT_RETINA_RESOLUTION
    
    [self setupDisplayLink];
    
    _renderer = _coreRenderer;
    _currentContext = coreContext;
    _isLeagacy = false;
    
    // setViewport with exist _renderer object
    [self windowDidResize:nil];
}

- (void) setupDisplayLink
{
    // Create a display link capable of being used with all active displays
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    
    // Set the renderer output callback function
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);
    
    // Set the display link for the current renderer
    // CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    // CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    // CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    CVDisplayLinkSetCurrentCGDisplay(displayLink, CGMainDisplayID () );

    
    // Activate the display link
    CVDisplayLinkStart(displayLink);
    
    // Register to be notified when the window closes so we can stop the displaylink
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self window]];
    
    // Register to be notified when the window closes so we can stop the displaylink
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidResize:)
                                                 name:NSWindowDidResizeNotification
                                               object:[self window]];
}

- (void) windowWillClose:(NSNotification*)notification
{
	// Stop the display link when the window is closing because default
	// OpenGL render buffers will be destroyed.  If display link continues to
	// fire without renderbuffers, OpenGL draw calls will set errors.
	
	CVDisplayLinkStop(displayLink);
}


- ( void ) windowDidResize:(NSNotification *)notofication
{
	// We draw on a secondary thread through the display link. However, when
	// resizing the view, -drawRect is called on the main thread.
	// Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing.
	CGLLockContext([_currentContext CGLContextObj]);

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
    
    [_currentContext makeCurrentContext];
    
	// Set the new dimensions in our renderer
	[_renderer resizeWithWidth:viewRectPixels.size.width
                      AndHeight:viewRectPixels.size.height];
    
    // Synchronize buffer swaps with vertical refresh rate
    GLint swapInt = 1;
    [_currentContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    [_currentContext update];
    
	CGLUnlockContext([_currentContext CGLContextObj]);
}

- (void) swapContext
{
    CGLLockContext([coreContext CGLContextObj]);
    CGLLockContext([legacyContext CGLContextObj]);
    
    if (_isLeagacy) {
        _renderer = _coreRenderer;
        _currentContext = coreContext;
        _isLeagacy = false;
    } else {
        _renderer = _legacyRenderer;
        _currentContext = legacyContext;
        _isLeagacy = true;
    }
 
    [_currentContext makeCurrentContext];
    
    // initialize view to make the view update when assigning self again.
    [_currentContext setView:nil];
    
    [_currentContext setView:self];
    // [self reshape];
    
    // Synchronize buffer swaps with vertical refresh rate
    // GLint swapInt = 1;
    //[_currentContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    //[_currentContext update];
    
    CGLUnlockContext([legacyContext CGLContextObj]);
    CGLUnlockContext([coreContext CGLContextObj]);
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

- (void) drawRect: (NSRect) theRect
{
	// Called during resize operations
	
	// Avoid flickering during resize by drawiing	
	[self drawView];
}

- (void) drawView
{	 
	[_currentContext makeCurrentContext];

	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main
	// thread. Add a mutex around to avoid the threads accessing the context
	// simultaneously when resizing
	CGLLockContext([_currentContext CGLContextObj]);

	[_renderer render];

	CGLFlushDrawable([_currentContext CGLContextObj]);
	CGLUnlockContext([_currentContext CGLContextObj]);
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
