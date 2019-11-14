## NSOpenGLView 기반

기존 소스 변경 없이 구현하기 위해 시도한 내용이다

NSOpenGLView에서 setOpenGLContext 함수 호출은,

- 해당 context에 대해 resize
- 해당 context 로의 변경에 대해 정상 작동하게 해준다

하지만, 다른 context 로 변경했을 때 (makeCurrent / setView / clearDrawable / update 호출 등을 통한)

디폴트 framebuffer 크기가 갱신이 안되는 증상이 나타난다.

clearDrawable을 호출할 경우 갱신은 이루어지나, 회색의 배경이 몇 프레임 가량 보인다.

결국, setOpenGLContext 를 쓰지않는 방법을 찾아야 했다.

우선 몇개 알개된 방법 몇가지,

### resize

NSOpenGLView에서 아래 2개 구문은 resize 시 정상 작동하게 해준다
(setOpenGLContext를 호출 하지 않았을 경우)

```
GLint swapInt = 1;
[_currentContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
[_currentContext update];
```

bgfx 이나 filament에 공통적으로 보이는 코드다.
update나 interval을 왜 계속 해야하는지 모르겠지만, 
2줄이 있어야 정상 작동한다. bgfx에서는 resize 시 호출한다 (glcontext_nsgl.mm)

### swapcontext

하나의 view에 여러 context를 쓰는 예제는 없었다

bgfx는 window에 NSOpenGLView를 사용하는데,
새로운 NSOpenGLView를 생성하여 setContentView로 할당하거나,
기존의 view가 있을 경우 addSubview를 호출하는 방식이다.
단일 context와 view가 결합된 구조로 context 교체에 대한 고려가 없다.

filament의 경우, context와 view가 분리되어 있는 구조이다 (createDriver / makeCurrent )
resize시에는 swapchain 를 다시 생성한다
NSOpenGLContetx의 swap Interval 설정은 context 생성시, 
NSOpenGLContext에 대한 update 호출은 makeCurrent에서 이루어진다

makeCurrent 함수내에서, view를 비교하여 바뀌었을때 setView를 호출해준다

위의 방식을 NSOpenGLView에 적용 해보았으나 제대로 작동하지 않았다.

대신, 같은 view 대입시 예외 처리를 예상하고, 아래와 같은 방식을 시도하니
정상 작동하게 되었다

```
// initialize view to make the view update when assigning self again.
[_currentContext setView:nil];

[_currentContext setView:self];
```


### framebuffer 오류 관련

```
Program cannot run with currentOpenGL State
Current draw framebuffer is invalid

GLError GL_INVALID_FRAMEBUFFER_OPERATION
```

기존 구현은 setOpenGLContext 호출에서 호출된 prepareOpenGL 에서 수행하도록 되어있는데,
해당부분을 awakeFromNib 에서 renderer를 초기화 하도록 바꾸니
함수 호출 순서에 따라 위의 오류가 발생하였다.

- OSX 10.14.5: setView 이후 호출할 경우 경고가 발생하지 않았다
- OSX 10.11.6: 같은 소스임에도 경고가 발생하였다. 다만, 경고는 발생했지만 정상 작동하는 것 처럼 보인다.

좀더 render 초기화 순서를 미루던가의 조치가 필요한 것 같다


## NSView 기반

custom view 예제읜 [3] 번과 filament[2] 의 경우 NSView 기반이기 때문에 시도해 보았다


## subView 기반

addSubview를 통해 2개를 추가하여 관리하는 형태
TODO

## CAOpenGLLayer 기반

layer 기반 예제를 바탕으로 2개를 교체하는 시도, 혹은 2개 layer 추가하는 방식
TODO

1. https://github.com/bkaradzic/bgfx/blob/master/src/glcontext_nsgl.mm
2. https://github.com/google/filament/blob/master/filament/backend/src/opengl/PlatformCocoaGL.mm
3. https://gist.github.com/newpolaris/087c68fbebe4fdc9c3dcfbcb35e85410

