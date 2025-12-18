# BunnyHop 🐰

A fast-paced card game available both as a physical card game and as a digital multiplayer game with online play.

## Overview

BunnyHop is a strategic card game for 2-4 players where you race your bunny to the finish line by playing hop cards and action cards. Be the first to reach position 20 to win!

## Game Versions

### 1. Physical Card Game 🎴
Print and play at home! Includes 52 beautifully designed cards:
- 40 Hop Cards (1-10 in 4 colors)
- 8 Action Cards (Skip, Reverse, Block, Double)
- 4 Special Cards (Wild Hop, Wild Action, Draw Two, Finish Line)

**Location:** `printable/`

### 2. Online Multiplayer 🌐
Play with friends over the internet using our Go-based server and HTML5 client.

**Components:**
- Go server with WebSocket support (`server/`)
- HTML5 web client (`client-html5/`)

### 3. Atari 8-bit Client 🕹️
Classic gaming on vintage hardware! Play via FujiNet on your Atari 8-bit computer.

**Location:** `client-atari/`

## Quick Start

### Playing Online

1. **Start the server:**
   ```bash
   cd server
   go build
   ./bunnyhop-server
   ```

2. **Open your browser:**
   Navigate to `http://localhost:8080`

3. **Create or join a game** and start playing!

### Printing Physical Cards

1. Open `printable/cards.html` in your web browser
2. Use Print function (Ctrl+P / Cmd+P)
3. Save as PDF or print directly to cardstock
4. Cut out the cards and play!

### Playing on Atari 8-bit

1. Build the client (requires CC65):
   ```bash
   cd client-atari
   make
   ```

2. Load onto your Atari via FujiNet
3. Configure server address and connect

## Game Rules

See [GAME_RULES.md](GAME_RULES.md) for complete rules and strategy tips.

**Quick Rules:**
- Deal 5 cards to each player
- Play cards to move your bunny forward
- Use action cards to affect gameplay
- First to position 20 wins!

## Project Structure

```
BunnyHop/
├── printable/          # Printable card PDFs and templates
│   ├── cards.html      # HTML template for printing
│   └── README.md       # Printing instructions
├── server/             # Go-based game server
│   ├── main.go         # Server entry point
│   ├── game/           # Game logic
│   └── websocket/      # WebSocket handling
├── client-html5/       # HTML5 web client
│   ├── index.html      # Main UI
│   ├── style.css       # Styling
│   └── game.js         # Client logic
├── client-atari/       # Atari 8-bit client
│   ├── bunnyhop.c      # Main client code
│   ├── Makefile        # Build configuration
│   └── README.md       # Atari-specific docs
├── GAME_RULES.md       # Complete game rules
└── README.md           # This file
```

## Features

### Server Features
- ✅ WebSocket-based real-time multiplayer
- ✅ REST API for game management
- ✅ Support for 2-4 players per game
- ✅ Complete game logic implementation
- ✅ Card validation and turn management

### HTML5 Client Features
- ✅ Responsive web interface
- ✅ Real-time game updates
- ✅ Visual card display with colors
- ✅ Player position tracking
- ✅ Game lobby and matchmaking

### Atari Client Features
- ✅ Text-based UI for 40-column display
- ✅ FujiNet network support
- ✅ Optimized for vintage hardware
- ✅ Complete game functionality

## Development

### Server Development

Requirements:
- Go 1.24 or higher
- gorilla/websocket package

Build:
```bash
cd server
go mod download
go build
```

### HTML5 Client Development

No build step required! Just open `client-html5/index.html` in a browser when the server is running.

### Atari Client Development

Requirements:
- CC65 compiler toolchain
- Atari development tools

Build:
```bash
cd client-atari
make
```

## API Documentation

### REST Endpoints

- `GET /api/games` - List all games
- `POST /api/games/create` - Create a new game

### WebSocket Protocol

Connect to `/ws` and send JSON messages:

**Join Game:**
```json
{
  "type": "join_game",
  "data": {
    "gameId": "game-123",
    "playerName": "Player1"
  }
}
```

**Play Card:**
```json
{
  "type": "play_card",
  "data": {
    "cardId": "card-5",
    "wildValue": 7
  }
}
```

**Start Game:**
```json
{
  "type": "start_game"
}
```

## Contributing

Contributions welcome! Areas for improvement:
- Additional card types
- Tournament mode
- Replay system
- Mobile app clients
- Additional retro platform clients

## License

This project is open source. Feel free to use, modify, and distribute.

## Credits

Created by NZSPY
Built with ❤️ for card game enthusiasts and retro computing fans

## Links

- GitHub: https://github.com/NZSPY/BunnyHop
- Issues: https://github.com/NZSPY/BunnyHop/issues

---

**Have fun playing BunnyHop!** 🐰🎮 
