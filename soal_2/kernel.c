int cursor = 0;
char color = 0x07;
char cmd[64]; /* PINDAHKAN KE SINI SEBAGAI VARIABEL GLOBAL */

void putInMemory(int segment, int address, char character);
int getChar();

void printChar(char character) {
    putInMemory(0xB800, cursor, character);
    cursor += 1;
    putInMemory(0xB800, cursor, color);
    cursor += 1;
}

void printString(char* string) {
    int i;
    i = 0;
    while (string[i] != '\0') {
        printChar(string[i]);
        i++;
    }
}

void newline() {
    int current_row;
    current_row = cursor / 160;
    cursor = (current_row + 1) * 160;
}

void clearScreen() {
    int i;
    cursor = 0;
    for (i = 0; i < 1999; i++) {
        printChar(' ');
    }
    putInMemory(0xB800, 3998, ' ');
    putInMemory(0xB800, 3999, color);
    
    cursor = 0;
}

void readString(char* buffer) {
    int i;
    char c;
    i = 0;
    while (1) {
        c = getChar();
        if (c == '\r') {
            buffer[i] = '\0';
            break;
        } else if (c == '\b') {
            if (i > 0) {
                i--;
                cursor -= 2;
                printChar(' ');
                cursor -= 2;
            }
        } else {
            buffer[i] = c;
            i++;
        }
    }
}

int strcmp(char* str1, char* str2) {
    int i;
    i = 0;
    while (str1[i] != '\0' || str2[i] != '\0') {
        if (str1[i] != str2[i]) {
            return 0;
        }
        i++;
    }
    return 1;
}

void main() {
    /* Deklarasi char cmd[64] di sini sudah dihapus */
    clearScreen();

    printString("Welcome to Assistant's Last Gift");
    newline();
    printString("type 'help'");
    newline();
    newline();

    while (1) {
        printString("> ");
        readString(cmd);
        newline();

        if (strcmp(cmd, "check")) {
            printString("ok");
        } else if (strcmp(cmd, "help")) {
            printString("Available commands: check");
        }

        newline();
    }
}