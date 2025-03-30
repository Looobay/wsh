module utils;

import std.stdio; 
import core.stdc.stdlib; // exit
import std.file; // chdir, exists, isDir, dirEntries, SpanMode, etc.
import std.path; // baseName
import std.algorithm;
import std.string;
import std.regex;
import std.process; // spawnProcess, wait
import core.sys.windows.windows;

bool isDebug = false;

string[] history = []; // Command history

// Route every command to the good function for it.
void router(string command, string[] args, string currentDir) {
    auto regex = regex(r"^[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+$"); // regex for files

    switch (command) {
        case "exit":
            exit(0);
            break;
        case "cd":
            cd(args);
            break;
        case "ls":
            ls(currentDir, args);
            break;
        case "echo":
            echo(args);
            break;
        case "pwd":
            pwd();
            break;
        case "clear":
            clear();
            break;
        case "true":
            // do nothing
            break;
        case "false":
            // do nothing
            break;
        case "cat":
            cat(args);
            break;
        case "mkdir":
            mkdir(args);
            break;
        case "wsh":
            runWsh(args);
            break;
        case "history":
            historic();
            break;
        case "touch":
            touch(args);
            break;
        default:
            // Handle special cases that can't be directly matched in the switch
            if (command.findSplit(".wsh") && exists(command)) {
                runScript(command, currentDir);
            } else if (match(command[2 .. $], regex) || match(command, regex)) {
                runExternal(args);
            } else {
                writeln("error: unknown command");
            }
            break;
    }

    if (args.length > 0) {
        history ~= command ~ " " ~ args[1 .. $].join(" ");
    } else {
        history ~= command;
    }
}

void cd(string[] args) {
    if (args.length < 2) {
        stderr.writeln("cd: missing arguments (example: cd foo)");
    } else if (args.length > 2) {
        stderr.writeln("cd: too many arguments (example: cd foo)");
    } else {
        string target = args[1];
        try {
            if (!exists(target)) {
                stderr.writeln("cd: '", target, "' does not exist");
            } else if (!isDir(target)) {
                stderr.writeln("cd: '", target, "' is not a folder");
            } else {
                chdir(target);
            }
        } catch (Exception e) {
            stderr.writeln("cd: error : ", e.msg);
        }
    }
}

void ls(string currentDir, string[] args) {
    string targetDir = currentDir; // Par défaut : répertoire courant
    string[] errors;

    // Si un argument est fourni, utilise-le comme cible
    if (args.length > 1) {
        targetDir = args[1];
        // Vérifie si la cible est valide
        if (!exists(targetDir)) {
            stderr.writeln("ls: '", targetDir, "' does not exist");
            return;
        }
        if (isFile(targetDir)) {
            stderr.writeln("ls: '", targetDir, "' is not a directory");
            return;
        }
        // Normalise le chemin pour éviter les problèmes
        targetDir = absolutePath(targetDir);
    }

    // Liste les entrées du répertoire cible
    foreach (entry; dirEntries(targetDir, SpanMode.shallow)) {
        try {
            string name = baseName(entry.name);
            if (!isFile(entry)) {
                writef("%s\\    ", name);
            } else {
                writef("%s    ", name);
            }
        } catch (Exception e) {
            errors ~= format("ls: impossible de lire '%s' : %s", entry.name, e.msg);
            continue;
        }
    }
    writeln();

    // Affiche les erreurs si mode debug activé
    if (isDebug) {
        foreach (error; errors) {
            stderr.writeln(error);
        }
    }
}

void runExternal(string[] args) {
    try {
        auto pid = spawnProcess(args);
        wait(pid);
    } catch (ProcessException e) {
        stderr.writeln("Error: ", e.msg);
    }
}

void echo(string[] args) {
    if (args.length > 1) {
        writeln(args[1..$].join(" "));
    } else {
        writeln();
    }
}

void pwd() {
    try {
        writeln(getcwd());
    } catch (FileException e) {
        stderr.writeln("Error: ", e.msg);
    }
}

void clear() {
    try {
        auto pid = spawnProcess(["cmd", "/c", "cls"]); // cls = clear screen
        wait(pid);
    } catch (ProcessException e) {
        stderr.writeln("Error while clearing screen : ", e.msg);
    }
}

void cat(string[] args) {
    if (args.length < 2) {
        stderr.writef("cat: missing arguments (example: cat file.txt)");
    } else {
        foreach (filename; args[1..$]) {
            try {
                if (!exists(filename)) {
                    stderr.writef("cat: '", filename, "' does not exist");
                } else if (isDir(filename)) {
                    stderr.writef("cat: '", filename, "' is a directory");
                } else {
                    string content = readText(filename);
                    write(content);
                }
            } catch (Exception e) {
                stderr.writef("cat: error reading '", filename, "' : ", e.msg);
            }
        }
    }
    writef("\n");
}

void mkdir(string[] args) {
    if (args.length < 2) {
        stderr.writeln("mkdir: missing arguments (example: mkdir dir)");
        return;
    }
    foreach (dirname; args[1..$]) {
        try {
            if (exists(dirname)) {
                stderr.writeln("mkdir: '", dirname, "' already exists");
                continue;
            }
            std.file.mkdir(dirname); // Appel explicite à std.file.mkdir
            if (isDebug) writeln("mkdir: created directory '", dirname, "'"); // Feedback clair
        } catch (FileException e) {
            stderr.writeln("mkdir: cannot create '", dirname, "' : ", e.msg);
        } catch (Exception e) {
            stderr.writeln("mkdir: unexpected error creating '", dirname, "' : ", e.msg);
        }
    }
}

void runScript(string scriptPath, string currentDir) {
    try {
        string content = readText(scriptPath);
        string[] lines = splitLines(content);
        foreach (line; lines) {
            string trimmedLine = line.strip();
            if (trimmedLine.empty || trimmedLine.startsWith("#")) {
                continue; // Ignore les lignes vides ou les commentaires
            }
            string[] args = trimmedLine.split();
            if (args.length > 0) {
                router(args[0], args, currentDir); // Appelle router pour chaque commande
            }
        }
    } catch (Exception e) {
        stderr.writeln("wsh: error executing '", scriptPath, "' : ", e.msg);
    }
}

void runWsh(string[] args) {
    try {
        string exePath = "D:\\wsh\\build\\wsh.exe"; // Remplace par le chemin réel si nécessaire (ex. "C:\\path\\to\\wsh.exe")
        string[] wshArgs = [exePath];
        if (args.length > 1) {
            wshArgs ~= args[1..$];
        }
        auto pid = spawnProcess(wshArgs);
        wait(pid);
    } catch (ProcessException e) {
        stderr.writeln("wsh: error launching shell: ", e.msg);
    }
}

void historic(){
    foreach (h;history){
        writeln(h);
    }
    history ~= "history";
    if (history.length >= 500) {
        history = history[100 .. $]; // delete 100 first elements
    }
}

void touch(string[] args) {
    if (args.length < 2) {
        stderr.writeln("touch: missing arguments (example: touch foo.txt)");
        return;
    }
    foreach (filename; args[1..$]) {
        try {
            if (exists(filename)) {
                stderr.writeln("touch: '", filename, "' already exists");
                continue;
            }
            std.file.write(filename, []);
            if (isDebug) writeln("file: created file '", filename, "'"); // Feedback clair
        } catch (FileException e) {
            stderr.writeln("file: cannot create '", filename, "' : ", e.msg);
        } catch (Exception e) {
            stderr.writeln("file: unexpected error creating '", filename, "' : ", e.msg);
        }
    }
}