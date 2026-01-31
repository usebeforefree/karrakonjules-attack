const std = @import("std");
const rl = @import("raylib");
const perlin = @import("perlin.zig");
const rg = @import("raygui");
const Level = @import("level.zig").Level;

pub const Enemy = struct {
    range: f64,
    max_health: usize,
    health: usize,
    damage: usize,
    speed: f64,
    attack_speed_ms: usize,
    attack_buffer: usize = 0,
    x_val: f64 = 100,
};

pub const State = struct {
    const GameState = enum {
        intro,
        chose_fighter,
        shop1,
        level1,
        cutscene1,
        outro,
    };

    fn loadFighterTextures(self: *State) !void {
        inline for (@typeInfo(Fighter).@"enum".fields, 0..) |f, i| {
            const fighter_name = f.name;
            const fighter_texture = try rl.loadTexture("assets/bodies/" ++ fighter_name ++ ".png");

            self.fighter_textures[i] = fighter_texture;
        }
    }

    var fighters_buf: [10]FighterStats = undefined;
    fighters: std.ArrayList(FighterStats) = .initBuffer(&fighters_buf),
    fighter_textures: [@typeInfo(Fighter).@"enum".fields.len]rl.Texture2D = undefined,

    phase: GameState = .intro,
    pub fn nextPhase(self: *State) void {
        self.phase = std.meta.intToEnum(GameState, @intFromEnum(self.phase) + 1) catch self.phase;
    }
};

pub var state: State = .{};
pub var debug_mode: bool = true;
pub var level1 = Level{};

const Fighter = enum {
    strong,
    fast,
    smart,

    pub fn getFighterStats(self: Fighter) FighterStats {
        return switch (self) {
            .strong => .{
                .name = @tagName(self),
                .health = 110,
                .damage = 20,
                .attack_speed_ms = 3000,
                .range = 45,
            },
            .fast => .{
                .name = @tagName(self),
                .health = 100,
                .damage = 10,
                .attack_speed_ms = 1500,
                .range = 60,
            },
            .smart => .{
                .name = @tagName(self),
                .health = 90,
                .damage = 10,
                .attack_speed_ms = 2250,
                .range = 75,
            },
        };
    }
};

const FighterStats = struct {
    name: []const u8,
    health: usize,
    damage: usize,
    attack_speed_ms: usize,
    range: usize,
};

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

pub fn dtToMs(dt: f64) usize {
    return @intFromFloat(dt * 1000);
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
    try state.loadFighterTextures();

    level1.enemies[0] = Enemy{
        .attack_speed_ms = 2000,
        .range = 100,
        .damage = 10,
        .speed = 10,
        .health = 100,
        .max_health = 100,
    };
    level1.enemies[0] = Enemy{
        .attack_speed_ms = 2400,
        .range = 100,
        .damage = 10,
        .speed = 10,
        .health = 100,
        .max_health = 100,
    };
    const rect: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(menu_texture.width),
        .height = @floatFromInt(menu_texture.height),
    };

    _ = rect;

    const screen_rect: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(rl.getScreenWidth()),
        .height = @floatFromInt(rl.getRenderHeight()),
    };

    _ = screen_rect;

    var last_frame_time = rl.getTime();
    while (!rl.windowShouldClose()) {
        const screenw: f32 = @floatFromInt(rl.getScreenWidth());
        // const screenh: f32 = @floatFromInt(rl.getScreenHeight());
        const time: f32 = @floatCast(rl.getTime());
        const dt = time - last_frame_time;
        last_frame_time = time;
        const offset_noise = perlin.noise(f32, perlin.permutation, .{ .x = time, .y = 34.5, .z = 345.3 }) * 100;

        // INPUT
        if (rl.isKeyPressed(.tab)) {
            debug_mode = !debug_mode;
        }

        switch (state.phase) {
            .level1 => {
                level1.update(dt);
            },
            else => {
                // std.log.debug("Main loop update not implemented for phase: {t}", .{state.phase});
            },
        }
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        switch (state.phase) {
            .intro => {
                rl.drawText("Karrakonjules attack!", @intFromFloat(offset_noise), 20, 100, .black);

                rl.drawText("Arrow keys to select, ENTER to confirm", 180, 400, 20, .gray);

                drawFullscreenCentered(menu_texture);
            },
            .level1 => {
                level1.render();
            },
            .chose_fighter => {
                rl.drawText("Choose Your Fighter", 200, 50, 40, .black);

                inline for (@typeInfo(Fighter).@"enum".fields) |f| {
                    const fighter_name = f.name;
                    const fighter = std.meta.stringToEnum(Fighter, fighter_name).?;
                    const fighter_int = @intFromEnum(fighter);
                    const fighter_texture = state.fighter_textures[fighter_int];

                    const button_rect = rl.Rectangle{
                        .x = 100 + 150 * @as(f32, @floatFromInt(fighter_int)),
                        .y = 150,
                        .width = 120,
                        .height = 120,
                    };

                    const mouse_pos = rl.getMousePosition();
                    const is_hovered = rl.checkCollisionPointRec(mouse_pos, button_rect);
                    const is_clicked = is_hovered and rl.isMouseButtonPressed(.left);

                    rl.drawRectangleRec(button_rect, if (is_hovered) rl.Color.light_gray else rl.Color.gray);
                    rl.drawRectangleLinesEx(button_rect, 2, rl.Color.dark_gray);

                    const img_size: f32 = 100;
                    const img_x = button_rect.x + (button_rect.width - img_size) / 2;
                    const img_y = button_rect.y + 10;

                    fighter_texture.drawPro(getRect(fighter_texture), .{ .x = img_x, .y = img_y, .width = img_size, .height = img_size }, .{ .x = 0, .y = 0 }, 0, .white);

                    const name_width = rl.measureText(fighter_name, 16);
                    rl.drawText(fighter_name, @intFromFloat(button_rect.x + (button_rect.width - @as(f32, @floatFromInt(name_width))) / 2), @intFromFloat(button_rect.y + button_rect.height - 25), 16, .black);

                    if (is_clicked) {
                        state.fighters.appendAssumeCapacity(fighter.getFighterStats());
                        state.nextPhase();
                        break;
                    }
                }
            },
            else => {
                std.log.debug("Main loop render not implemented for phase: {t}", .{state.phase});
            },
        }

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
