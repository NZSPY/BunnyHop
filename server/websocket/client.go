package websocket

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/NZSPY/BunnyHop/server/game"
	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// TODO: For production, restrict to specific origins
		// Example: return r.Header.Get("Origin") == "https://yourdomain.com"
		return true // Allow all origins for development
	},
}

type Client struct {
	hub     *Hub
	conn    *websocket.Conn
	send    chan []byte
	gameID  string
	playerID string
	gm      *game.Manager
}

type Message struct {
	Type   string                 `json:"type"`
	GameID string                 `json:"gameId,omitempty"`
	Data   map[string]interface{} `json:"data,omitempty"`
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()
	
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})
	
	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		
		c.handleMessage(message)
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()
	
	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			
			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)
			
			if err := w.Close(); err != nil {
				return
			}
			
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *Client) handleMessage(message []byte) {
	var msg Message
	if err := json.Unmarshal(message, &msg); err != nil {
		log.Printf("error unmarshaling message: %v", err)
		return
	}
	
	switch msg.Type {
	case "join_game":
		c.handleJoinGame(msg)
	case "start_game":
		c.handleStartGame(msg)
	case "play_card":
		c.handlePlayCard(msg)
	case "get_state":
		c.handleGetState(msg)
	}
}

func (c *Client) handleJoinGame(msg Message) {
	gameID, ok := msg.Data["gameId"].(string)
	if !ok {
		c.sendError("Invalid gameId")
		return
	}
	
	playerName, ok := msg.Data["playerName"].(string)
	if !ok {
		c.sendError("Invalid playerName")
		return
	}
	
	c.gameID = gameID
	c.playerID = playerName + "-" + time.Now().Format("150405")
	
	err := c.gm.JoinGame(gameID, c.playerID, playerName)
	
	response := Message{
		Type:   "join_result",
		GameID: gameID,
		Data: map[string]interface{}{
			"success":  err == nil,
			"playerId": c.playerID,
		},
	}
	
	if err != nil {
		response.Data["error"] = err.Error()
	}
	
	c.sendJSON(response)
	c.broadcastGameState()
}

func (c *Client) handleStartGame(msg Message) {
	err := c.gm.StartGame(c.gameID)
	
	response := Message{
		Type:   "start_result",
		GameID: c.gameID,
		Data: map[string]interface{}{
			"success": err == nil,
		},
	}
	
	if err != nil {
		response.Data["error"] = err.Error()
	}
	
	c.sendJSON(response)
	c.broadcastGameState()
}

func (c *Client) handlePlayCard(msg Message) {
	cardID, ok := msg.Data["cardId"].(string)
	if !ok {
		c.sendError("Invalid cardId")
		return
	}
	
	targetPlayerID := ""
	if target, ok := msg.Data["targetPlayerId"].(string); ok {
		targetPlayerID = target
	}
	
	wildColor := game.Color("")
	if color, ok := msg.Data["wildColor"].(string); ok {
		wildColor = game.Color(color)
	}
	
	wildValue := 0
	if value, ok := msg.Data["wildValue"].(float64); ok {
		wildValue = int(value)
	}
	
	err := c.gm.PlayCard(c.gameID, c.playerID, cardID, targetPlayerID, wildColor, wildValue)
	
	response := Message{
		Type:   "play_result",
		GameID: c.gameID,
		Data: map[string]interface{}{
			"success": err == nil,
		},
	}
	
	if err != nil {
		response.Data["error"] = err.Error()
	}
	
	c.sendJSON(response)
	c.broadcastGameState()
}

func (c *Client) handleGetState(msg Message) {
	g := c.gm.GetGame(c.gameID)
	if g == nil {
		return
	}
	
	response := Message{
		Type:   "game_state",
		GameID: c.gameID,
		Data:   g.GetState(),
	}
	
	c.sendJSON(response)
}

func (c *Client) broadcastGameState() {
	g := c.gm.GetGame(c.gameID)
	if g == nil {
		return
	}
	
	msg := Message{
		Type:   "game_state",
		GameID: c.gameID,
		Data:   g.GetState(),
	}
	
	data, err := json.Marshal(msg)
	if err != nil {
		log.Printf("error marshaling game state: %v", err)
		return
	}
	c.hub.BroadcastToGame(c.gameID, data)
}

func (c *Client) sendJSON(msg Message) {
	data, err := json.Marshal(msg)
	if err != nil {
		log.Printf("error marshaling message: %v", err)
		return
	}
	
	c.send <- data
}

func (c *Client) sendError(errMsg string) {
	log.Printf("client error: %s", errMsg)
	response := Message{
		Type: "error",
		Data: map[string]interface{}{
			"error": errMsg,
		},
	}
	c.sendJSON(response)
}

func ServeWs(hub *Hub, gm *game.Manager, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	
	client := &Client{
		hub:  hub,
		conn: conn,
		send: make(chan []byte, 256),
		gm:   gm,
	}
	
	client.hub.register <- client
	
	go client.writePump()
	go client.readPump()
}
