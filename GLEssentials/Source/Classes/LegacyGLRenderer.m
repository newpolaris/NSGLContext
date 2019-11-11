#import "LegacyGLRenderer.h"

@implementation LegacyGLRenderer

- (instancetype)initWithDefaultFBO:(GLuint)defaultFBOName {

    if((self = [super init]))
    {
    }
    return self;
}

- (void)render {
    // Always use this clear color
    glClearColor(1.0f, 0.4f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)resizeWithWidth:(GLuint)width AndHeight:(GLuint)height {
    glViewport(0, 0, width, height);
}

@end
