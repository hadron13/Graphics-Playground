package playground

import "vendor:sdl3"
import gl "vendor:OpenGL"
import "core:fmt"
import "core:os"
import "core:time"
import "core:c"

main :: proc(){
    if(!sdl3.Init({.VIDEO , .EVENTS})){
        return
    }
    defer sdl3.Quit()
    
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_MAJOR_VERSION, 3)
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_MINOR_VERSION, 3)
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_PROFILE_MASK, i32(sdl3.GLProfile.CORE))
    sdl3.GL_SetAttribute(sdl3.GLAttr.FRAMEBUFFER_SRGB_CAPABLE, 1)

    window := sdl3.CreateWindow("Playground", 1000, 1400, {.OPENGL, .RESIZABLE})
    defer sdl3.DestroyWindow(window)

    gl_context := sdl3.GL_CreateContext(window)
    defer sdl3.GL_DestroyContext(gl_context)

    sdl3.GL_SetSwapInterval(-1)
   
    gl.load_up_to(4, 6, sdl3.gl_set_proc_address)

    fmt.printfln("loaded OpenGL version %s", gl.GetString(gl.VERSION))
    fmt.printfln("vendor: %s", gl.GetString(gl.VENDOR) )
    
    gl.Enable(gl.FRAMEBUFFER_SRGB)

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


    VERTEX_SHADER_PATH :: "playground/shaders/generic.vert.glsl"
    FRAGMENT_SHADER_PATH :: "playground/shaders/raymarch.frag.glsl"

    shader, ok := gl.load_shaders_file( VERTEX_SHADER_PATH, FRAGMENT_SHADER_PATH)
    uniforms := gl.get_uniforms_from_program(shader)

    if !ok {
        a, b, c, d := gl.get_last_error_messages()
        fmt.printfln("Could not compile shaders\n %s\n %s", a, c)
        return
    }else{
        fmt.printfln("Shaders loaded")
    }
    stat, err := os.stat(FRAGMENT_SHADER_PATH)
    last_modification := stat.modification_time

    width, height : c.int
    sdl3.GetWindowSize(window, &width, &height)

    loop:
    for{
        event : sdl3.Event
        for sdl3.PollEvent(&event){
            #partial switch(event.type){
                case .QUIT:
                    break loop
                case .KEY_UP:
                    if(event.key.key == sdl3.GetKeyFromName("r")){
                        shader, ok = gl.load_shaders_file(VERTEX_SHADER_PATH, FRAGMENT_SHADER_PATH)
                        uniforms = gl.get_uniforms_from_program(shader)

                        if !ok {
                            a, b, c, d := gl.get_last_error_messages()
                            fmt.printfln("Could not compile shaders\n %s\n %s", a, c)
                        }else{
                            fmt.printfln("Shaders loaded")
                        }
                    }
                case .WINDOW_RESIZED:
                    sdl3.GetWindowSize(window, &width, &height)
                    gl.Viewport(0, 0, width, height)
                
            }
        }
        
        if stat, err = os.stat(FRAGMENT_SHADER_PATH); time.diff(last_modification, stat.modification_time) != 0{
            shader, ok = gl.load_shaders_file(VERTEX_SHADER_PATH, FRAGMENT_SHADER_PATH)
            uniforms = gl.get_uniforms_from_program(shader)

            if !ok {
                a, b, c, d := gl.get_last_error_messages()
                fmt.printfln("Could not compile shaders\n %s\n %s", a, c)
            }else{
                fmt.printfln("Shaders loaded")
            }
            last_modification = stat.modification_time
        }

        

        gl.UseProgram(shader) 
        gl.Uniform2f(uniforms["resolution"].location, f32(width), f32(height));
        gl.ClearColor(0.1, 0.1, 0.1, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        
        gl.Uniform1f(uniforms["time"].location, f32(sdl3.GetTicks())/1000.0)
        gl.BindVertexArray(quad_vao)

        gl.DrawArrays(gl.TRIANGLES, 0, 6)

        sdl3.GL_SwapWindow(window)
    }



}
