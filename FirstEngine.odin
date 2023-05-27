package main

import "core:fmt"
import img "core:image"
import "core:math"
import "core:math/noise"
import "core:os"
import "core:slice"

import gl "vendor:OpenGL"
import SDL "vendor:sdl2"

SEED : i64 = 235235235

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

GameState :: enum{PLAY, EXIT}

Position :: struct {
    x: i16,
    y: i16,
}

Color :: struct {
    r: u8,
    g: u8,
    b: u8,
}

// Palette is Aurora by DawnBringer (https://lospec.com/palette-list/aurora)
Palette := [256]Color{
{0,0,0},{17,17,17},{34,34,34},{51,51,51},{68,68,68},{85,85,85},{102,102,102},{119,119,119},
{136,136,136},{153,153,153},{170,170,170},{187,187,187},{204,204,204},{221,221,221},{238,238,238},{255,255,255},
{0,127,127},{63,191,191},{0,255,255},{191,255,255},{129,129,255},{0,255,0},{63,63,191},{0,0,127},
{15,15,80},{127,0,127},{191,63,191},{245,0,245},{253,129,255},{255,192,203},{255,129,129},{255,0,0},
{191,63,63},{127,0,0},{85,20,20},{127,63,0},{191,127,63},{255,127,0},{255,191,129},{255,255,191},
{255,255,0},{191,191,63},{127,127,0},{0,127,0},{63,191,63},{0,255,0},{175,255,175},{0,191,255},
{0,127,255},{75,125,200},{188,175,192},{203,170,137},{166,160,144},{126,148,148},{110,130,135},{126,110,96},
{160,105,95},{192,120,114},{208,138,116},{225,155,125},{235,170,140},{245,185,155},{246,200,175},{245,225,210},
{127,0,255},{87,59,59},{115,65,60},{142,85,85},{171,115,115},{199,143,143},{227,171,171},{248,210,218},
{227,199,171},{196,158,115},{143,115,87},{115,87,59},{59,45,31},{65,65,35},{115,115,59},{143,143,87},
{162,162,85},{181,181,114},{199,199,143},{218,218,171},{237,237,199},{199,227,171},{171,199,143},{142,190,85},
{115,143,87},{88,125,62},{70,80,50},{25,30,15},{35,80,55},{59,87,59},{80,100,80},{59,115,73},
{87,143,87},{115,171,115},{100,192,130},{143,199,143},{162,216,162},{225,248,250},{180,238,202},{171,227,197},
{135,180,142},{80,125,95},{15,105,70},{30,45,35},{35,65,70},{59,115,115},{100,171,171},{143,199,199},
{171,227,227},{199,241,241},{190,210,240},{171,199,227},{168,185,220},{143,171,199},{87,143,199},{87,115,143},
{59,87,115},{15,25,45},{31,31,59},{59,59,87},{73,73,115},{87,87,143},{115,110,170},{118,118,202},
{143,143,199},{171,171,227},{208,218,248},{227,227,255},{171,143,199},{143,87,199},{115,87,143},{87,59,115},
{60,35,60},{70,50,70},{114,64,114},{143,87,143},{171,87,171},{171,115,171},{235,172,225},{255,220,245},
{227,199,227},{225,185,210},{215,160,190},{199,143,185},{200,125,160},{195,90,145},{75,40,55},{50,22,35},
{40,10,30},{64,24,17},{98,24,0},{165,20,10},{218,32,16},{213,82,74},{255,60,10},{245,90,50},
{255,98,98},{246,189,49},{255,165,60},{215,155,15},{218,110,10},{180,90,0},{160,75,5},{95,50,20},
{83,80,10},{98,98,0},{140,128,90},{172,148,0},{177,177,10},{230,213,90},{255,213,16},{255,234,74},
{200,255,65},{155,240,70},{150,220,25},{115,200,5},{106,168,5},{60,110,20},{40,52,5},{32,70,8},
{12,92,12},{20,150,5},{10,215,10},{20,230,10},{125,255,115},{75,240,90},{0,197,20},{5,180,80},
{28,140,78},{18,56,50},{18,152,128},{6,196,145},{0,222,106},{45,235,168},{60,254,165},{106,255,205},
{145,235,255},{85,230,255},{125,215,240},{8,222,213},{16,156,222},{5,90,92},{22,44,82},{15,55,125},
{0,74,156},{50,100,150},{0,82,246},{24,106,189},{35,120,220},{105,157,195},{74,164,255},{144,176,255},
{90,197,255},{190,185,250},{120,110,240},{74,90,255},{98,65,246},{60,60,245},{16,28,218},{0,16,189},
{35,16,148},{12,33,72},{80,16,176},{96,16,208},{135,50,210},{156,65,255},{189,98,255},{185,145,255},
{215,165,255},{215,195,250},{248,198,252},{230,115,255},{255,82,255},{218,32,224},{189,41,255},{189,16,197},
{140,20,190},{90,24,123},{100,20,100},{65,0,98},{50,10,70},{85,25,55},{160,25,130},{200,0,120},
{255,80,191},{255,106,197},{250,160,185},{252,58,140},{230,30,120},{189,16,57},{152,52,77},{145,20,55}}

Texture :: struct {
    width: u8,
    height: u8,
    pixels: []u8,
}

UVCoords :: struct {
    u: f16,
    v: f16,
}

Vertex :: struct {
    pos: Position,
    tex: UVCoords,
    color: Color,
    pad: u8,
}

Sprite :: struct {
    x: i16,
    y: i16,
    width: i16,
    height: i16,
}

main :: proc() {
    screenWidth : i32 = 1024
    screenHeight : i32 = 768

    // Initialize SDL with all categories
    SDL.Init(SDL.INIT_EVERYTHING);
    defer SDL.Quit()

    // Create window for app
    window := SDL.CreateWindow("Game Engine", SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED, screenWidth, screenHeight, {.OPENGL})
    if window == nil {
        fmt.eprintln("Failed to create window")
        return
    }
    defer SDL.DestroyWindow(window)

    // Create GL Context
    gl_context := SDL.GL_CreateContext(window)
    if gl_context == nil {
        fmt.eprintln("Failed to create GL context")
        return
    }
    defer SDL.GL_DeleteContext(gl_context)

    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, SDL.gl_set_proc_address)

    // create shader program
    shader, shader_ok := gl.load_shaders_file("./colorShading.vert", "./colorShading.frag")
    if !shader_ok {
        fmt.eprintln("Failed to create GLSL shader program")
        return
    }
    defer gl.DeleteProgram(shader)

    gl.UseProgram(shader)

    // Create uniform variables
    textureUniform := gl.GetUniformLocation(shader, "ourTexture")
    if textureUniform == -1 {
        fmt.eprintln("Failed to link to texture uniform in shader")
        return
    }

    /*screenSizeUniform := gl.GetUniformLocation(shader, "screenSize")
    if screenSizeUniform == -1 {
        fmt.eprintln("Failed to link to screen size uniform in shader")
        return
    }*/

    // Create texture
    devTexture := Texture{8, 8, 
        {0,  1,  2,  3,  4,  5,  6,  7,
         8,  9, 10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31,
        16,  0, 16,  0, 16,  0, 16,  0,
        16, 16,  0,  0, 16, 16,  0,  0,
        16, 16, 16, 16,  0,  0,  0,  0,
        248, 249, 250, 251, 252, 253, 254, 255}}

    stonePalette := []u8{5, 6, 7, 8, 9, 10}
    stoneTexture := TextureFromNoise(16, 16, stonePalette)

    tex: u32
    gl.GenTextures(1, &tex); defer gl.DeleteTextures(1, &tex)
    gl.BindTexture(gl.TEXTURE_2D, tex)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
    textureBuffer := GenerateTexture(stoneTexture) // No defer, see 140
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, i32(stoneTexture.width), i32(stoneTexture.height), 0, gl.RGB, gl.UNSIGNED_BYTE, slice.first_ptr(textureBuffer))
    gl.GenerateMipmap(gl.TEXTURE_2D)
    delete(textureBuffer) // Explicit deletion

    // initialization of OpenGL buffers
    vbo, ebo: u32
    gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo); defer gl.DeleteBuffers(1, &ebo)

    // Create sprite
    sprite := Sprite{-1, -1, 2, 2}
    spriteVertices := []Vertex{
        {{sprite.x,                sprite.y},                 {0.0, 0.0}, {255, 255, 255}, 0},
        {{sprite.x + sprite.width, sprite.y},                 {2.0, 0.0}, {255,   0, 255}, 0},
        {{sprite.x,                sprite.y + sprite.height}, {0.0, 2.0}, {255,   0, 255}, 0},
        {{sprite.x + sprite.width, sprite.y + sprite.height}, {2.0, 2.0}, {  0,   0, 255}, 0},
    }

    spriteIndices := []u16{
        0, 1, 2,
        1, 2, 3,
    }

    // Bind vertex buffer object
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(spriteVertices)*size_of(spriteVertices[0]), raw_data(spriteVertices), gl.STATIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.EnableVertexAttribArray(2)
    // Position attribute pointer
    gl.VertexAttribPointer(0, 2, gl.SHORT, false, size_of(spriteVertices[0]), offset_of(spriteVertices[0].pos))
    // Texture attribute pointer
    gl.VertexAttribPointer(1, 2, gl.HALF_FLOAT, false, size_of(spriteVertices[0]), offset_of(spriteVertices[0].tex))
    // Color attribute pointer
    gl.VertexAttribPointer(2, 3, gl.UNSIGNED_BYTE, true, size_of(spriteVertices[0]), offset_of(spriteVertices[0].color))

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(spriteIndices)*size_of(spriteIndices[0]), raw_data(spriteIndices), gl.STATIC_DRAW)

    // Set clear/BG color
    gl.ClearColor(0.0, 0.0, 1.0, 1.0)

    // Game loop
    currentState : GameState = .PLAY
    loop: for currentState != .EXIT {
        // Process input
        event: SDL.Event
        for SDL.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    currentState = .EXIT
            }
        }

        //gl.Uniform2i(screenSizeUniform, screenWidth, screenHeight)

        // Draw game
        gl.ClearDepth(1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_SHORT, nil)

        SDL.GL_SwapWindow(window)
    }
}

GenerateTexture :: proc(texSource: Texture, allocator := context.allocator, loc := #caller_location) -> []u8 {
    result := make([]u8, len(texSource.pixels) * 3, allocator, loc)
    for color, index in texSource.pixels {
        result[index * 3] = Palette[color].r
        result[index * 3 + 1] = Palette[color].g
        result[index * 3 + 2] = Palette[color].b
    }
    return result
}

TextureFromNoise :: proc(width: u8, height: u8, colors: []u8, allocator := context.allocator, loc := #caller_location) -> Texture {
    // Create Struct
    result : Texture
    result.width = width;
    result.height = height;
    result.pixels = make([]u8, u16(width) * u16(height), allocator, loc)

    scale := 2.0
    scaleX := math.PI * 2.0 / f64(width)
    scaleY := math.PI * 2.0 / f64(height)
    latitude : f64 = 0.0
    longitude : f64 = 0.0
    // Populate
    for x in 0..<width {
        for y in 0..<height {
            fmt.println(scale * math.cos(latitude) * math.cos(longitude))

            result.pixels[x + y * width] = PalettizeNoise(colors, noise.noise_3d_improve_xy(SEED, noise.Vec3{scale * math.cos(latitude) * math.cos(longitude), 
                                                                                                  scale * math.cos(latitude) * math.sin(longitude),
                                                                                                  scale * math.sin(latitude)}))
            latitude += scaleY
        }
        longitude += scaleX
        latitude = 0.0
    }

    return result
}

PalettizeNoise :: proc(colors: []u8, value: f32) -> u8 {
    return colors[int((value * 0.5 + 0.5) * f32(len(colors) - 2))]
}