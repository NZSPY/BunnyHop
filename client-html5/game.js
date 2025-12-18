// WebSocket connection
let ws = null;
let currentGameId = null;
let currentPlayerId = null;
let gameState = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    showScreen('lobby');
});

function showScreen(screenName) {
    document.querySelectorAll('.screen').forEach(screen => {
        screen.classList.remove('active');
    });
    document.getElementById(screenName).classList.add('active');
}

function showJoinGame() {
    document.getElementById('joinGameForm').classList.toggle('hidden');
    loadGamesList();
}

function loadGamesList() {
    fetch('/api/games')
        .then(response => response.json())
        .then(games => {
            const listContent = document.getElementById('gamesListContent');
            if (games.length === 0) {
                listContent.innerHTML = '<p>No games available</p>';
            } else {
                listContent.innerHTML = games.map(game => `
                    <div class="game-item">
                        <div class="game-item-info">
                            <strong>Game ${game.id.substring(0, 8)}</strong><br>
                            Players: ${game.playerCount}/${game.maxPlayers} | Status: ${game.state}
                        </div>
                        <div class="game-item-action">
                            <button class="btn btn-primary" onclick="joinGameById('${game.id}')">Join</button>
                        </div>
                    </div>
                `).join('');
            }
            document.getElementById('gamesList').classList.remove('hidden');
        })
        .catch(err => {
            console.error('Error loading games:', err);
            addLog('Error loading games list');
        });
}

function createGame() {
    const playerName = document.getElementById('playerName').value.trim();
    if (!playerName) {
        alert('Please enter your name');
        return;
    }
    
    fetch('/api/games/create', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            playerName: playerName,
            maxPlayers: 4
        })
    })
    .then(response => response.json())
    .then(data => {
        currentGameId = data.gameId;
        connectWebSocket();
        showScreen('waitingRoom');
        document.getElementById('currentGameId').textContent = currentGameId;
    })
    .catch(err => {
        console.error('Error creating game:', err);
        alert('Failed to create game');
    });
}

function joinGame() {
    const gameId = document.getElementById('gameId').value.trim();
    if (!gameId) {
        alert('Please enter a game ID');
        return;
    }
    
    joinGameById(gameId);
}

function joinGameById(gameId) {
    const playerName = document.getElementById('playerName').value.trim();
    if (!playerName) {
        alert('Please enter your name');
        return;
    }
    
    currentGameId = gameId;
    connectWebSocket();
    
    // Wait for WebSocket connection before sending join message
    setTimeout(() => {
        if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({
                type: 'join_game',
                data: {
                    gameId: gameId,
                    playerName: playerName
                }
            }));
        }
    }, 500);
}

function connectWebSocket() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws`;
    
    ws = new WebSocket(wsUrl);
    
    ws.onopen = () => {
        console.log('WebSocket connected');
        addLog('Connected to server');
    };
    
    ws.onmessage = (event) => {
        const message = JSON.parse(event.data);
        handleWebSocketMessage(message);
    };
    
    ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        addLog('Connection error');
    };
    
    ws.onclose = () => {
        console.log('WebSocket disconnected');
        addLog('Disconnected from server');
    };
}

function handleWebSocketMessage(message) {
    console.log('Received message:', message);
    
    switch (message.type) {
        case 'join_result':
            if (message.data.success) {
                currentPlayerId = message.data.playerId;
                showScreen('waitingRoom');
                document.getElementById('currentGameId').textContent = currentGameId;
                addLog(`Joined game as ${currentPlayerId}`);
            } else {
                alert('Failed to join game: ' + message.data.error);
            }
            break;
            
        case 'start_result':
            if (message.data.success) {
                addLog('Game started!');
            } else {
                alert('Failed to start game: ' + message.data.error);
            }
            break;
            
        case 'play_result':
            if (message.data.success) {
                addLog('Card played successfully');
            } else {
                alert('Failed to play card: ' + message.data.error);
            }
            break;
            
        case 'game_state':
            updateGameState(message.data);
            break;
    }
}

function updateGameState(state) {
    gameState = state;
    console.log('Game state updated:', state);
    
    if (state.state === 'waiting') {
        updateWaitingRoom(state);
    } else if (state.state === 'started') {
        showScreen('gameScreen');
        updateGameScreen(state);
    } else if (state.state === 'finished') {
        showWinnerScreen(state);
    }
}

function updateWaitingRoom(state) {
    const playersList = document.getElementById('playersList');
    const players = Object.values(state.players);
    
    playersList.innerHTML = '<h3>Players (' + players.length + '/' + state.maxPlayers + '):</h3>' +
        players.map(player => `
            <div class="player-item">
                ${player.name} ${player.id === currentPlayerId ? '(You)' : ''}
            </div>
        `).join('');
}

function updateGameScreen(state) {
    // Update players area
    const playersArea = document.getElementById('playersArea');
    const players = Object.values(state.players);
    const playerIds = Object.keys(state.players);
    const currentPlayerTurnId = playerIds[state.currentPlayer];
    
    playersArea.innerHTML = players.map((player, idx) => {
        const isCurrentTurn = playerIds[idx] === currentPlayerTurnId;
        const isYou = player.id === currentPlayerId;
        
        return `
            <div class="player-box ${isCurrentTurn ? 'current-player' : ''} ${isYou ? 'active' : ''}">
                <div class="player-name">${player.name} ${isYou ? '(You)' : ''}</div>
                <div class="player-position">Position: ${player.position}/20 🐰</div>
                <div class="player-cards">Cards: ${player.hand ? player.hand.length : 0}</div>
                ${player.isBlocked ? '<div style="color: red;">🚫 Blocked</div>' : ''}
                ${player.hasDouble ? '<div style="color: green;">✖️2 Double Active</div>' : ''}
            </div>
        `;
    }).join('');
    
    // Update top card
    const topCard = state.topCard;
    const topCardEl = document.getElementById('topCard');
    if (topCard && topCard.id) {
        topCardEl.innerHTML = renderCard(topCard, false);
    }
    
    // Update player hand
    const currentPlayer = state.players[currentPlayerId];
    if (currentPlayer) {
        const handEl = document.getElementById('hand');
        handEl.innerHTML = currentPlayer.hand.map(card => 
            renderCard(card, true, currentPlayerTurnId === currentPlayerId)
        ).join('');
    }
    
    // Update game info
    const gameInfo = document.getElementById('gameInfo');
    const direction = state.direction === 1 ? '→' : '←';
    gameInfo.innerHTML = `
        Turn: ${players[state.currentPlayer]?.name || 'Unknown'} | 
        Direction: ${direction} |
        ${currentPlayerTurnId === currentPlayerId ? '<strong>YOUR TURN!</strong>' : 'Waiting...'}
    `;
}

function renderCard(card, clickable = false, isYourTurn = false) {
    let colorClass = '';
    let content = '';
    
    if (card.type === 'hop') {
        colorClass = card.color;
        content = `
            <div class="card-value">${card.value}</div>
            <div class="card-icon">🐰</div>
        `;
    } else if (card.type === 'action' || card.type === 'special') {
        const icons = {
            'skip': '⏭️',
            'reverse': '🔄',
            'block': '🚫',
            'double': '✖️2',
            'wild_hop': '🌈🐰',
            'wild_action': '🌈⚡',
            'draw_two': '+2',
            'finish_line': '🏁'
        };
        
        colorClass = card.color === 'wild' ? 'wild' : card.type === 'action' ? 'action' : 'special';
        content = `
            <div class="card-icon">${icons[card.actionType] || '⚡'}</div>
            <div class="card-type">${card.actionType.replace('_', ' ')}</div>
        `;
    }
    
    const onclick = clickable && isYourTurn ? `onclick="playCard('${card.id}')"` : '';
    const playableClass = clickable && isYourTurn ? 'playable' : '';
    
    return `<div class="card ${colorClass} ${playableClass}" ${onclick}>${content}</div>`;
}

function playCard(cardId) {
    if (!ws || ws.readyState !== WebSocket.OPEN) {
        alert('Not connected to server');
        return;
    }
    
    // For wild cards, prompt for color/value
    const card = gameState.players[currentPlayerId].hand.find(c => c.id === cardId);
    let wildColor = '';
    let wildValue = 0;
    
    if (card.actionType === 'wild_hop') {
        wildValue = parseInt(prompt('Enter hop value (1-10):', '5'));
        if (!wildValue || wildValue < 1 || wildValue > 10) {
            return;
        }
    }
    
    ws.send(JSON.stringify({
        type: 'play_card',
        data: {
            cardId: cardId,
            wildColor: wildColor,
            wildValue: wildValue
        }
    }));
}

function startGame() {
    if (!ws || ws.readyState !== WebSocket.OPEN) {
        alert('Not connected to server');
        return;
    }
    
    ws.send(JSON.stringify({
        type: 'start_game'
    }));
}

function leaveGame() {
    if (ws) {
        ws.close();
    }
    backToLobby();
}

function backToLobby() {
    if (ws) {
        ws.close();
    }
    currentGameId = null;
    currentPlayerId = null;
    gameState = null;
    showScreen('lobby');
    document.getElementById('log').innerHTML = '';
}

function showWinnerScreen(state) {
    showScreen('winnerScreen');
    const winnerPlayer = state.players[state.winner];
    document.getElementById('winnerMessage').textContent = 
        `${winnerPlayer?.name || 'Unknown'} wins the game! 🎉`;
}

function addLog(message) {
    const log = document.getElementById('log');
    if (log) {
        const entry = document.createElement('div');
        entry.className = 'log-entry';
        entry.textContent = `[${new Date().toLocaleTimeString()}] ${message}`;
        log.appendChild(entry);
        log.scrollTop = log.scrollHeight;
    }
}
