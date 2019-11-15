/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Window controller subclass.
 */

#import "GLEssentialsWindowController.h"
#import "GLEssentialsFullscreenWindow.h"

@interface GLEssentialsWindowController ()
{
    // Non-Fullscreen window (also the initial window)
    NSWindow* _standardWindow;
}
@end

@implementation GLEssentialsWindowController

- (instancetype)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];

	if (self)
	{
    }

	return self;
}

- (void)swapContext
{
    GLEssentialsView* view = (GLEssentialsView*)self.window.contentView;
    [view swapContext];
}

- (void)keyDown:(NSEvent *)event
{
	unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];

	switch (c)
	{
        case 'a':
            [self swapContext];
            return;
	}

	// Allow other character to be handled (or not and beep)
	[super keyDown:event];
}

@end
