/**
 * BunnyHop Card Game - Atari 8-bit Client
 * 
 * A text-based client for playing BunnyHop over FujiNet
 * Designed for Atari 400/800/XL/XE computers
 */

#include <atari.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>

// Configuration
#define SERVER_HOST "localhost:8080"
#define MAX_PLAYERS 4
#define MAX_CARDS 10
#define SCREEN_WIDTH 40

// Game state
typedef struct {
    char id[32];
    char name[20];
    int position;
    int cardCount;
    int isActive;
    int isBlocked;
    int hasDouble;
} Player;

typedef struct {
    char id[16];
    char type[16];
    char color[16];
    int value;
    char actionType[24];
} Card;

typedef struct {
    char gameId[32];
    char playerId[32];
    Player players[MAX_PLAYERS];
    int playerCount;
    int currentPlayer;
    Card hand[MAX_CARDS];
    int handSize;
    Card topCard;
    int direction;
    char state[16];
} GameState;

// Global state
GameState gameState;
char serverHost[64] = SERVER_HOST;
int connected = 0;

// Function declarations
void clearScreen();
void drawBorder();
void drawTitle();
void showMainMenu();
void createGame();
void joinGame();
void playGame();
void displayGameState();
void displayHand();
void playCard(int cardIndex);
void drawCard();
void waitForTurn();
void showHelp();
int connectToServer();
void disconnectFromServer();
int sendCommand(const char* cmd);
int receiveResponse(char* buffer, int maxLen);
void parseGameState(const char* data);

/**
 * Main entry point
 */
int main() {
    int choice;
    
    clearScreen();
    drawTitle();
    
    printf("\n\nWELCOME TO BUNNYHOP!\n");
    printf("ATARI 8-BIT CLIENT V1.0\n\n");
    
    printf("SERVER: %s\n", serverHost);
    printf("PRESS ANY KEY TO START...\n");
    cgetc();
    
    while(1) {
        clearScreen();
        showMainMenu();
        
        choice = cgetc() - '0';
        
        switch(choice) {
            case 1:
                createGame();
                break;
            case 2:
                joinGame();
                break;
            case 3:
                showHelp();
                break;
            case 4:
                clearScreen();
                printf("\n\nTHANKS FOR PLAYING!\n");
                printf("VISIT: GITHUB.COM/NZSPY/BUNNYHOP\n");
                return 0;
            default:
                printf("\nINVALID CHOICE!\n");
                printf("PRESS ANY KEY...\n");
                cgetc();
        }
    }
    
    return 0;
}

/**
 * Clear the screen
 */
void clearScreen() {
    clrscr();
}

/**
 * Draw a border line
 */
void drawBorder() {
    int i;
    for(i = 0; i < SCREEN_WIDTH; i++) {
        putchar('-');
    }
    putchar('\n');
}

/**
 * Draw the title screen
 */
void drawTitle() {
    drawBorder();
    printf(" BUNNYHOP CARD GAME - ATARI CLIENT\n");
    drawBorder();
}

/**
 * Show main menu
 */
void showMainMenu() {
    drawTitle();
    printf("\n");
    printf("  1. CREATE NEW GAME\n");
    printf("  2. JOIN GAME\n");
    printf("  3. HELP\n");
    printf("  4. QUIT\n");
    printf("\n");
    drawBorder();
    printf("\nCHOICE: ");
}

/**
 * Create a new game
 */
void createGame() {
    char playerName[20];
    char buffer[256];
    
    clearScreen();
    drawTitle();
    printf("\nCREATE NEW GAME\n\n");
    
    printf("YOUR NAME (MAX 15 CHARS): ");
    fgets(playerName, sizeof(playerName), stdin);
    playerName[strcspn(playerName, "\n")] = 0;
    
    if(strlen(playerName) == 0) {
        strcpy(playerName, "PLAYER");
    }
    
    printf("\nCONNECTING TO SERVER...\n");
    
    if(!connectToServer()) {
        printf("FAILED TO CONNECT!\n");
        printf("PRESS ANY KEY...\n");
        cgetc();
        return;
    }
    
    // Send create command
    snprintf(buffer, sizeof(buffer), "CREATE %s 4", playerName);
    if(!sendCommand(buffer)) {
        printf("FAILED TO CREATE GAME!\n");
        printf("PRESS ANY KEY...\n");
        cgetc();
        disconnectFromServer();
        return;
    }
    
    // Receive response
    if(receiveResponse(buffer, sizeof(buffer))) {
        printf("GAME CREATED!\n");
        printf("WAITING FOR PLAYERS...\n");
        
        // Parse game ID from response
        // In real implementation, parse JSON response
        strcpy(gameState.gameId, "GAME001");
        strcpy(gameState.playerId, playerName);
        
        playGame();
    }
    
    disconnectFromServer();
}

/**
 * Join an existing game
 */
void joinGame() {
    char playerName[20];
    char gameId[32];
    char buffer[256];
    
    clearScreen();
    drawTitle();
    printf("\nJOIN GAME\n\n");
    
    printf("GAME ID: ");
    fgets(gameId, sizeof(gameId), stdin);
    gameId[strcspn(gameId, "\n")] = 0;
    
    printf("YOUR NAME: ");
    fgets(playerName, sizeof(playerName), stdin);
    playerName[strcspn(playerName, "\n")] = 0;
    
    if(strlen(playerName) == 0) {
        strcpy(playerName, "PLAYER");
    }
    
    printf("\nCONNECTING TO SERVER...\n");
    
    if(!connectToServer()) {
        printf("FAILED TO CONNECT!\n");
        printf("PRESS ANY KEY...\n");
        cgetc();
        return;
    }
    
    // Send join command
    snprintf(buffer, sizeof(buffer), "JOIN %s %s", gameId, playerName);
    if(!sendCommand(buffer)) {
        printf("FAILED TO JOIN GAME!\n");
        printf("PRESS ANY KEY...\n");
        cgetc();
        disconnectFromServer();
        return;
    }
    
    // Receive response
    if(receiveResponse(buffer, sizeof(buffer))) {
        printf("JOINED GAME!\n");
        printf("WAITING TO START...\n");
        
        strcpy(gameState.gameId, gameId);
        strcpy(gameState.playerId, playerName);
        
        playGame();
    }
    
    disconnectFromServer();
}

/**
 * Main game loop
 */
void playGame() {
    int running = 1;
    char ch;
    
    while(running) {
        clearScreen();
        displayGameState();
        displayHand();
        
        printf("\nCOMMANDS: 1-9=PLAY CARD, R=REFRESH\n");
        printf("          S=START GAME, Q=QUIT\n");
        printf("\nCOMMAND: ");
        
        ch = cgetc();
        
        if(ch >= '1' && ch <= '9') {
            int cardIndex = ch - '1';
            if(cardIndex < gameState.handSize) {
                playCard(cardIndex);
            }
        } else if(ch == 'r' || ch == 'R') {
            // Refresh game state
            sendCommand("STATE");
        } else if(ch == 's' || ch == 'S') {
            sendCommand("START");
        } else if(ch == 'q' || ch == 'Q') {
            running = 0;
        }
    }
}

/**
 * Display current game state
 */
void displayGameState() {
    int i;
    
    drawTitle();
    printf("\nGAME: %s\n", gameState.gameId);
    drawBorder();
    
    printf("PLAYERS:\n");
    for(i = 0; i < gameState.playerCount; i++) {
        Player* p = &gameState.players[i];
        printf("%d. %-15s POS:%2d CARDS:%d\n", 
               i+1, p->name, p->position, p->cardCount);
        
        if(p->isBlocked) {
            printf("   [BLOCKED]\n");
        }
        if(p->hasDouble) {
            printf("   [DOUBLE ACTIVE]\n");
        }
    }
    
    drawBorder();
    printf("TOP CARD: %s %d\n", gameState.topCard.color, 
           gameState.topCard.value);
}

/**
 * Display player's hand
 */
void displayHand() {
    int i;
    
    drawBorder();
    printf("YOUR HAND:\n");
    
    for(i = 0; i < gameState.handSize; i++) {
        Card* c = &gameState.hand[i];
        
        printf("%d. ", i+1);
        
        if(strcmp(c->type, "hop") == 0) {
            printf("%-6s %d\n", c->color, c->value);
        } else {
            printf("%-15s\n", c->actionType);
        }
    }
}

/**
 * Play a card from hand
 */
void playCard(int cardIndex) {
    char buffer[128];
    
    snprintf(buffer, sizeof(buffer), "PLAY %d", cardIndex);
    
    if(sendCommand(buffer)) {
        printf("\nCARD PLAYED!\n");
    } else {
        printf("\nFAILED TO PLAY CARD!\n");
    }
    
    printf("PRESS ANY KEY...\n");
    cgetc();
}

/**
 * Show help screen
 */
void showHelp() {
    clearScreen();
    drawTitle();
    printf("\nHOW TO PLAY BUNNYHOP:\n\n");
    
    printf("GOAL: BE FIRST TO REACH 20!\n\n");
    
    printf("CARD TYPES:\n");
    printf("- HOP CARDS: MOVE FORWARD\n");
    printf("- SKIP: SKIP NEXT PLAYER\n");
    printf("- REVERSE: REVERSE ORDER\n");
    printf("- BLOCK: BLOCK OPPONENT\n");
    printf("- DOUBLE: NEXT HOP X2\n");
    printf("- WILD: ANY COLOR/VALUE\n");
    printf("- FINISH: WIN AT 15+\n\n");
    
    printf("NETWORK PLAY:\n");
    printf("CONNECT VIA FUJINET TO PLAY\n");
    printf("WITH OTHER PLAYERS ONLINE!\n\n");
    
    printf("PRESS ANY KEY...\n");
    cgetc();
}

/**
 * Connect to game server
 * Note: This is a placeholder. Real implementation would
 * use FujiNet's N: device for TCP connection
 */
int connectToServer() {
    // In real implementation:
    // - Open N: device
    // - Connect to server
    // - Establish TCP connection
    
    connected = 1;
    return 1;
}

/**
 * Disconnect from server
 */
void disconnectFromServer() {
    // In real implementation:
    // - Close N: device
    // - Clean up connection
    
    connected = 0;
}

/**
 * Send command to server
 */
int sendCommand(const char* cmd) {
    // In real implementation:
    // - Format as JSON or protocol message
    // - Send via N: device
    // - Return success/failure
    
    return 1;
}

/**
 * Receive response from server
 */
int receiveResponse(char* buffer, int maxLen) {
    // In real implementation:
    // - Read from N: device
    // - Parse response
    // - Update game state
    
    return 1;
}

/**
 * Parse game state from JSON response
 */
void parseGameState(const char* data) {
    // In real implementation:
    // - Parse JSON response
    // - Update gameState structure
    // - Handle errors
}
