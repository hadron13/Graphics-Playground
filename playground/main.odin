package playground

import "vendor:sdl3"
import gl "vendor:OpenGL"
import "core:fmt"

main :: proc(){
    if(!sdl3.Init({.VIDEO , .EVENTS})){
        return
    }
    defer sdl3.Quit()
    
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_MAJOR_VERSION, 3)
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_MINOR_VERSION, 3)
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_PROFILE_MASK, i32(sdl3.GLProfile.CORE))

    window := sdl3.CreateWindow("Playground", 800, 600, {.OPENGL})
    defer sdl3.DestroyWindow(window)

    gl_context := sdl3.GL_CreateContext(window)
    defer sdl3.GL_DestroyContext(gl_context)

    sdl3.GL_SetSwapInterval(-1)
   
    gl.load_up_to(4, 6, sdl3.gl_set_proc_address)

    fmt.printfln("loaded OpenGL version %s", gl.GetString(gl.VERSION))
    fmt.printfln("vendor: %s", gl.GetString(gl.VENDOR) )

    quad : []f32 = {
       -1.0,-1.0,
       -1.0, 1.0,
        1.0,-1.0,
        1.0,-1.0,
       -1.0, 1.0,
        1.0, 1.0
    }
    
    quad_vbo, quad_vao: u32
    gl.GenVertexArrays(1, &quad_vao)
    gl.GenBuffers(1, &quad_vbo)
    
    gl.BindVertexArray(quad_vao)
    
    gl.BindBuffer(gl.ARRAY_BUFFER, quad_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(quad) * size_of(f32), raw_data(quad), gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * size_of(f32), 0)
    gl.EnableVertexAttribArray(0)

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)


    shader, ok := gl.load_shaders_file("playground/shaders/generic.vert.glsl", "playground/shaders/raymarch.frag.glsl")

    if !ok {
        a, b, c, d := gl.get_last_error_messages()
        fmt.printfln("Could not compile shaders\n %s\n %s", a, c)
        return
    }else{
        fmt.printfln("Shaders loaded")
    }

    loop:
    for{
        event : sdl3.Event
        for sdl3.PollEvent(&event){
            #partial switch(event.type){
                case .QUIT:
                    break loop
            }
        }
        gl.ClearColor(0.1, 0.1, 0.1, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        
        gl.UseProgram(shader)
        gl.BindVertexArray(quad_vao)

        gl.DrawArrays(gl.TRIANGLES, 0, 6)

        sdl3.GL_SwapWindow(window)
    }



}
