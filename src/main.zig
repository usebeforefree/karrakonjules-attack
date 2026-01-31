const std = @import("std");
const rl = @import("raylib");
const perlin = @import("perlin.zig");
const rg = @import("raygui");

pub const State = struct {
    const GameState = enum {
        intro,
        shop1,
        level1,
        cutscene1,
        outro,
    };

    phase: GameState = .intro,
    pub fn nextPhase(self: *State) void {
        self.phase = std.meta.intToEnum(GameState, @intFromEnum(self.phase) + 1) catch self.phase;
    }
};

var state: State = .{};
var debug_mode: bool = true;

fn getRect(tex: rl.Texture2D) rl.Rectangle {
    return .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(tex.width),
        .height = @floatFromInt(tex.height),
    };
}

fn drawFullscreenCentered(tex: rl.Texture2D) void {
    const sw: f32 = @floatFromInt(rl.getScreenWidth());
    const sh: f32 = @floatFromInt(rl.getScreenHeight());

    const aspect = sh / sw;
    _ = aspect;
    const tw: f32 = @floatFromInt(tex.width);
    const th: f32 = @floatFromInt(tex.height);

    const ratio = sh / th;

    const center = sw / 2;

    const target_width = tw * ratio;

    const screen_rect: rl.Rectangle = .{
        .x = center - target_width / 2,
        .y = 0,
        .width = target_width,
        .height = th * ratio,
    };

    tex.drawPro(getRect(tex), screen_rect, .{ .x = 0, .y = 0 }, 0, .white);
}

pub fn drawSpriteCentered(tex: rl.Texture2D, x: f32, y: f32, scale: f32, rot: f32) void {
    const rect: rl.Rectangle = .{
        .x = x,
        .y = y,
        .width = @as(f32, @floatFromInt(tex.width)) * scale,
        .height = @as(f32, @floatFromInt(tex.height)) * scale,
    };
    tex.drawPro(
        getRect(tex),
        rect,
        .{
            .x = @as(f32, @floatFromInt(tex.width)) / 2,
            .y = @as(f32, @floatFromInt(tex.height)) / 2,
        },
        rot,
        .white,
    );
}

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.setConfigFlags(.{ .window_resizable = true });

    rl.initWindow(screenWidth, screenHeight, "Karrankonjules attack!");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    rg.setStyle(.default, .{ .default = .text_size }, 30);

    const menu_texture = try rl.loadTexture("assets/menu_day.png");
    const sun_rays = try rl.loadTexture("assets/sun_rays.png");

    const rect: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(menu_texture.width),
        .height = @floatFromInt(menu_texture.height),
    };

    _ = rect;

    while (!rl.windowShouldClose()) {
        const screenw: f32 = @floatFromInt(rl.getScreenWidth());
        // const screenh: f32 = @floatFromInt(rl.getScreenHeight());
        const time: f32 = @floatCast(rl.getTime());
        const offset_noise = perlin.noise(f32, perlin.permutation, .{ .x = time, .y = 34.5, .z = 345.3 }) * 100;

        // INPUT
        if (rl.isKeyPressed(.tab)) {
            debug_mode = !debug_mode;
        }
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        drawFullscreenCentered(menu_texture);

        rl.drawText("Karrakonjules attack!", @intFromFloat(offset_noise), 20, 100, .black);

        const sun_rect = getRect(sun_rays);

        sun_rays.drawPro(
            getRect(sun_rays),
            getRect(sun_rays),
            .{ .x = sun_rect.width / 2, .y = sun_rect.height / 2 },
            time * 20,
            .white,
        );

        drawSpriteCentered(sun_rays, screenw / 2, 30, 1, time * 10);

        if (debug_mode) {
            if (rg.button(.{ .height = 35, .width = 200, .x = 10, .y = 10 }, "Next phase")) {
                state.nextPhase();
            }
            _ = rg.label(.{ .height = 75, .width = 100, .x = 10, .y = 30 }, @tagName(state.phase));
        }
    }
}
