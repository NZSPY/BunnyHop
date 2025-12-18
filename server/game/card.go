package game

import (
	"fmt"
	"math/rand"
	"time"
)

type CardType string

const (
	CardTypeHop     CardType = "hop"
	CardTypeAction  CardType = "action"
	CardTypeSpecial CardType = "special"
)

type Color string

const (
	ColorRed    Color = "red"
	ColorBlue   Color = "blue"
	ColorGreen  Color = "green"
	ColorYellow Color = "yellow"
	ColorWild   Color = "wild"
)

type ActionType string

const (
	ActionSkip       ActionType = "skip"
	ActionReverse    ActionType = "reverse"
	ActionBlock      ActionType = "block"
	ActionDouble     ActionType = "double"
	ActionWildHop    ActionType = "wild_hop"
	ActionWildAction ActionType = "wild_action"
	ActionDrawTwo    ActionType = "draw_two"
	ActionFinishLine ActionType = "finish_line"
)

type Card struct {
	ID         string     `json:"id"`
	Type       CardType   `json:"type"`
	Color      Color      `json:"color,omitempty"`
	Value      int        `json:"value,omitempty"`
	ActionType ActionType `json:"actionType,omitempty"`
}

func (c Card) String() string {
	if c.Type == CardTypeHop {
		return fmt.Sprintf("%s %d", c.Color, c.Value)
	}
	return string(c.ActionType)
}

func NewDeck() []Card {
	var deck []Card
	cardID := 0
	
	// Hop cards: 1-10 in each of 4 colors
	colors := []Color{ColorRed, ColorBlue, ColorGreen, ColorYellow}
	for _, color := range colors {
		for value := 1; value <= 10; value++ {
			deck = append(deck, Card{
				ID:    fmt.Sprintf("card-%d", cardID),
				Type:  CardTypeHop,
				Color: color,
				Value: value,
			})
			cardID++
		}
	}
	
	// Action cards: 2 of each type
	actions := []ActionType{ActionSkip, ActionReverse, ActionBlock, ActionDouble}
	for _, action := range actions {
		for i := 0; i < 2; i++ {
			deck = append(deck, Card{
				ID:         fmt.Sprintf("card-%d", cardID),
				Type:       CardTypeAction,
				ActionType: action,
			})
			cardID++
		}
	}
	
	// Special cards: 1 of each
	specials := []ActionType{ActionWildHop, ActionWildAction, ActionDrawTwo, ActionFinishLine}
	for _, special := range specials {
		deck = append(deck, Card{
			ID:         fmt.Sprintf("card-%d", cardID),
			Type:       CardTypeSpecial,
			ActionType: special,
			Color:      ColorWild,
		})
		cardID++
	}
	
	return deck
}

func ShuffleDeck(deck []Card) []Card {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	shuffled := make([]Card, len(deck))
	copy(shuffled, deck)
	
	r.Shuffle(len(shuffled), func(i, j int) {
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	})
	
	return shuffled
}
