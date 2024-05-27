import ../../common

# settings
const
  SCR_WIDTH = 800
  SCR_HEIGHT = 600

  vertexShaderSource = """#version 320 es
precision highp float;
layout (location = 0) in vec3 aPos;
void main()
{
   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}"""

  fragmentShaderSource = """#version 320 es
precision highp float;
out vec4 FragColor;
void main()
{
   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}"""

import sdl2
import nimgl

type
  Context = object
    wnd: WindowPtr
    glc: GlContextPtr
    rdr: RendererPtr

    program: GLuint

    vao, vbo: GLuint

  ContextPtr = ptr Context

proc createBuffer(ctx: ContextPtr) =
  # set up vertex data (and buffer(s)) and configure vertex attributes
  # ------------------------------------------------------------------
  # add a new set of vertices to form a second triangle (a total of 6 vertices); the vertex attribute configuration remains the same (still one 3-float position vector per vertex)
  var vertices: array[18, GLfloat] = [
                        # first triangle
    -0.9f, -0.5f, 0.0f, # left
    -0.0f, -0.5f, 0.0f, # right
    -0.45f, 0.5f, 0.0f, # top
                        # second triangle
    0.0f, -0.5f, 0.0f,  # left
    0.9f, -0.5f, 0.0f,  # right
    0.45f, 0.5f, 0.0f   # top
  ]

  glGenVertexArrays(1, addr ctx.vao);
  glGenBuffers(1, addr ctx.vbo);
  # bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
  glBindVertexArray(ctx.vao);

  glBindBuffer(GL_ARRAY_BUFFER, ctx.vbo);
  glBufferData(GL_ARRAY_BUFFER, (sizeof vertices).GLsizeiptr, addr vertices, GL_STATIC_DRAW);

  glVertexAttribPointer(0, 3, cGL_FLOAT, false, 3 * sizeof GLfloat, nil);
  glEnableVertexAttribArray(0);

  # note that this is allowed, the call to glVertexAttribPointer registered VBO as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
  glBindBuffer(GL_ARRAY_BUFFER, 0);

  # You can unbind the VAO afterwards so other VAO calls won't accidentally modify this VAO, but this rarely happens. Modifying other
  # VAOs requires a call to glBindVertexArray anyways so we generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
  glBindVertexArray(0);

proc init(ctx: ContextPtr): ContextPtr =
  var wnd = sdl2.createWindow("LearnOpenGL", sdl2.SDL_WINDOWPOS_CENTERED,
      sdl2.SDL_WINDOWPOS_CENTERED, SCR_WIDTH, SCR_HEIGHT,
      sdl2.SDL_WINDOW_OPENGL + sdl2.SDL_WINDOW_SHOWN)

  var glc = createOpenGLContext(wnd)
  if glc == nil:
    quit(1)

  var rdr = sdl2.createRenderer(wnd, -1, Renderer_Accelerated + Renderer_TargetTexture)
  if rdr == nil:
    quit(1)

  discard sdl2.glMakeCurrent(wnd, glc)

  ctx.program = loadShaderProgram(vertexShaderSource, fragmentShaderSource)

  ctx.createBuffer

  ctx.wnd = wnd
  ctx.glc = glc
  ctx.rdr = rdr

  result = ctx

proc destroy(ctx: ContextPtr) =
  ctx.rdr.destroy
  ctx.wnd.destroy

  # optional: de-allocate all resources once they've outlived their purpose:
  # ------------------------------------------------------------------------
  glDeleteVertexArrays(1, addr ctx.vao);
  glDeleteBuffers(1, addr ctx.vbo);
  glDeleteProgram(ctx.program);

# whenever the window size changed (by OS or user resize) this callback function executes
proc resize(ctx: ContextPtr, width, height: cint) =
  # make sure the viewport matches the new window dimensions; note that width and
  # height will be significantly larger than specified on retina displays.
  glViewport(0, 0, width, height);

proc draw(ctx: ContextPtr) =
  # render
  # ------
  glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);

  # draw our first triangle
  glUseProgram(ctx.program);
  # seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
  glBindVertexArray(ctx.vao);
  # set the count to 6 since we're drawing 6 vertices now (2 triangles); not 3!
  glDrawArrays(GL_TRIANGLES, 0, 6);
  # glBindVertexArray(0); # no need to unbind it every time

  # sdl: swap buffers
  sdl2.glSwapWindow(ctx.wnd)

proc main(): void =
  var ctx = create(Context, 1).init()
  defer: ctx.destroy

  # when defined(windows):
  #   # uncomment this call to draw in wireframe polygons.
  #   glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

  var e: sdl2.Event
  while true:
    var quit = false

    while sdl2.pollEvent(e):
      if e.kind == sdl2.QuitEvent:
        quit = true
        break
      if e.kind == sdl2.WindowEvent and e.window.event == WindowEvent_Resized:
        ctx.resize(e.window.data1, e.window.data2)

    if quit:
      break

    ctx.draw

main()
