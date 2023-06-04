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

Wall :: struct {
    x1, y1,
    x2, y2 : i32,
    color : u8,
}

Sector :: struct {
    wallStart, wallEnd : i32,
    bottom, top : i32,
    centerX, centerY : i32,
    distanceY : i32,
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

Trigonometry :: struct {
    cos, sin: [360]f32,
}

EngineContext :: struct {
    window : ^SDL.Window,
    renderer : ^SDL.Renderer,
    keys : Buttons,
    time : EngineTime,
    tick: int,
}

Player :: struct {
    x, y, z: i32,
    a, l : i32,
}

// Declare global state
engine : EngineContext
trig : Trigonometry
player : Player
walls : [30]Wall
sectors : [30]Sector

pixelWidth : i32 = 160
pixelHeight : i32 = 120
pixelRatio : i32 = 4

halfWidth : i32 = pixelWidth / 2
halfHeight : i32 = pixelHeight / 2

sectorCount : i32 = 4

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
    
    // Game Init
    Init()

    // Game loop
    currentState : GameState = .PLAY
    loop: for currentState != .EXIT {
        // Process input
        event: SDL.Event
        for SDL.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    currentState = .EXIT
                case .KEYDOWN:
                    #partial switch event.key.keysym.sym {
                        case .w:
                            engine.keys.w = true
                        case .s:
                            engine.keys.s = true
                        case .a:
                            engine.keys.a = true
                        case .d:
                            engine.keys.d = true
                        case .m:
                            engine.keys.m = true
                        case .COMMA:
                            engine.keys.sl = true
                        case .PERIOD:
                            engine.keys.sr = true
                    } 
                case .KEYUP:
                    #partial switch event.key.keysym.sym {
                        case .w:
                            engine.keys.w = false
                        case .s:
                            engine.keys.s = false
                        case .a:
                            engine.keys.a = false
                        case .d:
                            engine.keys.d = false
                        case .m:
                            engine.keys.m = false
                        case .COMMA:
                            engine.keys.sl = false
                        case .PERIOD:
                            engine.keys.sr = false
                    } 
            }
        }

        Display()
    }
}

RenderCustomPixel :: proc(x, y : i32, c : u8) {
    if x > 0 && x < pixelWidth && y > 0 && y < pixelWidth {
        testRect := SDL.Rect{(i32)(x*pixelRatio), (i32)((pixelHeight - y)*pixelRatio), (i32)(pixelRatio), (i32)(pixelRatio)}
        SDL.SetRenderDrawColor(engine.renderer, palette[c].r, palette[c].g, palette[c].b, 255)
        SDL.RenderFillRect(engine.renderer, &testRect)
    }
}

ClearBackground :: proc() {
    SDL.SetRenderDrawColor(engine.renderer, palette[8].r, palette[8].g, palette[8].b, 255)
    SDL.RenderClear(engine.renderer)
}

MovePlayer :: proc() {
    if engine.keys.a && !engine.keys.m { player.a -= 4; if player.a < 0 { player.a += 360 }}
    if engine.keys.d && !engine.keys.m { player.a += 4; if player.a > 359 { player.a -= 360 }}
    
    dx := (i32)(trig.sin[player.a] * 10.0)
    dy := (i32)(trig.cos[player.a] * 10.0)
    if engine.keys.w && !engine.keys.m { player.x += dx; player.y += dy }
    if engine.keys.s && !engine.keys.m { player.x -= dx; player.y -= dy }

    if engine.keys.sr { player.x += dy; player.y -= dx }
    if engine.keys.sl { player.x -= dy; player.y += dx }

    if engine.keys.a && engine.keys.m { player.l -= 1 }
    if engine.keys.d && engine.keys.m { player.l += 1 }
    if engine.keys.w && engine.keys.m { player.z -= 4 }
    if engine.keys.s && engine.keys.m { player.z += 4 }
}

ClipBehindPlayer :: proc(x1, y1, z1, x2, y2, z2 : i32) -> (x, y, z : i32) {
    da : f32 = (f32)(y1) // distance plane -> point a
    db : f32 = (f32)(y2) // distance plane -> point b
    d : f32 = da - db; if d == 0 { d = 1 }
    s : f32 = da / d // intersection factor (0 - 1)
    
    x = x1 + (i32)(s * ((f32)(x2) - (f32)(x1)))
    y = y1 + (i32)(s * ((f32)(y2) - (f32)(y1))); if y == 0 { y = 1 }
    z = z1 + (i32)(s * ((f32)(z2) - (f32)(z1)))

    fmt.println(x, y, z)
    return x, y, z
}

DrawWall :: proc(x1, x2, b1, b2, t1, t2 : i32, color : u8) {
    dyb : i32 = b2 - b1                       // y distance of bottom
    dyt : i32 = t2 - t1                       // y distance of top
    dx : i32 = x2 - x1; if dx == 0 { dx = 1 } // x distance
    xs : i32 = x1                             // intial x
    // clip x
    clip_x1 := x1
    clip_x2 := x2
    if x1 < 0 { clip_x1 = 0 }
    if x2 < 0 { clip_x2 = 0 }
    if x1 > pixelWidth { clip_x1 = pixelWidth }
    if x2 > pixelWidth { clip_x2 = pixelWidth }
    // draw x vertical lines
    for x : i32 = clip_x1; x < clip_x2; x+=1 {
        y1 : i32 = dyb * (x - xs) / dx + b1
        y2 : i32 = dyt * (x - xs) / dx + t1
        // clip y
        clip_y1 := y1
        clip_y2 := y2
        if y1 < 0 { clip_y1 = 0 }
        if y2 < 0 { clip_y2 = 0 }
        if y1 > pixelWidth { clip_y1 = pixelWidth }
        if y2 > pixelWidth { clip_y2 = pixelWidth }
        for y : i32 = clip_y1; y < clip_y2; y+=1 {
            RenderCustomPixel(x, y, color)
        }
    }
}

Distance :: proc(x1, y1, x2, y2 : i32) -> i32 {
    return (i32)(math.sqrt(math.pow((f32)(x2 - x1), 2.0) + math.pow((f32)(y2 - y1), 2.0)))
}

Draw3D :: proc() {
    wx, wy, wz : [4]i32
    cs := trig.cos[player.a]
    sn := trig.sin[player.a]

    // Order sectors by last distance
    for i : i32 = 0; i < sectorCount; i += 1 {
        for j : i32 = 0; j < sectorCount - i - 1; j += 1 {
            if sectors[j].distanceY < sectors[j + 1].distanceY {
                temp : Sector = sectors[j]
                sectors[j] = sectors[j + 1]
                sectors[j + 1] = temp
            }
        }
    }

    // Draw Sectors
    for s : i32 = 0; s < sectorCount; s += 1 {
        sectors[s].distanceY = 0;
        for w := sectors[s].wallStart; w < sectors[s].wallEnd; w += 1 {
            // Offset bottom 2 points by player
            x1 : i32 = walls[w].x1 - player.x
            y1 : i32 = walls[w].y1 - player.y
            x2 : i32 = walls[w].x2 - player.x
            y2 : i32 = walls[w].y2 - player.y
            // World X position
            wx[0] = (i32)((f32)(x1) * cs - (f32)(y1) * sn)
            wx[1] = (i32)((f32)(x2) * cs - (f32)(y2) * sn)
            wx[2] = wx[0]
            wx[3] = wx[1]
            // World Y position (depth)
            wy[0] = (i32)((f32)(y1) * cs + (f32)(x1) * sn)
            wy[1] = (i32)((f32)(y2) * cs + (f32)(x2) * sn)
            wy[2] = wy[0]
            wy[3] = wy[1]
            sectors[s].distanceY += Distance(0, 0, (wx[0] + wx[1]) / 2, (wy[0] + wy[1]) / 2)
            // World Z position (height)
            wz[0] = sectors[s].bottom - player.z + (i32)((f32)(player.l * wy[0]) / 32.0)
            wz[1] = sectors[s].bottom - player.z + (i32)((f32)(player.l * wy[1]) / 32.0)
            wz[2] = wz[0] + sectors[s].top
            wz[3] = wz[1] + sectors[s].top
            // Don't draw if behind player
            if wy[0] < 1 && wy[1] < 1 { continue } // Wall completely behind player
            if wy[0] < 1 {
                wx[0], wy[0], wz[0] = ClipBehindPlayer(wx[0], wy[0], wz[0], wx[1], wy[1], wz[1])
                wx[2], wy[2], wz[2] = ClipBehindPlayer(wx[2], wy[2], wz[2], wx[3], wy[3], wz[3])
            }
            if wy[1] < 1 {
                wx[1], wy[1], wz[1] = ClipBehindPlayer(wx[1], wy[1], wz[1], wx[0], wy[0], wz[0])
                wx[3], wy[3], wz[3] = ClipBehindPlayer(wx[3], wy[3], wz[3], wx[2], wy[2], wz[2])
            }
            // Screen X Y position
            wx[0] = wx[0] * 200 / wy[0] + halfWidth; wy[0] = wz[0] * 200 / wy[0] + halfHeight
            wx[1] = wx[1] * 200 / wy[1] + halfWidth; wy[1] = wz[1] * 200 / wy[1] + halfHeight
            wx[2] = wx[2] * 200 / wy[2] + halfWidth; wy[2] = wz[2] * 200 / wy[2] + halfHeight
            wx[3] = wx[3] * 200 / wy[3] + halfWidth; wy[3] = wz[3] * 200 / wy[3] + halfHeight
            // draw points
            DrawWall(wx[0], wx[1], wy[0], wy[1], wy[2], wy[3], walls[w].color)
        }
        sectors[s].distanceY /= sectors[s].wallEnd - sectors[s].wallStart
    }
}

Display :: proc() {
    if engine.time.fr1 - engine.time.fr2 >= 50  {
        ClearBackground()
        MovePlayer()
        Draw3D()

        engine.time.fr2 = engine.time.fr1
        SDL.RenderPresent(engine.renderer)
    }

    engine.time.fr1 = SDL.GetTicks()
}

testSectors : [16]i32 = {
    // wall start, end, bottom, top
    0, 4, 0, 40, // Sector 1
    4, 8, 0, 40, // Sector 2
    8, 12, 0, 40, // Sector 3
    12, 16, 0, 40, // Sector 4
}

testWalls : [80]i32 = {
     0, 0, 32, 0,  0,
    32, 0, 32,32,  1,
    32,32,  0,32,  0,
     0,32,  0, 0,  1,

    64, 0, 96, 0, 31,
    96, 0, 96,32, 32,
    96,32, 64,32, 31,
    64,32, 64, 0, 32,

    64,64, 96,64, 16,
    96,64, 96,96, 17,
    96,96, 64,96, 16,
    64,96, 64,64, 17,

     0,64, 32,64, 35,
    32,64, 32,96, 36,
    32,96,  0,96, 35,
     0,96,  0,64, 36,
}

Init :: proc() {
    // Store sin/cos in degrees
    for i := 0; i < 360; i += 1 {
        trig.cos[i] = math.cos_f32((f32)(i) / 180.0 * math.PI)
        trig.sin[i] = math.sin_f32((f32)(i) / 180.0 * math.PI)
    }
    // Init player
    player = Player{70, -110, 20, 0, 0}
    // Load sectors
    aggregator, aggregator2 : int
    for s : i32 = 0; s < sectorCount; s += 1 {
        sectors[s].wallStart = testSectors[aggregator + 0]
        sectors[s].wallEnd = testSectors[aggregator + 1]
        sectors[s].bottom = testSectors[aggregator + 2]
        sectors[s].top = testSectors[aggregator + 3]
        aggregator += 4
        for w : i32 = sectors[s].wallStart; w < sectors[s].wallEnd; w += 1 {
            walls[w].x1 = testWalls[aggregator2 + 0]
            walls[w].y1 = testWalls[aggregator2 + 1]
            walls[w].x2 = testWalls[aggregator2 + 2]
            walls[w].y2 = testWalls[aggregator2 + 3]
            walls[w].color = (u8)(testWalls[aggregator2 + 4])
            aggregator2 += 5
        }
    }
}