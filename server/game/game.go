package game

import (
	"fmt"
	"sync"
	"time"
)

type GameState string

const (
	GameStateWaiting  GameState = "waiting"
	GameStateStarted  GameState = "started"
	GameStateFinished GameState = "finished"
)

type Game struct {
	ID            string            `json:"id"`
	Players       map[string]*Player `json:"players"`
	DrawPile      []Card            `json:"-"`
	DiscardPile   []Card            `json:"discardPile"`
	CurrentPlayer int               `json:"currentPlayer"`
	State         GameState         `json:"state"`
	MaxPlayers    int               `json:"maxPlayers"`
	Direction     int               `json:"direction"` // 1 for forward, -1 for reverse
	Winner        string            `json:"winner,omitempty"`
	CreatedAt     time.Time         `json:"createdAt"`
	mu            sync.RWMutex
}

func NewGame(id string, maxPlayers int) *Game {
	deck := ShuffleDeck(NewDeck())
	
	game := &Game{
		ID:            id,
		Players:       make(map[string]*Player),
		DrawPile:      deck[1:], // Save first card for discard pile
		DiscardPile:   []Card{deck[0]},
		CurrentPlayer: 0,
		State:         GameStateWaiting,
		MaxPlayers:    maxPlayers,
		Direction:     1,
		CreatedAt:     time.Now(),
	}
	
	return game
}

func (g *Game) AddPlayer(player *Player) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	
	if g.State != GameStateWaiting {
		return fmt.Errorf("game already started")
	}
	
	if len(g.Players) >= g.MaxPlayers {
		return fmt.Errorf("game is full")
	}
	
	g.Players[player.ID] = player
	
	// Deal initial cards (5 per player)
	for i := 0; i < 5; i++ {
		if len(g.DrawPile) > 0 {
			card := g.DrawPile[0]
			g.DrawPile = g.DrawPile[1:]
			player.AddCard(card)
		}
	}
	
	return nil
}

func (g *Game) Start() error {
	g.mu.Lock()
	defer g.mu.Unlock()
	
	if len(g.Players) < 2 {
		return fmt.Errorf("need at least 2 players to start")
	}
	
	g.State = GameStateStarted
	return nil
}

func (g *Game) PlayCard(playerID, cardID string, targetPlayerID string, wildColor Color, wildValue int) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	
	if g.State != GameStateStarted {
		return fmt.Errorf("game not started")
	}
	
	player := g.Players[playerID]
	if player == nil {
		return fmt.Errorf("player not found")
	}
	
	if !g.IsPlayerTurn(playerID) {
		return fmt.Errorf("not your turn")
	}
	
	card := player.RemoveCard(cardID)
	if card == nil {
		return fmt.Errorf("card not in hand")
	}
	
	// Check if player is blocked
	if player.IsBlocked && card.Type == CardTypeHop {
		player.AddCard(*card) // Put card back
		player.IsBlocked = false // Remove block
		return fmt.Errorf("you are blocked from playing hop cards this turn")
	}
	
	// Apply card effect
	if err := g.applyCardEffect(*card, player, targetPlayerID, wildColor, wildValue); err != nil {
		player.AddCard(*card) // Put card back
		return err
	}
	
	// Add to discard pile
	g.DiscardPile = append(g.DiscardPile, *card)
	
	// Draw a card
	g.drawCard(player)
	
	// Check for winner
	if player.Position >= 20 {
		g.State = GameStateFinished
		g.Winner = playerID
		return nil
	}
	
	// Move to next player
	g.nextPlayer()
	
	return nil
}

func (g *Game) applyCardEffect(card Card, player *Player, targetPlayerID string, wildColor Color, wildValue int) error {
	switch card.Type {
	case CardTypeHop:
		spaces := card.Value
		if player.HasDouble {
			spaces *= 2
			player.HasDouble = false
		}
		player.MoveForward(spaces)
		
	case CardTypeAction:
		switch card.ActionType {
		case ActionSkip:
			g.nextPlayer() // Skip next player
			
		case ActionReverse:
			g.Direction *= -1
			
		case ActionBlock:
			if targetPlayerID != "" && targetPlayerID != player.ID {
				target := g.Players[targetPlayerID]
				if target != nil {
					target.IsBlocked = true
				}
			}
			
		case ActionDouble:
			player.HasDouble = true
		}
		
	case CardTypeSpecial:
		switch card.ActionType {
		case ActionWildHop:
			if wildValue > 0 && wildValue <= 10 {
				spaces := wildValue
				if player.HasDouble {
					spaces *= 2
					player.HasDouble = false
				}
				player.MoveForward(spaces)
			}
			
		case ActionWildAction:
			// Can be used as any action card - implement specific behavior as needed
			
		case ActionDrawTwo:
			// Next player draws 2 and skips
			g.nextPlayer()
			nextPlayer := g.getCurrentPlayer()
			if nextPlayer != nil {
				g.drawCard(nextPlayer)
				g.drawCard(nextPlayer)
			}
			
		case ActionFinishLine:
			if player.Position >= 15 {
				player.Position = 20 // Instant win
			} else {
				return fmt.Errorf("must be at position 15 or higher to use Finish Line")
			}
		}
	}
	
	return nil
}

func (g *Game) drawCard(player *Player) {
	if len(g.DrawPile) == 0 {
		// Reshuffle discard pile if draw pile is empty
		if len(g.DiscardPile) > 1 {
			topCard := g.DiscardPile[len(g.DiscardPile)-1]
			g.DrawPile = ShuffleDeck(g.DiscardPile[:len(g.DiscardPile)-1])
			g.DiscardPile = []Card{topCard}
		} else {
			return // No cards left
		}
	}
	
	if len(g.DrawPile) > 0 {
		card := g.DrawPile[0]
		g.DrawPile = g.DrawPile[1:]
		player.AddCard(card)
	}
}

func (g *Game) nextPlayer() {
	playerIDs := g.getPlayerIDs()
	if len(playerIDs) == 0 {
		return
	}
	
	g.CurrentPlayer += g.Direction
	
	if g.CurrentPlayer >= len(playerIDs) {
		g.CurrentPlayer = 0
	} else if g.CurrentPlayer < 0 {
		g.CurrentPlayer = len(playerIDs) - 1
	}
}

func (g *Game) getCurrentPlayer() *Player {
	playerIDs := g.getPlayerIDs()
	if g.CurrentPlayer < 0 || g.CurrentPlayer >= len(playerIDs) {
		return nil
	}
	return g.Players[playerIDs[g.CurrentPlayer]]
}

func (g *Game) getPlayerIDs() []string {
	ids := make([]string, 0, len(g.Players))
	for id := range g.Players {
		ids = append(ids, id)
	}
	return ids
}

func (g *Game) IsPlayerTurn(playerID string) bool {
	playerIDs := g.getPlayerIDs()
	if g.CurrentPlayer < 0 || g.CurrentPlayer >= len(playerIDs) {
		return false
	}
	return playerIDs[g.CurrentPlayer] == playerID
}

func (g *Game) GetTopCard() Card {
	if len(g.DiscardPile) > 0 {
		return g.DiscardPile[len(g.DiscardPile)-1]
	}
	return Card{}
}

func (g *Game) GetState() map[string]interface{} {
	g.mu.RLock()
	defer g.mu.RUnlock()
	
	return map[string]interface{}{
		"id":            g.ID,
		"state":         g.State,
		"players":       g.Players,
		"currentPlayer": g.CurrentPlayer,
		"topCard":       g.GetTopCard(),
		"direction":     g.Direction,
		"winner":        g.Winner,
	}
}
