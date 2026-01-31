const std = @import("std");

const rl = @import("raylib");

const m = @import("main.zig");
const Enemy = m.Enemy;
const dtToMs = m.dtToMs;
const Animation = m.Animation;

var state = &m.state;

const player_x = 100;
const player_y = 300;
const player_width = 100;
const player_height = 100;

const enemy_x = 600;
const enemy_y = 300;
const healthbar_height = 50;

fn renderDamageAnimation(animation: *const Animation, x: f32, y: f32, width: f32, height: f32) void {
    if (animation.isPlaying()) {
        const frame = animation.getCurrentFrame();
        const dmg_tex = state.damage_textures[frame];
        dmg_tex.drawPro(
            m.getRect(dmg_tex),
            .{ .x = x, .y = y, .width = width, .height = height },
            .{ .x = 0, .y = 0 },
            0,
            rl.Color.white,
        );
    }
}

fn applyDamageEvent(entity: *m.Enemy) void {
    entity.health, const of = @subWithOverflow(entity.health, entity.damage_to_take);
    if (of == 1) {
        entity.health = 0;
    }
    entity.damage_to_take = 0;
}

fn applyDamageEventFighter(entity: *m.FighterStats) void {
    entity.health, const of = @subWithOverflow(entity.health, entity.damage_to_take);
    if (of == 1) {
        entity.health = 0;
    }
    entity.damage_to_take = 0;
}

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
            const i: i32 = @intCast(idx);
            const px = player_x - i * 30;
            const py = player_y - i * 30;
            renderDamageAnimation(&fighter.damage_animation, @floatFromInt(px), @floatFromInt(py), 100, 100);
        }

        for (self.enemies, 0..) |e, idx| {
            if (e) |enemy| {
                if (enemy.health == 0) {
                    continue;
                }
                const i: i32 = @intCast(idx);
                renderDamageAnimation(&enemy.damage_animation, @floatFromInt(enemy_x + i * 30), @floatFromInt(enemy_y - i * 30), 100, 100);
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
                // Enemy move
                enemy.x_val -= dt * enemy.speed;

                // Update damage animation and handle events
                const dmg_event = enemy.damage_animation.update(dtToMs(dt));
                if (dmg_event == .apply_damage) {
                    applyDamageEvent(enemy);
                }

                if (closest_enemy == null) {
                    closest_enemy = enemy;
                } else if (enemy.x_val < closest_enemy.?.x_val) {
                    closest_enemy = enemy;
                }

                // Enemy attack
                if (enemy.range > enemy.x_val) {
                    enemy.attack_buffer += dtToMs(dt);
                    if (enemy.attack_buffer >= enemy.attack_speed_ms) {
                        enemy.attack_buffer -= enemy.attack_speed_ms;
                        std.log.debug("enemy attack\n", .{});
                        // Apply damage to first fighter (simple behaviour)
                        if (state.fighters.items.len > 0) {
                            var target = &state.fighters.items[0];
                            target.damage_to_take = enemy.damage;
                            target.damage_animation.start();
                        }
                    }
                }
            }
        }

        // Update fighter damage animations and handle events
        for (state.fighters.items) |*f| {
            const dmg_event = f.damage_animation.update(dtToMs(dt));
            if (dmg_event == .apply_damage) {
                applyDamageEventFighter(f);
            }
        }

        // Fighter attacks
        for (state.fighters.items) |*f| {
            if (closest_enemy) |enemy| {
                if (f.range >= enemy.x_val) {
                    f.attack_time_buffer += dtToMs(dt);
                    if (f.attack_time_buffer >= f.attack_speed_ms) {
                        f.attack_time_buffer -= f.attack_speed_ms;
                        std.log.debug("Player attack\n", .{});
                        enemy.damage_to_take = f.damage;
                        enemy.damage_animation.start();
                    }
                }
            }
        }
    }
};
