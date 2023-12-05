const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const mecha_module = b.dependency("mecha", .{}).module("mecha");
    const zigfsm_module = b.dependency("zigfsm", .{}).module("fsm");
    const zigstr_module = b.dependency("zigstr", .{}).module("zigstr");

    var days = (std.fs.cwd().openDir("./day", std.fs.Dir.OpenDirOptions{ .access_sub_paths = true, .no_follow = false }) catch unreachable).iterate();
    while (days.next() catch unreachable) |day| {
        var name = std.ArrayList(u8).init(allocator);
        defer name.deinit();
        name.appendSlice("advent-of-code-2023-day-") catch unreachable;
        name.appendSlice(day.name) catch unreachable;

        var path = std.ArrayList(u8).init(allocator);
        defer path.deinit();
        path.appendSlice("day/") catch unreachable;
        path.appendSlice(day.name) catch unreachable;
        path.appendSlice("/main.zig") catch unreachable;

        const exe = b.addExecutable(.{
            .name = name.items,
            .root_source_file = .{ .path = path.items },
            .target = target,
            .optimize = optimize,
        });

        exe.addModule("mecha", mecha_module);
        exe.addModule("zigfsm", zigfsm_module);
        exe.addModule("zigstr", zigstr_module);

        // This declares intent for the executable to be installed into the
        // standard location when the user invokes the "install" step (the default
        // step when running `zig build`).
        b.installArtifact(exe);

        // This *creates* a Run step in the build graph, to be executed when another
        // step is evaluated that depends on it. The next line below will establish
        // such a dependency.
        const run_cmd = b.addRunArtifact(exe);

        // By making the run step depend on the install step, it will be run from the
        // installation directory rather than directly from within the cache directory.
        // This is not necessary, however, if the application depends on other installed
        // files, this ensures they will be present and in the expected location.
        run_cmd.step.dependOn(b.getInstallStep());

        // This allows the user to pass arguments to the application in the build
        // command itself, like this: `zig build run -- arg1 arg2 etc`
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        var step_name = std.ArrayList(u8).init(allocator);
        defer step_name.deinit();
        step_name.appendSlice("run-day-") catch unreachable;
        step_name.appendSlice(day.name) catch unreachable;

        var description = std.ArrayList(u8).init(allocator);
        defer description.deinit();
        description.appendSlice("Run the solution for day ") catch unreachable;
        description.appendSlice(day.name) catch unreachable;

        // This creates a build step. It will be visible in the `zig build --help` menu,
        // and can be selected like this: `zig build run`
        // This will evaluate the `run` step rather than the default, which is "install".
        const run_step = b.step(step_name.items, description.items);
        run_step.dependOn(&run_cmd.step);
    }
}
