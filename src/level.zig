const rl = @import("raylib");

const m = @import("main.zig");
const Enemy = m.Enemy;
var state = &m.state;

const enemy_x = 600;
const enemy_y = 300;

// spawn point igraca na 0
// enemy spawn point 100
// clock
// po clocku attack speed.
// enemy se pomera
pub const Level = struct {
    enemies: [10]?Enemy = @splat(null),

    const Self = @This();

    pub fn render(self: *Self) void {

        // todo for player in players draw
        rl.drawRectangle(20, 200, 100, 100, rl.Color.red);
        for (self.enemies, 0..) |e, idx| {
            if (e) |enemy| {
                _ = enemy; // autofix
                const i: i32 = @intCast(idx);
                rl.drawRectangle(enemy_x + i * 30, enemy_y - i * 30, 100, 100, rl.Color.blue);
            }
        }
    }
    pub fn update(self: *Self, dt: f32) void {
        _ = dt; // autofix
        _ = self; // autofix
    }
};
