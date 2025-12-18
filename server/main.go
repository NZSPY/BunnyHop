package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"

	"github.com/NZSPY/BunnyHop/server/game"
	"github.com/NZSPY/BunnyHop/server/websocket"
)

var addr = flag.String("addr", ":8080", "http service address")

func main() {
	flag.Parse()
	
	hub := websocket.NewHub()
	go hub.Run()
	
	gameManager := game.NewManager()
	
	// WebSocket endpoint
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		websocket.ServeWs(hub, gameManager, w, r)
	})
	
	// REST API endpoints
	http.HandleFunc("/api/games", func(w http.ResponseWriter, r *http.Request) {
		handleGames(w, r, gameManager)
	})
	
	http.HandleFunc("/api/games/create", func(w http.ResponseWriter, r *http.Request) {
		handleCreateGame(w, r, gameManager)
	})
	
	// Serve static files for HTML5 client
	fs := http.FileServer(http.Dir("../client-html5"))
	http.Handle("/", fs)
	
	log.Printf("BunnyHop server starting on %s", *addr)
	err := http.ListenAndServe(*addr, nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

func handleGames(w http.ResponseWriter, r *http.Request, gm *game.Manager) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	games := gm.ListGames()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(games)
}

func handleCreateGame(w http.ResponseWriter, r *http.Request, gm *game.Manager) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	var req struct {
		PlayerName string `json:"playerName"`
		MaxPlayers int    `json:"maxPlayers"`
	}
	
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	
	if req.MaxPlayers < 2 || req.MaxPlayers > 4 {
		req.MaxPlayers = 4
	}
	
	gameID := gm.CreateGame(req.PlayerName, req.MaxPlayers)
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"gameId": gameID,
		"message": fmt.Sprintf("Game created successfully by %s", req.PlayerName),
	})
}
