package playground

import "vendor:sdl3"
import gl "vendor:OpenGL"
import "core:fmt"

main :: proc(){
    if(!sdl3.Init({.VIDEO , .EVENTS})){
        return
    }
    
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_MAJOR_VERSION, 3)
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_MINOR_VERSION, 3)
    sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_PROFILE_MASK, i32(sdl3.GLProfile.CORE))

    window := sdl3.CreateWindow("Playground", 800, 600, {.OPENGL})
    defer sdl3.DestroyWindow(window)

    gl_context := sdl3.GL_CreateContext(window)
    defer sdl3.GL_DestroyContext(gl_context)
   
    gl.load_up_to(4, 6, sdl3.gl_set_proc_address)

    fmt.printfln("loaded OpenGL version %s", gl.GetString(gl.VERSION))
    fmt.printfln("vendor: %s", gl.GetString(gl.VENDOR) )

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

        sdl3.GL_SwapWindow(window)
    }



}
