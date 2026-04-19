# BunnyHop Client Guide

This guide explains how to build your own BunnyHop client and publish it on GitHub. The server exposes a simple HTTP API, so you can create clients in Web, desktop, mobile, retro, or custom frameworks.

## 1. Overview

BunnyHop is a server-driven card game. Clients do not need to implement game rules; they only need to:
- display the current table and player state
- let the user choose valid moves
- send requests to the server
- refresh game state regularly

The server lives in `Server/main.go`. Example client code is available under `Clients/Web/GameMaker`.

## 2. Server API Endpoints

The game server uses HTTP GET endpoints. Use query parameters as shown below.

### `/tables`
Returns the list of tables and their status.

Example:
```text
GET /tables
```

### `/state`
Returns the current game state for a specific table and player.

Example:
```text
GET /state?table=ai1&player=Alice
```

### `/join`
Join a table as a player.

Example:
```text
GET /join?table=ai1&player=Alice
```

### `/start`
Start a game at the table.

Example:
```text
GET /start?table=ai1
```

### `/move`
Send a move for a player.

Example:
```text
GET /move?table=ai1&player=Alice&VM=D
```

## 3. Understanding `/state` response

The `/state` endpoint returns JSON like:
```json
{
  "dd": 72,
  "dp": 5,
  "ts": 3,
  "lmp": "Player1 played a Five",
  "pls": [
    {"n":"Alice","s":1,"nc":5,"ph":"159","pvm":"3D","sc":12,"hc":false},
    ...
  ]
}
```

Key fields:
- `dd`: remaining draw deck cards
- `dp`: current discard card value
- `ts`: table status (2 = waiting, 3 = playing, 4 = round over, 5 = game over)
- `lmp`: last move played message
- `pls`: player list
  - `n` = player name
  - `s` = player status
  - `nc` = number of cards in hand
  - `ph` = hand summary string
  - `pvm` = valid move string
  - `sc` = score
  - `hc` = HasCat marker

## 4. Valid Move Codes

The server uses one-letter and digit codes for moves.

Common move codes:
- `0` = play Dog card (wild card win)
- `1`..`9` = play matching numbered card
- `B`, `H`, `N`, `J`, `M`, `K` = bunny hop to player slots 1–6
- `D` = draw card
- `F` = fold
- `R` = view round results
- `G` = view game over results

Your client should read `pvm` and present only allowed moves.

## 5. Client behavior

### Typical flow
1. call `/tables`
2. let user choose a table and player name
3. call `/join?table=...&player=...`
4. optionally call `/start?table=...` if the game is waiting
5. poll `/state?table=...&player=...` every 1–2 seconds
6. display game state and valid moves
7. send `/move?table=...&player=...&VM=...` when user chooses a move

### Polling
Clients should poll `GET /state` frequently enough to stay up to date.
- Web clients: `setInterval(...)`
- desktop/mobile: timer loop
- retro/embedded: game loop tick

### UI hints
- Show the discard card and remaining deck count
- Highlight which player is currently active
- Show valid moves from `pvm` clearly
- Show a distinct message when `ts` is 4 or 5

## 6. Example JavaScript client request

```js
async function fetchState(table, player) {
  const res = await fetch(`/state?table=${encodeURIComponent(table)}&player=${encodeURIComponent(player)}`);
  return res.json();
}

async function sendMove(table, player, vm) {
  const res = await fetch(`/move?table=${encodeURIComponent(table)}&player=${encodeURIComponent(player)}&VM=${encodeURIComponent(vm)}`);
  return res.text();
}
```

## 7. Client architecture suggestions

### Web client
- call the server directly from browser JavaScript
- render game information into HTML
- support click/tap input for moves

### Desktop client
- use HTTP libraries for polling and moves
- render with your favorite UI toolkit

### GameMaker client
- use `http_get` and the existing `Clients/Web/GameMaker` objects as a reference
- parse server responses and display card layouts

### Custom client ideas
- React/Vue web app
- Unity or Godot UI
- Python/Tkinter desktop app
- Console-based client
- Mobile client with touch controls

## 8. How to publish your client on GitHub

1. fork the BunnyHop repo on GitHub.
2. clone your fork locally.
3. create a feature branch, e.g. `feature/my-client`.
4. add a new folder under `Clients/` for your client.
5. include a `README.md` inside your client folder with usage notes.
6. commit your changes with a clear message.
7. push the branch to your fork.
8. open a Pull Request against the main BunnyHop repo.

### Suggested GitHub PR contents
- summary of the client type and platform
- how to run your client
- screenshots or demo links
- any known limitations

## 9. What to include in your client folder

A good client submission should include:
- source code
- assets or UI resources
- a short `README.md`
- instructions for running locally
- any build or dependency steps

## 10. Tips for contributors

- use the existing `Clients/Web/GameMaker` folder as a model
- keep API requests simple and reliable
- validate `pvm` before sending move requests
- do not assume player order is fixed; use the server state
- handle table status `2`, `3`, `4`, and `5`

## 11. Summary

This repo is ready for client contributions. Use the server API, follow the move codes, and publish your client as a new folder under `Clients/`.

Good luck building your own BunnyHop client!