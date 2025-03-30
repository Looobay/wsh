module external;

// Here we are including the builtin tools

immutable ubyte[] nano = cast(immutable(ubyte)[]) import("nano/nano.exe");
immutable ubyte[] vim = cast(immutable(ubyte)[]) import("vim/vim.exe");

void runNano(string[] args){
    import std.file : write;
    import std.process : execute;
    import std.path : buildPath;
    import std.uuid : randomUUID;
    import std.file : tempDir, remove;
    
    string tempPath = buildPath(tempDir, "external_" ~ randomUUID().toString() ~ ".exe");
    
    write(tempPath, nano);
    
    if (args.length > 1) {
        auto result = execute([tempPath, args[1]]);
    } else {
        auto result = execute([tempPath]);
    }
    
    remove(tempPath);
}

// TODO : Include Vim64.dll
void runVim(string[] args){
    import std.file : write;
    import std.process : execute;
    import std.path : buildPath;
    import std.uuid : randomUUID;
    import std.file : tempDir, remove;
    
    string tempPath = buildPath(tempDir, "external_" ~ randomUUID().toString() ~ ".exe");
    
    write(tempPath, vim);
    
    if (args.length > 1) {
        auto result = execute([tempPath, args[1]]);
    } else {
        auto result = execute([tempPath]);
    }
    
    remove(tempPath);
}
