# BunnyHop Game Server

A Go-based multiplayer game server for BunnyHop card game with WebSocket support.

## Features

- Real-time multiplayer gameplay via WebSockets
- REST API for game management
- Support for 2-4 players per game
- Complete game logic implementation
- Concurrent game handling

## Installation

### Prerequisites
- Go 1.24 or higher
- Internet connection for downloading dependencies

### Setup

1. Clone the repository
2. Navigate to the server directory:
   ```bash
   cd server
   ```

3. Download dependencies:
   ```bash
   go mod download
   ```

4. Build the server:
   ```bash
   go build -o bunnyhop-server
   ```

## Running the Server

### Basic Usage

```bash
./bunnyhop-server
```

The server will start on port 8080 by default.

### Custom Port

```bash
./bunnyhop-server -addr=:9000
```

## API Documentation

### REST Endpoints

#### List Games
```
GET /api/games
```

Returns a list of all active games.

**Response:**
```json
[
  {
    "id": "game-1234567890",
    "state": "waiting",
    "playerCount": 2,
    "maxPlayers": 4,
    "createdAt": "2024-01-01T00:00:00Z"
  }
]
```

#### Create Game
```
POST /api/games/create
```

Creates a new game.

**Request Body:**
```json
{
  "playerName": "Player1",
  "maxPlayers": 4
}
```

**Response:**
```json
{
  "gameId": "game-1234567890",
  "message": "Game created successfully by Player1"
}
```

### WebSocket API

Connect to `/ws` to interact with games in real-time.

#### Message Format

All messages follow this structure:
```json
{
  "type": "message_type",
  "gameId": "game-id",
  "data": {
    // Message-specific data
  }
}
```

#### Client -> Server Messages

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

**Start Game:**
```json
{
  "type": "start_game"
}
```

**Play Card:**
```json
{
  "type": "play_card",
  "data": {
    "cardId": "card-5",
    "targetPlayerId": "player-2",
    "wildColor": "red",
    "wildValue": 7
  }
}
```

**Get State:**
```json
{
  "type": "get_state"
}
```

#### Server -> Client Messages

**Join Result:**
```json
{
  "type": "join_result",
  "gameId": "game-123",
  "data": {
    "success": true,
    "playerId": "player-1"
  }
}
```

**Game State:**
```json
{
  "type": "game_state",
  "gameId": "game-123",
  "data": {
    "id": "game-123",
    "state": "started",
    "players": {
      "player-1": {
        "id": "player-1",
        "name": "Player1",
        "position": 5,
        "hand": [...],
        "isBlocked": false,
        "hasDouble": false
      }
    },
    "currentPlayer": 0,
    "topCard": {...},
    "direction": 1,
    "winner": ""
  }
}
```

**Play Result:**
```json
{
  "type": "play_result",
  "gameId": "game-123",
  "data": {
    "success": true,
    "error": ""
  }
}
```

## Game Logic

### Card Types

**Hop Cards (1-10 in 4 colors):**
- Red, Blue, Green, Yellow
- Move player forward by card value

**Action Cards:**
- **Skip**: Next player loses their turn
- **Reverse**: Reverse direction of play
- **Block**: Prevent target player from playing hop cards next turn
- **Double**: Next hop card counts for double value

**Special Cards:**
- **Wild Hop**: Acts as any color and value 1-10
- **Wild Action**: Acts as any action card
- **Draw Two**: Next player draws 2 cards and skips turn
- **Finish Line**: Instant win if at position 15+

### Game Flow

1. **Setup**: Shuffle deck, deal 5 cards per player
2. **Turns**: Players take turns playing one card, then drawing one
3. **Win Condition**: First player to reach position 20 wins

### Validation

The server validates:
- Player turn order
- Card legality
- Game state transitions
- Player actions

## Architecture

### Package Structure

```
server/
├── main.go              # Server entry point, HTTP handlers
├── game/
│   ├── card.go          # Card types and deck management
│   ├── player.go        # Player state management
│   ├── game.go          # Core game logic
│   └── manager.go       # Multi-game management
└── websocket/
    ├── hub.go           # WebSocket connection hub
    └── client.go        # WebSocket client handling
```

### Concurrency

- Each game has its own mutex for thread-safe operations
- WebSocket hub manages client connections
- Game manager handles multiple concurrent games

## Development

### Running Tests

```bash
go test ./...
```

### Adding New Card Types

1. Add card type to `game/card.go`
2. Implement logic in `game/game.go` in `applyCardEffect()`
3. Update deck generation in `NewDeck()`

### Adding New Endpoints

1. Add handler function in `main.go`
2. Register route in `main()` function
3. Document in this README

## Performance

- Supports dozens of concurrent games
- Low memory footprint per game (~10KB)
- WebSocket connections pooled efficiently
- No database required (in-memory state)

## Troubleshooting

**Server won't start:**
- Check if port is already in use
- Verify Go installation
- Check file permissions

**Clients can't connect:**
- Verify firewall settings
- Check server address/port
- Ensure WebSocket support in client

**Game state issues:**
- Check server logs
- Verify client message format
- Ensure valid game IDs

## Future Enhancements

- [ ] Persistent game state (database)
- [ ] Authentication and user accounts
- [ ] Game replay/history
- [ ] Spectator mode
- [ ] Tournament mode
- [ ] Metrics and analytics
- [ ] Rate limiting
- [ ] Admin API

## License

Open source - see main repository for details.
