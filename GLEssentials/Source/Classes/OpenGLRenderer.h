 /*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The OpenGLRenderer class creates and draws objects.
  Most of the code is OS independent.
 */
#include "glUtil.h"
#include "NSGLRenderer.h"
#import <Foundation/Foundation.h>
#import <Appkit/AppKit.h>

@interface OpenGLRenderer : NSObject <NSGLRenderer>

@property (nonatomic) GLuint defaultFBOName;

- (instancetype)initWithDefaultFBO:(GLuint)defaultFBOName withContext:(NSOpenGLContext*)ctx;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;
- (void) render;
- (void) dealloc;

@end
