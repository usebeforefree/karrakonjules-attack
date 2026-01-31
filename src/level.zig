const std = @import("std");

const rl = @import("raylib");

const m = @import("main.zig");
const Enemy = m.Enemy;
const dtToMs = m.dtToMs;

var state = &m.state;

const player_x = 100;
const player_y = 300;
const player_width = 100;
const player_height = 100;

const enemy_x = 600;
const enemy_y = 300;
const healthbar_height = 50;

pub const Level = struct {
    enemies: [10]?Enemy = @splat(null),

    const Self = @This();

    pub fn render(self: *Self) void {
        for (state.fighters.items, 0..) |fighter, idx| {
            _ = fighter; // autofix
            const i: i32 = @intCast(idx);
            const px = player_x - i * 30;
            const py = player_y - i * 30;
            rl.drawRectangle(px + player_width + 10, py, 10, healthbar_height, rl.Color.green);
            rl.drawRectangle(px + player_width + 10, py, 10, healthbar_height / 2, rl.Color.red);
            rl.drawRectangle(px, py, 100, 100, rl.Color.yellow);
        }
        // Draw all enemy rectangles first
        for (self.enemies, 0..) |e, idx| {
            if (e) |enemy| {
                if (enemy.health == 0) {
                    continue;
                }
                const i: i32 = @intCast(idx);
                rl.drawRectangle(enemy_x + i * 30, enemy_y - i * 30, 100, 100, rl.Color.blue);
            }
        }

        // Draw damage animations on top (fighters then enemies)
        for (state.fighters.items, 0..) |fighter, idx| {
            if (fighter.display_dmg_animation) {
                const i: i32 = @intCast(idx);
                const px = player_x - i * 30;
                const py = player_y - i * 30;
                const frame: usize = @min(fighter.dmg_animation_time / Enemy.dmg_frame_time, Enemy.dmg_frames - 1);
                const dmg_tex = state.damage_textures[frame];
                dmg_tex.drawPro(
                    m.getRect(dmg_tex),
                    .{ .x = @floatFromInt(px), .y = @floatFromInt(py), .width = 100, .height = 100 },
                    .{ .x = 0, .y = 0 },
                    0,
                    rl.Color.white,
                );
            }
        }

        for (self.enemies, 0..) |e, idx| {
            if (e) |enemy| {
                if (enemy.health == 0) {
                    continue;
                }
                if (enemy.display_dmg_animation) {
                    const i: i32 = @intCast(idx);
                    const frame: usize = @min(enemy.dmg_animation_time / Enemy.dmg_frame_time, Enemy.dmg_frames - 1);
                    const dmg_tex = state.damage_textures[frame];
                    dmg_tex.drawPro(
                        m.getRect(dmg_tex),
                        .{ .x = @floatFromInt(enemy_x + i * 30), .y = @floatFromInt(enemy_y - i * 30), .width = 100, .height = 100 },
                        .{ .x = 0, .y = 0 },
                        0,
                        rl.Color.white,
                    );
                }
            }
        }
    }

    pub fn update(self: *Self, dt: f64) void {
        var closest_enemy: ?*Enemy = null;

        for (&self.enemies) |*e| {
            if (e.*) |*enemy| {
                if (enemy.health == 0) {
                    continue;
                }
                //enemy move
                enemy.x_val -= dt * enemy.speed;
                if (enemy.display_dmg_animation) {
                    enemy.dmg_animation_time += dtToMs(dt);
                }
                if (enemy.dmg_animation_time > Enemy.dmg_frame_time * Enemy.dmg_frames) {
                    enemy.dmg_animation_time = 0;
                    enemy.display_dmg_animation = false;
                    enemy.health, const of = @subWithOverflow(enemy.health, enemy.damage_to_take);
                    if (of == 1) {
                        enemy.health = 0;
                    }
                    enemy.damage_to_take = 0;
                }

                if (closest_enemy == null) {
                    closest_enemy = enemy;
                } else if (enemy.x_val < closest_enemy.?.x_val) {
                    closest_enemy = enemy;
                }

                // enemy attack
                if (enemy.range > enemy.x_val) {
                    enemy.attack_buffer += dtToMs(dt);
                    if (enemy.attack_buffer >= enemy.attack_speed_ms) {
                        enemy.attack_buffer -= enemy.attack_speed_ms;
                        std.log.debug("enemy attack\n", .{});
                        // apply damage to first fighter (simple behaviour)
                        if (state.fighters.items.len > 0) {
                            var target = &state.fighters.items[0];
                            target.damage_to_take = enemy.damage;
                            target.display_dmg_animation = true;
                            target.dmg_animation_time = 0;
                        }
                    }
                }
            }
        }
        // Progress fighter damage animations and apply damage when finished
        for (state.fighters.items) |*f| {
            if (f.display_dmg_animation) {
                f.dmg_animation_time += dtToMs(dt);
                if (f.dmg_animation_time > Enemy.dmg_frame_time * Enemy.dmg_frames) {
                    f.dmg_animation_time = 0;
                    f.display_dmg_animation = false;
                    f.health, const of = @subWithOverflow(f.health, f.damage_to_take);
                    if (of == 1) {
                        f.health = 0;
                    }
                    f.damage_to_take = 0;
                }
            }
        }
        for (state.fighters.items) |*f| {
            if (closest_enemy) |enemy| {
                if (f.range >= enemy.x_val) {
                    f.attack_time_buffer += dtToMs(dt);
                    if (f.attack_time_buffer >= f.attack_speed_ms) {
                        f.attack_time_buffer -= f.attack_speed_ms;
                        std.log.debug("Player attack\n", .{});
                        enemy.damage_to_take = f.damage;
                        enemy.display_dmg_animation = true;
                    }
                }
            }
        }
    }
};
