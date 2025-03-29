import std.stdio;      // Pour writeln, readln, write, stdout, stderr
import std.string;     // Pour strip, split, empty
import std.process;    // Pour spawnProcess, wait, ProcessException
import std.file;       // Pour chdir, FileException, getcwd
import core.stdc.stdlib : exit; // Optionnel
import core.stdc.stdlib; // exit

import utils;

void main() {
    writeln("Windows Shell (WSH) - UNIX-like shell for Windows");

    while (true) {
        try {
            string cwd;
            try {
                 cwd = std.file.getcwd(); // get the current directory
            } catch (FileException e) {
                 cwd = "??";
                 stderr.writeln("Warning!: Impossible to get the current directory: ", e.msg);
            }
            std.stdio.write(cwd, " ~ # ");
            stdout.flush();

            string line = stdin.readln();
            if (line is null) {
                exit(-1);
            }
            line = line.strip();
            if (line.empty) {
                continue;
            }

            string[] args = line.split();
            string command = args[0];

            router(command, args, cwd); // Handle commands

        } catch (Exception e) {
            return;
        }
    }
}