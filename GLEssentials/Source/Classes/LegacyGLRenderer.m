#import "LegacyGLRenderer.h"
#import <AppKit/AppKit.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

@implementation LegacyGLRenderer
{
    NSOpenGLContext* context;
    GLuint program;
    GLuint vertexBuffer;
}

- (void)dealloc
{
    [context makeCurrentContext];
    
    glDeleteProgram(program);
    program = 0;
    glDeleteBuffers(1, &vertexBuffer);
    vertexBuffer = 0;
}

- (bool)createProgram
{
    char vertex[] = "\
        uniform mat4 mat; \
        attribute vec2 position; \
        void main() { \
            gl_Position = mat * vec4(position, 0.0, 1.0); \
        }";

    char fragment[] = "\
        void main() {  \
            gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0); \
        }";

    GLint  vertexShader = [self createShader:GL_VERTEX_SHADER
                                        Code:vertex];
         
    GLuint fragmentShader = [self createShader:GL_FRAGMENT_SHADER
                                          Code:fragment];

    GLuint prog = glCreateProgram();
    glAttachShader(prog, vertexShader);
    glDeleteShader(vertexShader);

    glAttachShader(prog, fragmentShader);
    glDeleteShader(fragmentShader);

    GLint logLength;

    glLinkProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s\n", log);
        free(log);
    }

    GLint status;
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to link program");
        glDeleteProgram(prog);
        return false;
    }

    glValidateProgram(prog);

    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
    {
        // 'status' set to 0 here does NOT indicate the program itself is invalid,
        //   but rather the state OpenGL was set to when glValidateProgram was called was
        //   not valid for this program to run (i.e. Given the CURRENT openGL state,
        //   draw call with this program will fail).  You may still be able to use this
        //   program if certain OpenGL state is set before a draw is made.  For instance,
        //   'status' could be 0 because no VAO was bound and so long as one is bound
        //   before drawing with this program, it will not be an issue.
        NSLog(@"Program cannot run with current OpenGL State");
    }

    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s\n", log);
        free(log);

        //glDeleteProgram(prog);
        //return false;
    }

    glUseProgram(prog);
    program = prog;
    return true;
}

- (bool)create
{
    [self createProgram];
    
    GLfloat vertices[] = {
        -0.5f, -0.5f,
         0.5f, -0.5f,
         0.0f,  0.5f,
    };
    
    GLuint vbo;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    vertexBuffer = vbo;
    
    return true;
}

- (instancetype)initWithDefaultFBO:(GLuint)defaultFBOName withContext:(NSOpenGLContext*)ctx
{
    if((self = [super init]))
    {
        context = ctx;
        [context makeCurrentContext];
        [self create];
    }
    return self;
}

- (void)applyRotation:(float)radians
{
    float s = sin(radians);
    float c = cos(radians);
    float rot[16] = {
        c,-s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
    
    GLint matLocation = glGetUniformLocation(program, "mat");
    glUniformMatrix4fv(matLocation, 1, 0, &rot[0]);
}

- (GLuint)createShader:(GLenum)type Code:(const char*)code
{
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &code, NULL);
    glCompileShader(shader);
    GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        NSLog(@"Frag Shader compile log:\n%s\n", log);
        free(log);
    }
    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        NSLog(@"Failed to compile frag shader:\n%s\n", code);
        return 0;
    }
    return shader;
}

- (void)render {
    static float radians = 0.0;
    radians += 0.01f;
    
    // Always use this clear color
    glClearColor(1.0f, 0.4f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Bind our default FBO to render to the screen
    glBindFramebuffer(GL_FRAMEBUFFER, _defaultFBOName);
    glUseProgram(program);
    
    [self applyRotation:radians];
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glDisableVertexAttribArray(0);
}

- (void)resizeWithWidth:(GLuint)width AndHeight:(GLuint)height {
    glViewport(0, 0, width, height);
}

@end
