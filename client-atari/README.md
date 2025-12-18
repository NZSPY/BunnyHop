# BunnyHop Atari 8-bit Client

This is a text-based client for the BunnyHop card game, designed to run on Atari 8-bit computers using the FujiNet network adapter.

## Requirements

- Atari 8-bit computer (400/800/XL/XE series)
- FujiNet network adapter
- Network connection configured in FujiNet

## Features

- Text-based UI optimized for 40-column display
- Connect to BunnyHop game servers
- Join existing games or create new ones
- Play cards using keyboard input
- View game state and other players' positions

## Building

The client is written in C and can be compiled using CC65:

```bash
cd client-atari
make
```

This will produce `bunnyhop.atr` which can be loaded onto your Atari or FujiNet.

## Usage

1. Boot the ATR file on your Atari
2. Enter the server address (default: localhost:8080)
3. Enter your player name
4. Choose to create or join a game
5. Follow on-screen prompts to play

## Controls

- **Number keys 1-9**: Select card from hand
- **RETURN**: Confirm selection
- **ESC**: Cancel / Go back
- **SPACE**: Pass turn (draw only)

## Network Protocol

The Atari client uses a simplified text protocol over TCP:

### Commands
- `CREATE <name> <maxPlayers>` - Create new game
- `JOIN <gameId> <name>` - Join existing game
- `START` - Start the game
- `PLAY <cardIndex> [target] [value]` - Play a card
- `STATE` - Request current game state
- `QUIT` - Leave game

### Responses
All responses are in format: `STATUS:message:data`

## Screen Layout

```
+----------------------------------------+
| BUNNYHOP - ATARI CLIENT                |
+----------------------------------------+
| GAME: XXXXX  TURN: PLAYER1             |
| YOUR POSITION: 5/20                    |
+----------------------------------------+
| PLAYERS:                               |
| 1. PLAYER1 - POS 5 - 5 CARDS          |
| 2. PLAYER2 - POS 8 - 4 CARDS          |
+----------------------------------------+
| YOUR HAND:                             |
| 1. RED 5     2. BLUE 3   3. SKIP      |
| 4. GREEN 7   5. DOUBLE                 |
+----------------------------------------+
| TOP CARD: BLUE 8                       |
| > SELECT CARD (1-5):                   |
+----------------------------------------+
```

## Technical Details

### Memory Map
- Screen memory: $BC20 (GR.0)
- Network buffer: $0600 (256 bytes)
- Game state: $0700 (512 bytes)

### FujiNet Integration
Uses FujiNet's N: device for network I/O:
- Opens TCP connection to server
- Sends/receives JSON messages
- Handles connection state

## Limitations

- Maximum 40 characters per line (40-column mode)
- Simple text graphics only
- No color card display
- Network latency may affect gameplay

## Future Enhancements

- [ ] Graphics mode support (GR.8)
- [ ] Color-coded cards
- [ ] Sound effects
- [ ] Better error handling
- [ ] Offline practice mode

## Troubleshooting

**Cannot connect to server:**
- Check FujiNet network settings
- Verify server IP and port
- Ensure server is running

**Garbled display:**
- Reset computer
- Check ANTIC/GTIA settings
- Verify disk image integrity

**Game state not updating:**
- Press 'R' to refresh
- Check network connection
- Rejoin game if needed

## Credits

BunnyHop Atari client by NZSPY
Built for FujiNet platform
