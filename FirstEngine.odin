package main

import "core:fmt"
import img "core:image"
import "core:math"
import "core:math/noise"
import "core:os"
import "core:slice"

import gl "vendor:OpenGL"
import SDL "vendor:sdl2"

GameState :: enum{PLAY, EXIT}

Buttons :: struct {
    w, s, a, d,
    sl, sr,
    m : bool,
}

EngineTime :: struct {
    fr1, fr2 : u32,
}

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
palette := [256]Color{
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

EngineContext :: struct {
    window : ^SDL.Window,
    renderer : ^SDL.Renderer,
    keys : Buttons,
    time : EngineTime,
    tick: int,
}

// Declare global state
engine : EngineContext

pixelWidth : i16 = 160
pixelHeight : i16 = 120
pixelRatio : i16 = 4

halfWidth : i16 = pixelWidth / 2
halfHeight : i16 = pixelHeight / 2

main :: proc() {
    // Initialize SDL
    SDL.Init({.TIMER, .AUDIO, .VIDEO, .EVENTS});
    defer SDL.Quit()

    // Create window and renderer for app
    error := SDL.CreateWindowAndRenderer(
        (i32)(pixelWidth*pixelRatio), (i32)(pixelHeight*pixelRatio),
        SDL.WINDOW_SHOWN,
        &engine.window, &engine.renderer)
    if error != 0 {
        fmt.eprintln(SDL.GetError())
        return
    }
    defer(SDL.DestroyRenderer(engine.renderer))
    defer(SDL.DestroyWindow(engine.window))

    // TODO: Add sdl based rendering
    

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

        Display()
    }
}

RenderCustomPixel :: proc(x, y : i16, c : u8) {
    testRect := SDL.Rect{(i32)(x*pixelRatio), (i32)(y*pixelRatio), (i32)(pixelRatio), (i32)(pixelRatio)}
    SDL.SetRenderDrawColor(engine.renderer, palette[c].r, palette[c].g, palette[c].b, 255)
    SDL.RenderFillRect(engine.renderer, &testRect)
}

ClearBackground :: proc() {
    SDL.SetRenderDrawColor(engine.renderer, palette[8].r, palette[8].g, palette[8].b, 255)
    SDL.RenderClear(engine.renderer)
}

MovePlayer :: proc() {
    if engine.keys.a && !engine.keys.m { fmt.println("left") }
    if engine.keys.d && !engine.keys.m { fmt.println("right") }
    if engine.keys.w && !engine.keys.m { fmt.println("up") }
    if engine.keys.s && !engine.keys.m { fmt.println("down") }

    if engine.keys.sl { fmt.println("strafe left") }
    if engine.keys.sr { fmt.println("strafe right") }

    if engine.keys.a && engine.keys.m { fmt.println("look up") }
    if engine.keys.d && engine.keys.m { fmt.println("look down") }
    if engine.keys.w && engine.keys.m { fmt.println("move up") }
    if engine.keys.s && engine.keys.m { fmt.println("move down") }
}

Draw3D :: proc() {
    c : u8 = 0
    for y : i16 = 0; y < halfHeight; y+=1 {
        for x : i16 = 0; x < halfWidth; x+=1 {
            RenderCustomPixel(x, y, c)
            c += 1
        }
    }
    //frame rate
    engine.tick += 1
    if engine.tick > 20 { engine.tick = 0 }
    RenderCustomPixel(halfWidth, halfHeight + (i16)(engine.tick), 0)
}

Display :: proc() {
    if(engine.time.fr1-engine.time.fr2>=50) {
        ClearBackground()
        MovePlayer()
        Draw3D()

        engine.time.fr2 = engine.time.fr1
        SDL.RenderPresent(engine.renderer)
    }

    engine.time.fr1 = SDL.GetTicks()
}

GenerateTexture :: proc(texSource: Texture, allocator := context.allocator, loc := #caller_location) -> []u8 {
    result := make([]u8, len(texSource.pixels) * 3, allocator, loc)
    for color, index in texSource.pixels {
        result[index * 3] = palette[color].r
        result[index * 3 + 1] = palette[color].g
        result[index * 3 + 2] = palette[color].b
    }
    return result
}