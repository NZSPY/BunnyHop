package game

type Player struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Position int    `json:"position"`
	Hand     []Card `json:"hand"`
	IsActive bool   `json:"isActive"`
	IsBlocked bool  `json:"isBlocked"`
	HasDouble bool  `json:"hasDouble"`
}

func NewPlayer(id, name string) *Player {
	return &Player{
		ID:       id,
		Name:     name,
		Position: 0,
		Hand:     make([]Card, 0),
		IsActive: true,
		IsBlocked: false,
		HasDouble: false,
	}
}

func (p *Player) AddCard(card Card) {
	p.Hand = append(p.Hand, card)
}

func (p *Player) RemoveCard(cardID string) *Card {
	for i, card := range p.Hand {
		if card.ID == cardID {
			p.Hand = append(p.Hand[:i], p.Hand[i+1:]...)
			return &card
		}
	}
	return nil
}

func (p *Player) HasCard(cardID string) bool {
	for _, card := range p.Hand {
		if card.ID == cardID {
			return true
		}
	}
	return false
}

func (p *Player) MoveForward(spaces int) {
	p.Position += spaces
	if p.Position < 0 {
		p.Position = 0
	}
}
