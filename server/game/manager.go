package game

import (
	"fmt"
	"sync"

	"github.com/google/uuid"
)

type Manager struct {
	games map[string]*Game
	mu    sync.RWMutex
}

func NewManager() *Manager {
	return &Manager{
		games: make(map[string]*Game),
	}
}

func (m *Manager) CreateGame(creatorName string, maxPlayers int) string {
	m.mu.Lock()
	defer m.mu.Unlock()
	
	gameID := "game-" + uuid.New().String()
	game := NewGame(gameID, maxPlayers)
	
	// Add creator as first player
	playerID := "player-" + uuid.New().String()
	creator := NewPlayer(playerID, creatorName)
	game.AddPlayer(creator)
	
	m.games[gameID] = game
	return gameID
}

func (m *Manager) GetGame(gameID string) *Game {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	return m.games[gameID]
}

func (m *Manager) ListGames() []map[string]interface{} {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	games := make([]map[string]interface{}, 0, len(m.games))
	for _, game := range m.games {
		games = append(games, map[string]interface{}{
			"id":          game.ID,
			"state":       game.State,
			"playerCount": len(game.Players),
			"maxPlayers":  game.MaxPlayers,
			"createdAt":   game.CreatedAt,
		})
	}
	
	return games
}

func (m *Manager) JoinGame(gameID, playerID, playerName string) error {
	game := m.GetGame(gameID)
	if game == nil {
		return fmt.Errorf("game not found")
	}
	
	player := NewPlayer(playerID, playerName)
	return game.AddPlayer(player)
}

func (m *Manager) StartGame(gameID string) error {
	game := m.GetGame(gameID)
	if game == nil {
		return fmt.Errorf("game not found")
	}
	
	return game.Start()
}

func (m *Manager) PlayCard(gameID, playerID, cardID, targetPlayerID string, wildColor Color, wildValue int) error {
	game := m.GetGame(gameID)
	if game == nil {
		return fmt.Errorf("game not found")
	}
	
	return game.PlayCard(playerID, cardID, targetPlayerID, wildColor, wildValue)
}
