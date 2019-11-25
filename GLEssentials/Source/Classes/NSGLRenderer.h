#pragma once
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@protocol NSGLRenderer <NSObject>

- (instancetype)initWithDefaultFBO:(GLuint)defaultFBOName withContext:(NSOpenGLContext*)ctx;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;
- (void) render;
- (void) dealloc;

@end
