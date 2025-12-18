package main

import (
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

type GameState struct {
	Table          GameTable
	NumCards       int
	Discard        Card
	Players        Players
	Maindeck       Deck
	LastMovePlayed string // Last move made by the active player (e.g., "play", "fold", "draw")
	EndedLast      int    // The index of the player who ended the last round
	RoundOver      bool   // Indicates if the round is over
	Gameover       bool   // Indicates if the game is over
	startTime      time.Time
}

var gameStates = make([]GameState, 7)
var LOBBY_ENDPOINT_UPSERT string
var UpdateLobby bool

type GameTable struct {
	Table      string `json:"t"`
	Name       string `json:"n"`
	CurPlayers int    `json:"p"` // human players
	MaxPlayers int    `json:"m"` // human players
	maxBots    int    // max bots allowed (internal use)
	Status     int    `json:"s"` // status of the table, "0=empty" "1=full" "2=waiting"  "3=playing" "4=roundover" "5=gameover"
}

var tables = []GameTable{
	{Table: "garden", Name: "The Garden", CurPlayers: 0, MaxPlayers: 6, maxBots: 5, Status: 0},
	{Table: "ai1", Name: "AI Room - 1 bots", CurPlayers: 0, MaxPlayers: 6, maxBots: 1, Status: 0},
	{Table: "ai2", Name: "AI Room - 2 bots", CurPlayers: 0, MaxPlayers: 6, maxBots: 2, Status: 0},
	{Table: "ai3", Name: "AI Room - 3 bots", CurPlayers: 0, MaxPlayers: 6, maxBots: 3, Status: 0},
	{Table: "ai4", Name: "AI Room - 4 bots", CurPlayers: 0, MaxPlayers: 6, maxBots: 4, Status: 0},
	{Table: "ai5", Name: "AI Room - 5 bots", CurPlayers: 0, MaxPlayers: 6, maxBots: 5, Status: 0},
	{Table: "cave", Name: "Cave of Caerbannog", CurPlayers: 0, MaxPlayers: 6, maxBots: 5, Status: 0},
}

type Status int

const (
	STATUS_WAITING         Status = 0
	STATUS_PLAYING         Status = 1
	STATUS_FOLDED          Status = 2
	STATUS_WON             Status = 3 // Player has won the round
	STATUS_ROUND_VIEWED    Status = 4 // Player has the results of the round
	STATUS_GAMEOVER_VIEWED Status = 5 // Player has the results of the end of game
)

// Deck represents a collection of cards.
type Deck []Card

// card represents a playing card with it's name and value
type Card struct {
	Cardvalue int    `json:"cv"`
	Cardname  string `json:"cn"`
}

type Player struct {
	Name           string
	Human          bool
	Status         Status
	WhiteTokens    int
	BlackTokens    int
	Score          int
	Hand           Deck
	NumCards       int       // Number of cards in hand
	ValidMove      string    // List of valid moves for the player (e.g., "play", "fold", "draw")
	Playorder      int       // The order in which the player plays (0 is first)
	RoundScore     int       // Score for the current round
	LastPolledTime time.Time // The time when the player last called the get state function
	Handsumary     string    // store the hand summary form for sending via JSON to 8 bit computers the
}

// Players represents a the players at a table
type Players []Player

func main() {
	log.Print("Starting server...")

	// Set environment flags
	UpdateLobby = os.Getenv("GO_PROD") == "1"
	/*
		if UpdateLobby {
			gin.SetMode(gin.ReleaseMode)
			LOBBY_ENDPOINT_UPSERT = "http://lobby.fujinet.online/server"
		} else {
			LOBBY_ENDPOINT_UPSERT = "http://qalobby.fujinet.online/server"
		}

		log.Print("This instance will update the lobby at " + LOBBY_ENDPOINT_UPSERT)
	*/

	// Determine port for HTTP service.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Listing on port %s", port)

	// Initialize the tables and game states
	for i := 0; i < len(gameStates); i++ {
		gameStates[i] = GameState{Table: tables[i],
			Maindeck:       Deck{},
			NumCards:       0,
			Discard:        Card{},
			Players:        Players{},
			LastMovePlayed: "Waiting for players to join",
			startTime:      time.Now(),
			EndedLast:      -1,
			RoundOver:      false,
			Gameover:       false}
		setUpTable(i)  // Initialize each table with a new deck and shuffle it
		updateLobby(i) // Update the lobby with the initial state of each table
	}

	router := gin.Default()
	router.Use(cors.Default())            // All origins allowed by default (added this for testing via java script as it wouldn't work with it)
	router.GET("/tables", getTables)      // Get the list of tables
	router.GET("/devview", viewGameState) // View the game state for a specific table (IE Cheats view)
	router.GET("/state", getGameState)    // Get the game state for a specific table and player
	router.GET("/join", joinTable)        // Join a table
	router.GET("/start", StartNewGame)    // start a new game on a table (this also happens automaticly when the table is filled with players), if the table is not filled  it will fill the emplty slots with AI Players
	router.GET("/move", doVaildMoveURL)   // Make a move on the table (play, fold, draw)

	// Set up router and start server
	router.SetTrustedProxies(nil) // Disable trusted proxies because Gin told me to do it.. (neeed to investigate this further)
	router.Run(":" + port)
}

// getTables responds with the list of all tables  as JSON.
func getTables(c *gin.Context) {

	// if any games are over and all players have viewed the results then the game state is reset for a new game
	for i := 0; i < len(gameStates); i++ {
		if gameStates[i].Table.Status != 0 {
			idleTableClose(i) // Close any tables with no human players
		}
		idlePlayerRemoval(i) // Remove any idle players from the tables
		if allViewedGameOver(i) && gameStates[i].Gameover {
			resetGame(i) // Reset the game state for a new game
		}
	}

	c.JSON(http.StatusOK, tables)
}

// View the State retrieves the game state for a specific table or all if none specified (cheating/dev view).
func viewGameState(c *gin.Context) {
	tableIndex := -1
	ok := false
	tableIndex, ok = getTableIndex(c)
	if ok {
		c.IndentedJSON(http.StatusOK, gameStates[tableIndex]) // Return the game state for the specified table
	} else {
		c.IndentedJSON(http.StatusOK, gameStates) // Return all game states if no specific table is requested
	}

	elapsed := time.Since(gameStates[tableIndex].startTime)
	fmt.Println("Elapsed time:", elapsed)

}

// NewDeck creates a new Llama 56-card deck.
func NewDeck() []Card {
	deck := make([]Card, 56)

	cardNames := []string{"One", "Two", "Three", "Four", "Five", "Six", "Llama"}

	currentCard := 0
	for value := 1; value <= 7; value++ {
		for i := 0; i < 8; i++ {
			deck[currentCard] = Card{Cardvalue: value, Cardname: cardNames[value-1]}
			currentCard++
		}
	}
	return deck
}

func setUpTable(tableIndex int) {
	if tableIndex < 0 || tableIndex >= len(gameStates) {
		return // Invalid table index
	}
	gameStates[tableIndex].Maindeck = NewDeck()              // Create a new deck for the table
	shuffleDeck(gameStates[tableIndex].Maindeck, tableIndex) // Shuffle the deck and set the discard pile
}

// shuffleDeck shuffles the deck using the Fisher-Yates algorithm.
// And deal out the first card to the discard pile.
func shuffleDeck(deck []Card, tableIndex int) {
	for i := len(deck) - 1; i > 0; i-- {
		j := rand.Intn(i + 1)
		deck[i], deck[j] = deck[j], deck[i]
	}
	gameStates[tableIndex].Discard = gameStates[tableIndex].Maindeck[55] // Set the discard to the last card in the deck
	gameStates[tableIndex].NumCards = 55
}

// find the table index from the query parameter
// Returns the table index and a boolean indicating a vaild table was found
func getTableIndex(c *gin.Context) (int, bool) {
	tableIndex := -1
	ok := false
	if tableStr := c.Query("table"); tableStr != "" {
		// Find the table index by matching the table name
		for i, t := range tables {
			if t.Table == tableStr {
				tableIndex = i
				ok = true
				break
			}
		}
	}
	return tableIndex, ok
}

// joinTable allows a player to join a table.
func joinTable(c *gin.Context) {
	tableIndex := -1
	ok := false
	tableIndex, ok = getTableIndex(c)
	newplayerName := c.Query("player")
	newplayer := Player{
		Name:           newplayerName,
		Human:          true,
		Status:         STATUS_WAITING,
		WhiteTokens:    0,
		BlackTokens:    0,
		Score:          0,
		RoundScore:     0,
		Hand:           Deck{},
		NumCards:       0,          // Initially, the player has no cards in hand
		ValidMove:      "",         // Initially, the player doesn't have any valid moves
		Playorder:      0,          // Set the play order to the current number of players
		LastPolledTime: time.Now(), // Set the last polled time to now
	}
	fmt.Println("A player is trying to join table:", string(tables[tableIndex].Table), " with name:", newplayerName) // Log the player trying to join the table

	// Add the new player to the game state if a valid condtions are met
	switch {
	case !ok:
		c.JSON(http.StatusNotFound, "ERR(1)You need to specify a valid table and player name to join") // Notify the player to specify a table and player name
		return
	case newplayerName == "":
		c.JSON(http.StatusNotFound, "ERR(2)You need to supply a player name to join a table")
		return
	case checkPlayerName(tableIndex, newplayerName):
		c.JSON(http.StatusNotFound, "ERR(3) Sorry: "+newplayerName+" someone is already at table with that name ,please try a different table and or name") // Notify the player name is already taken
		return
	case gameStates[tableIndex].Table.Status == 3 || gameStates[tableIndex].Table.Status == 4 || gameStates[tableIndex].Table.Status == 5:
		c.JSON(http.StatusNotFound, "ERR(4) Sorry: "+newplayerName+" table "+tables[tableIndex].Table+" has a game in progress, please try a different table") // Notify the player that the table is busy
		return
	case gameStates[tableIndex].Table.Status == 1:
		gameStates[tableIndex].Table.Status = 1
		c.JSON(http.StatusNotFound, "ERR(5) Sorry: "+newplayerName+" table "+tables[tableIndex].Table+" is full, please try a different table") // Notify the player that the table is full
		return

	default:
		c.JSON(http.StatusOK, newplayerName+" joined table "+tables[tableIndex].Table)                         // Notify the player that they have successfully joined the table
		fmt.Println("Success !!.. Player ", newplayerName, " Joined table ", string(tables[tableIndex].Table)) // Log the player joining the table
		gameStates[tableIndex].Table.Status = 2                                                                // set status to waiting
		gameStates[tableIndex].Players = append(gameStates[tableIndex].Players, newplayer)
		gameStates[tableIndex].Players[len(gameStates[tableIndex].Players)-1].Playorder = gameStates[tableIndex].Table.CurPlayers // Set the play order for the new player
		gameStates[tableIndex].Table.CurPlayers++                                                                                 // Increment the current players count
		if (gameStates[tableIndex].Table.Table == "cave" || gameStates[tableIndex].Table.Table == "river") && gameStates[tableIndex].Table.CurPlayers > 1 {
			gameStates[tableIndex].Table.maxBots = 0 // No bots allowed in cave or river if more than 2 or more human players
		}
		if gameStates[tableIndex].Table.CurPlayers >= gameStates[tableIndex].Table.MaxPlayers {
			gameStates[tableIndex].Table.Status = 1 // Set the status to full if max players reached
			c.Params = []gin.Param{{Key: "sup", Value: "1"}}
			StartNewGame(c) // Automatically start a new game if the table is full
		}
		tables[tableIndex].CurPlayers = gameStates[tableIndex].Table.CurPlayers // update the quick table view players count
		tables[tableIndex].Status = gameStates[tableIndex].Table.Status         // update the quick table view status
		gameStates[tableIndex].startTime = time.Now()                           // Reset the waiting timer for the game state
		updateLobby(tableIndex)                                                 // Update the lobby with the new table state
	}
}

// Check if player name is already taken
func checkPlayerName(tableIndex int, newplayerName string) bool {
	ok := false
	for _, player := range gameStates[tableIndex].Players {
		if player.Name == newplayerName {
			ok = true
		}
	}
	return ok
}

// start a new game on the table
func StartNewGame(c *gin.Context) {
	tableIndex := -1
	ok := false
	surpress := false
	if c.Param("sup") == "1" {
		surpress = true
	}

	tableIndex, ok = getTableIndex(c)
	switch {
	case !ok || tableIndex < 0 || tableIndex >= len(gameStates):
		// If no table is specified or invalid table index, return an error
		if !surpress {
			c.JSON(http.StatusNotFound, "You need to specify a valid table to start a new game EG: /start?table=ai1")
		}
		return
	case gameStates[tableIndex].Table.CurPlayers == 0:
		if !surpress {
			c.JSON(http.StatusNotFound, "Sorry: table "+tables[tableIndex].Table+" has no human players, please join the table before starting a game")
		}
		return
	case gameStates[tableIndex].Table.Status == 3:
		if !surpress {
			c.JSON(http.StatusNotFound, "Sorry: table "+tables[tableIndex].Table+" has a game in progress, please try a different table")
		}
		return
	default:
		// Start the game state for the table
		if !surpress {
			c.JSON(http.StatusOK, "New game started on table "+tables[tableIndex].Table)
		}
		// fill up the empty slots with AI players if there are less than 6 players up to the maxiumum  bots allowed at that table

		for i := 0; i < gameStates[tableIndex].Table.maxBots; i++ {
			if gameStates[tableIndex].Table.CurPlayers >= (gameStates[tableIndex].Table.MaxPlayers) {
				break // Stop adding AI players if the maximum number of players is reached
			}
			// Create a new AI player
			newAIPlayer := Player{
				Name:        fmt.Sprintf("AI-%d", i+1),
				Human:       false,
				Status:      STATUS_WAITING,
				WhiteTokens: 0,
				BlackTokens: 0,
				Score:       0,
				RoundScore:  0,
				Hand:        Deck{},
				Playorder:   gameStates[tableIndex].Table.CurPlayers, // Set the play order based on the current number of players
			}
			gameStates[tableIndex].Players = append(gameStates[tableIndex].Players, newAIPlayer)
			gameStates[tableIndex].Table.CurPlayers++
		}

		if (gameStates[tableIndex].Table.Table == "cave" || gameStates[tableIndex].Table.Table == "river") && gameStates[tableIndex].Table.CurPlayers > 1 {
			gameStates[tableIndex].Table.maxBots = 6 // restore max bots to 6 for cave and river tables
		}
		gameStates[tableIndex].Table.Status = 3                                                                                           // Set the table status to playing
		tables[tableIndex].CurPlayers = gameStates[tableIndex].Table.CurPlayers                                                           // Update the quick table view players count
		tables[tableIndex].Status = gameStates[tableIndex].Table.Status                                                                   // Update the quick table view status
		gameStates[tableIndex].Players[0].Status = STATUS_PLAYING                                                                         // make the first player status to playing
		gameStates[tableIndex].LastMovePlayed = "Game Started, Waiting for " + gameStates[tableIndex].Players[0].Name + " to make a move" // Update the last move played to indicate the game has started
		updateLobby(tableIndex)                                                                                                           // Update the lobby with the new table state
		dealCards(tableIndex)                                                                                                             // Deal cards to all players at the table

	}
}

// deal cards to all players
func dealCards(tableIndex int) {

	for i := 0; i < gameStates[tableIndex].Table.CurPlayers; i++ {
		player := &gameStates[tableIndex].Players[i]

		for j := 0; j < 6; j++ {
			player.Hand = append(player.Hand, gameStates[tableIndex].Maindeck[gameStates[tableIndex].NumCards]) // draw the last card from the deck
			gameStates[tableIndex].NumCards--                                                                   // Decrement the number of cards in the deck
			player.NumCards++                                                                                   // Increment the number of cards in the player's hand
		}
		// sortCards(tableIndex, i) // Sort the player's hand after dealing
	}

}

// getGameState retrieves the game state for a specific player at a specific table
func getGameState(c *gin.Context) {
	tableIndex, ok := getTableIndex(c)
	playerName := c.Query("player")

	if !ok || playerName == "" {
		c.JSON(http.StatusNotFound, "ERR(6) Must specify both table and player name")
		return
	}

	// Check the player is at this table
	playerFound := false
	for _, player := range gameStates[tableIndex].Players {
		if player.Name == playerName {
			playerFound = true

		}
	}
	if !playerFound {
		c.JSON(http.StatusNotFound, "ERR(7) Player not found at this table")
		return
	}

	// Update the player's last polled time and get vaild moves
	playerIndex := findPlayerIndex(tableIndex, playerName)
	if playerIndex != -1 {
		gameStates[tableIndex].Players[playerIndex].LastPolledTime = time.Now()
		gameStates[tableIndex].Players[playerIndex].ValidMove = setValidmoves(tableIndex, playerIndex)
	}

	elapsed := time.Since(gameStates[tableIndex].startTime)

	// Create player state info for all players at table
	playerStates := make([]struct {
		Name        string `json:"n"`
		Status      Status `json:"s"`
		NumCards    int    `json:"nc"`
		WhiteTokens int    `json:"wt"`
		BlackTokens int    `json:"bt"`
		HandSummary string `json:"ph"`
		ValidMove   string `json:"pvm"`
	}, len(gameStates[tableIndex].Players))

	for i, player := range gameStates[tableIndex].Players {
		playerStates[i] = struct {
			Name        string `json:"n"`
			Status      Status `json:"s"`
			NumCards    int    `json:"nc"`
			WhiteTokens int    `json:"wt"`
			BlackTokens int    `json:"bt"`
			HandSummary string `json:"ph"`
			ValidMove   string `json:"pvm"`
		}{
			Name:        player.Name,
			Status:      player.Status,
			NumCards:    player.NumCards,
			WhiteTokens: player.WhiteTokens,
			BlackTokens: player.BlackTokens,
			HandSummary: makeHandSummary(tableIndex, i),
			ValidMove:   player.ValidMove,
		}
	}

	// Create simplified game state response with player's hand
	response := struct {
		DrawDeck       int         `json:"dd"`
		DiscardPile    int         `json:"dp"`
		TablesStatus   int         `json:"ts"`
		LastMovePlayed string      `json:"lmp"` // Last move played
		Players        interface{} `json:"pls"`
	}{

		DrawDeck:       gameStates[tableIndex].NumCards,
		DiscardPile:    gameStates[tableIndex].Discard.Cardvalue,
		TablesStatus:   gameStates[tableIndex].Table.Status,
		LastMovePlayed: gameStates[tableIndex].LastMovePlayed,
		Players:        playerStates,
	}

	c.JSON(http.StatusOK, response)

	// If the table is waiting for players and the waiting timer has exceeded 45 seconds, start the game
	if elapsed >= 45*time.Second && gameStates[tableIndex].Table.Status == 2 {
		gameStates[tableIndex].startTime = time.Now() // Reset the waiting timer
		elapsed = time.Since(gameStates[tableIndex].startTime)
		fmt.Println("Waiting timer exceeded, starting new game")
		c.Params = []gin.Param{{Key: "sup", Value: "1"}}
		StartNewGame(c)
	}
	// If the table is playing and the waiting timer has exceeded 2 seconds, make an AI move if it's an AI player's turn
	if elapsed >= 2*time.Second && gameStates[tableIndex].Table.Status == 3 {
		for i := 0; i < len(gameStates[tableIndex].Players); i++ {
			if gameStates[tableIndex].Players[i].Status == STATUS_PLAYING && !gameStates[tableIndex].Players[i].Human {
				move := aiMove(tableIndex, i)    // AI move function to determine the AI's move)
				doVaildMove(tableIndex, i, move) // Perform the AI's move
				break                            // Exit the loop after the AI makes a move
			}
		}
	}

	// If the table is playing and the waiting timer has exceeded 60 seconds, Auto fold the player who has not made a move in 60 seconds
	if elapsed >= 60*time.Second && gameStates[tableIndex].Table.Status == 3 {
		gameStates[tableIndex].startTime = time.Now() // Reset the waiting timer
		for i := 0; i < len(gameStates[tableIndex].Players); i++ {
			if gameStates[tableIndex].Players[i].Status == STATUS_PLAYING {
				doVaildMove(tableIndex, i, "F") // If the player has not made a move in 60 seconds, fold them
				fmt.Println("Waiting timer exceeded 60 seconds, folding", gameStates[tableIndex].Players[i].Name)
				break // Exit the loop after folding the first player who is still playing
			}
		}
	}

	// Check if the round has ended and handle the end of the round logic
	if checkRoundEndCondtions(tableIndex) {
		fmt.Println("Round ended for table 1", tables[tableIndex].Table)
		EndofRoundScore(tableIndex) // Call the end of round scoring function
	}

	// check if all players have viewed the results and reset the game state if so
	if allViewedResults(tableIndex) && gameStates[tableIndex].RoundOver {
		if gameStates[tableIndex].Gameover {
			SetEndofGameStatus(tableIndex)
			fmt.Println("All players have viewed the results, Sorting for gameover", tables[tableIndex].Table)
			gameStates[tableIndex].Table.Status = 5 // Set the table status to game over
			tables[tableIndex].Status = gameStates[tableIndex].Table.Status
		} else {
			fmt.Println("All players have viewed the results, resetting game for table", tables[tableIndex].Table)
			resetTable(tableIndex) // Reset the game state for a new round
		}
	}

	// check if all players have viewed the results and reset the game state if so
	if allViewedGameOver(tableIndex) && gameStates[tableIndex].Gameover {
		fmt.Println("All players have viewed the final results, resetting game for table", tables[tableIndex].Table)
		resetGame(tableIndex) // Reset the game state for a new game
	}

	idlePlayerChange(tableIndex)
}

// check if any human players have disconnected ? (IE not polled the game state for over 3 minutes) and turn them into AI players
func idlePlayerChange(tableIndex int) {
	for i := 0; i < len(gameStates[tableIndex].Players); i++ {
		player := &gameStates[tableIndex].Players[i]
		if time.Since(player.LastPolledTime) > 3*time.Minute && player.Human {
			gameStates[tableIndex].Players[i].Human = false                                         // Change the player to an AI player
			gameStates[tableIndex].Players[i].Name = gameStates[tableIndex].Players[i].Name + "-AI" // Change the player name to indicate they are now an AI player
		}
	}
}

// check if any human players have disconnected (IE not polled the game state for over 5 minutes) and remove them from the table
func idlePlayerRemoval(tableIndex int) {
	for i := 0; i < len(gameStates[tableIndex].Players); i++ {
		player := &gameStates[tableIndex].Players[i]
		if time.Since(player.LastPolledTime) > 5*time.Minute && player.Human {
			// Remove the player from the table
			gameStates[tableIndex].Players = append(gameStates[tableIndex].Players[:i], gameStates[tableIndex].Players[i+1:]...)
			gameStates[tableIndex].Table.CurPlayers--
			tables[tableIndex].CurPlayers = gameStates[tableIndex].Table.CurPlayers // update the quick table view players count
			i--                                                                     // Adjust index after removal
		}
	}
}

// check if any human players are at the table and if not reset the game state
func idleTableClose(tableIndex int) {
	for i := 0; i < len(gameStates[tableIndex].Players); i++ {
		if gameStates[tableIndex].Players[i].Human {
			return // Exit the function if a human player is found
		}
	}
	// If no human players are found, reset the table
	resetGame(tableIndex) // Reset the game state for a new game
	fmt.Println("No human players at table, resetting game for table", tables[tableIndex].Table)
}

// find the index of a player at a table by their name
func findPlayerIndex(tableIndex int, playerName string) int {
	for i, player := range gameStates[tableIndex].Players {
		if player.Name == playerName {
			return i // Return the index of the player if found
		}
	}
	return -1 // Return -1 if the player is not found
}

// checks the player's hand and returns a string of valid moves possible for that player
func setValidmoves(tableIndex int, playerIndex int) string {
	validMoves := ""

	if gameStates[tableIndex].Table.Status == 4 { // If the round is over, players can only view results
		return "R" // Player can view results
	}

	if gameStates[tableIndex].Table.Status == 5 { // If the Game is over, players can only view game over re
		return "G" // Player can view results
	}

	if gameStates[tableIndex].Players[playerIndex].Status == STATUS_PLAYING {
		// Check if any card in hand matches or is higher than discard pile
		for _, card := range gameStates[tableIndex].Players[playerIndex].Hand {
			if card.Cardvalue == gameStates[tableIndex].Discard.Cardvalue {
				validMoves = strconv.Itoa(gameStates[tableIndex].Discard.Cardvalue) // Player can play a matching card
				break
			}
		}
		for _, card := range gameStates[tableIndex].Players[playerIndex].Hand {
			nextValue := gameStates[tableIndex].Discard.Cardvalue + 1
			if nextValue > 7 {
				nextValue = 1
			}
			if card.Cardvalue == nextValue {
				validMoves = validMoves + strconv.Itoa(nextValue) // Player can play a matching card
				break
			}
		}
		lastone := false
		foldedCount := 0

		for _, player := range gameStates[tableIndex].Players {
			if player.Status == STATUS_FOLDED {
				foldedCount++
			}
		}
		if foldedCount == len(gameStates[tableIndex].Players)-1 { // If all but one player has folded, the last player can not draw any new cards
			lastone = true
		}
		if gameStates[tableIndex].NumCards > 0 && !lastone {
			validMoves = validMoves + "D" // Player can draw
		}
		if gameStates[tableIndex].Players[playerIndex].Status == STATUS_PLAYING {
			validMoves = validMoves + "F" // Player can fold
		}
	}

	return validMoves
}

func doVaildMoveURL(c *gin.Context) {

	tableIndex, ok := getTableIndex(c)
	if !ok { // If no table is specified or invalid table index, return an error

		c.JSON(http.StatusBadRequest, "Must specify a valid table")

		return
	}

	// Find the player and check their status
	playerName := c.Query("player")
	move := c.Query("VM") // Valid Move (e.g., "P", "N", "D", "F","R","G")
	var playerFound bool
	var validMoves string
	playerIndex := -1
	i := -1
	for _, player := range gameStates[tableIndex].Players {
		i++
		if player.Name == playerName {
			playerFound = true
			playerIndex = i // Store the index of the player
			validMoves = player.ValidMove
			if player.Status != STATUS_PLAYING {

				if validMoves == "R" || validMoves == "G" {
					// If the player is allowed to view results, let them proceed

				} else {

					c.JSON(http.StatusBadRequest, "It's not your turn to play")

					return
				}
			}
		}
	}
	if !playerFound {

		c.JSON(http.StatusBadRequest, "Player not found at this table")

		return
	}

	if playerName == "" || move == "" {

		c.JSON(http.StatusBadRequest, "Must specify both player name and move")

		return
	}
	if !strings.Contains(validMoves, move) {

		c.JSON(http.StatusBadRequest, "Thats not a valid move, please try again")

		return
	}

	doVaildMove(tableIndex, playerIndex, move) // Call the doVaildMove function with the player and move
	c.JSON(http.StatusOK, gameStates[tableIndex].LastMovePlayed)
}

// Perform the valid move for the player at the specified table
func doVaildMove(tableIndex int, playerIndex int, move string) {

	nextValue := gameStates[tableIndex].Discard.Cardvalue + 1
	if nextValue > 7 {
		nextValue = 1
	}

	gameStates[tableIndex].startTime = time.Now() // Reset the waiting timer
	switch move {
	case strconv.Itoa(gameStates[tableIndex].Discard.Cardvalue): // Play card onto the discard pile
		gameStates[tableIndex].LastMovePlayed = gameStates[tableIndex].Players[playerIndex].Name + " played a " + gameStates[tableIndex].Discard.Cardname
		removeCardFromHand(tableIndex, playerIndex, gameStates[tableIndex].Discard) // Remove the played card from the player's hand
	case strconv.Itoa(nextValue): // Play card onto the discard pile
		cardNames := []string{"One", "Two", "Three", "Four", "Five", "Six", "Llama"}
		gameStates[tableIndex].LastMovePlayed = gameStates[tableIndex].Players[playerIndex].Name + " played a " + cardNames[nextValue-1]
		gameStates[tableIndex].Discard = Card{Cardvalue: nextValue, Cardname: cardNames[nextValue-1]}
		removeCardFromHand(tableIndex, playerIndex, Card{Cardvalue: nextValue, Cardname: cardNames[nextValue-1]}) // Remove the played card from the player's hand
	case "D": // Draw
		gameStates[tableIndex].LastMovePlayed = gameStates[tableIndex].Players[playerIndex].Name + " drew a card from the deck"
		addCardtohand(tableIndex, playerIndex) // Add a card to the player's hand
	case "F": // Fold
		gameStates[tableIndex].LastMovePlayed = gameStates[tableIndex].Players[playerIndex].Name + " folded"
		gameStates[tableIndex].Players[playerIndex].Status = STATUS_FOLDED
		gameStates[tableIndex].EndedLast = playerIndex
	case "R": // Viewed the results of the round
		gameStates[tableIndex].Players[playerIndex].Status = STATUS_ROUND_VIEWED
		gameStates[tableIndex].Players[playerIndex].ValidMove = "G" // Set valid move to view game over results only
		return
	case "G": // Viewed the gameover screens
		gameStates[tableIndex].Players[playerIndex].Status = STATUS_GAMEOVER_VIEWED
		gameStates[tableIndex].Players[playerIndex].ValidMove = ""
		return
	}

	// Update the player's  status
	gameStates[tableIndex].Players[playerIndex].ValidMove = "" // Clear the valid moves after the player has made a move
	if gameStates[tableIndex].Players[playerIndex].Status == STATUS_PLAYING {
		gameStates[tableIndex].Players[playerIndex].Status = STATUS_WAITING // Set the current player's status to waiting if they didn't fold
	}

	// check if the round end conditions have been met and if not find the next player to play
	if checkRoundEndCondtions(tableIndex) {
		fmt.Println("Round ended for table", tables[tableIndex].Table)
	} else {
		// If there are still players playing, find the next player to play
		nextPlayerIndex := playerIndex + 1
		if nextPlayerIndex >= len(gameStates[tableIndex].Players) {
			nextPlayerIndex = 0 // Wrap around to the first player if we reach the end
		}
		for i := 0; i < len(gameStates[tableIndex].Players); i++ {
			if gameStates[tableIndex].Players[nextPlayerIndex].Status == STATUS_FOLDED {
				// skip folded players
			} else {
				gameStates[tableIndex].Players[nextPlayerIndex].Status = STATUS_PLAYING // Set the next player to playing status
				//gameStates[tableIndex].LastMovePlayed += gameStates[tableIndex].Players[nextPlayerIndex].Name + " to play next"
				gameStates[tableIndex].Players[nextPlayerIndex].ValidMove = setValidmoves(tableIndex, nextPlayerIndex) // Set valid moves for the next player
				break
			}
			nextPlayerIndex++
			if nextPlayerIndex >= len(gameStates[tableIndex].Players) {
				nextPlayerIndex = 0 // Wrap around to the first player if we reach the end
			}
		}
	}
}

func removeCardFromHand(tableIndex int, playerIndex int, card Card) {
	for i, c := range gameStates[tableIndex].Players[playerIndex].Hand {
		if c.Cardvalue == card.Cardvalue {
			gameStates[tableIndex].Players[playerIndex].Hand = append(gameStates[tableIndex].Players[playerIndex].Hand[:i], gameStates[tableIndex].Players[playerIndex].Hand[i+1:]...) // Remove the card from the player's hand
			gameStates[tableIndex].Players[playerIndex].NumCards--                                                                                                                     // Decrement the number of cards in hand
			if gameStates[tableIndex].Players[playerIndex].NumCards <= 0 {
				gameStates[tableIndex].Players[playerIndex].Status = STATUS_WON // If the player has no cards left, set their status to won
				gameStates[tableIndex].EndedLast = playerIndex
				fmt.Println(gameStates[tableIndex].Players[playerIndex].Name, "has won the round!")
			}
			return
		}
	}
}

func addCardtohand(tableIndex int, playerIndex int) {

	gameStates[tableIndex].Players[playerIndex].Hand = append(gameStates[tableIndex].Players[playerIndex].Hand, gameStates[tableIndex].Maindeck[gameStates[tableIndex].NumCards]) // draw the last card from the deck
	gameStates[tableIndex].NumCards--                                                                                                                                             // Decrement the number of cards in the deck
	gameStates[tableIndex].Players[playerIndex].NumCards++
	// sortCards(tableIndex, playerIndex)
}

// aiMove simulates an player's just dumb move by returning the first valid move from the AI player's valid moves.
// This is a placeholder for a more sophisticated AI logic that could be implemented later.
func aiMove(tableIndex int, playerIndex int) string {
	gameStates[tableIndex].Players[playerIndex].ValidMove = setValidmoves(tableIndex, playerIndex) // Ensure the AI player has valid moves set
	// check if AI player has valid moves (just encase)
	if len(gameStates[tableIndex].Players[playerIndex].ValidMove) == 0 {
		return "F" // If no valid moves, fold the AI player
	}
	// set the move to the first option return in the move list
	move := string(gameStates[tableIndex].Players[playerIndex].ValidMove[0]) // Get the first valid move for the AI player
	return move                                                              // Return the move
}

func checkRoundEndCondtions(tableIndex int) bool {
	// Check if all players have folded
	foldedCount := 0
	wonCount := 0
	for _, player := range gameStates[tableIndex].Players {
		if player.Status == STATUS_FOLDED {
			foldedCount++
		}
		if player.Status == STATUS_WON {
			wonCount++
		}
	}
	if foldedCount >= gameStates[tableIndex].Table.CurPlayers || wonCount >= 1 {
		gameStates[tableIndex].LastMovePlayed = "Round over, adding up the scores"
		return true // Round ends if all players have folded or one player has no cards left in the thier hand
	}
	return false // Round continues if there are still players playing and cards available
}

// End of round scoreing
// Calculate the scores for each player at the end of the round
func EndofRoundScore(tableIndex int) {

	// Check if score has already been calculated for this round
	if gameStates[tableIndex].RoundOver {
		fmt.Println("Scores have already been calculated for this round, skipping score calculation")
		gameStates[tableIndex].LastMovePlayed = "Please view the results"
		SetEndofRoundStatus(tableIndex)
		tables[tableIndex].Status = gameStates[tableIndex].Table.Status
		return
	}

	fmt.Println("------------- End of round summary ------------------")
	for i := 0; i < len(gameStates[tableIndex].Players); i++ {
		{
			SortHand(tableIndex, i)             // Sort the player's hand before calculating the score
			RemoveDuplicateCards(tableIndex, i) // Remove any duplicate cards from the player's hand before calculating the score
			WhiteTokens := 0
			BlackTokens := 0
			// Calculate the score based on the cards remaining in the player's hand
			for _, card := range gameStates[tableIndex].Players[i].Hand {
				if card.Cardvalue > 0 && card.Cardvalue < 7 {
					WhiteTokens = WhiteTokens + card.Cardvalue
				}
				if card.Cardvalue == 7 {
					BlackTokens++ // Llama is worth 1 black token (10 points)
				}
			}

			RoundScore := WhiteTokens + (BlackTokens * 10)

			if RoundScore == 0 { // Player has no cards left in hand so score is 0 for this round and can return a token if they have one
				switch {
				case gameStates[tableIndex].Players[i].BlackTokens > 0:
					gameStates[tableIndex].Players[i].BlackTokens = gameStates[tableIndex].Players[i].BlackTokens - 1
					gameStates[tableIndex].Players[i].RoundScore = 0
				case gameStates[tableIndex].Players[i].WhiteTokens > 0:
					gameStates[tableIndex].Players[i].WhiteTokens = gameStates[tableIndex].Players[i].WhiteTokens - 1
					gameStates[tableIndex].Players[i].RoundScore = 0
				default:
					gameStates[tableIndex].Players[i].RoundScore = 0
				}
			} else {
				gameStates[tableIndex].Players[i].RoundScore = RoundScore
				gameStates[tableIndex].Players[i].WhiteTokens = gameStates[tableIndex].Players[i].WhiteTokens + WhiteTokens
				gameStates[tableIndex].Players[i].BlackTokens = gameStates[tableIndex].Players[i].BlackTokens + BlackTokens

			}
			if gameStates[tableIndex].Players[i].WhiteTokens > 9 {
				gameStates[tableIndex].Players[i].BlackTokens = gameStates[tableIndex].Players[i].BlackTokens + int(gameStates[tableIndex].Players[i].WhiteTokens/10)
				gameStates[tableIndex].Players[i].WhiteTokens = gameStates[tableIndex].Players[i].WhiteTokens % 10
			}

			gameStates[tableIndex].Players[i].Score = gameStates[tableIndex].Players[i].WhiteTokens + (gameStates[tableIndex].Players[i].BlackTokens * 10) // Update the player's total score

		}
	}

	gameStates[tableIndex].LastMovePlayed = "Please view the results"
	gameStates[tableIndex].RoundOver = true // Set the round over flag to true to prevent multiple score calculations
	gameStates[tableIndex].Table.Status = 4
	SetEndofRoundStatus(tableIndex)
	tables[tableIndex].Status = gameStates[tableIndex].Table.Status

}

func SetEndofRoundStatus(tableIndex int) {
	for i := 0; i < len(gameStates[tableIndex].Players); i++ {
		gameStates[tableIndex].Players[i].ValidMove = "R" // Set valid moves to view results only
		if Status(gameStates[tableIndex].Players[i].Score) >= 40 {
			gameStates[tableIndex].Gameover = true
		}
	}
	SortByRoundScore(tableIndex)
	gameStates[tableIndex].Players[0].Status = STATUS_WON
	setPlayorOrder(tableIndex)

}

func SetEndofGameStatus(tableIndex int) {
	for i := 0; i < len(gameStates[tableIndex].Players); i++ {
		gameStates[tableIndex].Players[i].ValidMove = "G" // Set valid moves to view results only
	}
	SortByFinalScore(tableIndex)
	gameStates[tableIndex].Players[0].Status = STATUS_WON

}

func SortByRoundScore(tableIndex int) {

	sort.SliceStable(gameStates[tableIndex].Players[:], func(i, j int) bool {
		return gameStates[tableIndex].Players[i].RoundScore < gameStates[tableIndex].Players[j].RoundScore
	})
}

func SortByFinalScore(tableIndex int) {

	sort.SliceStable(gameStates[tableIndex].Players[:], func(i, j int) bool {
		return gameStates[tableIndex].Players[i].Score < gameStates[tableIndex].Players[j].Score
	})
}

// Check if all human players have viewed the results
func allViewedResults(tableIndex int) bool {
	allViewed := true
	for _, player := range gameStates[tableIndex].Players {
		if player.Status != STATUS_ROUND_VIEWED && player.Human {
			allViewed = false
			break
		}
	}
	return allViewed
}

// Check if all human players have viewed Game Over Screen
func allViewedGameOver(tableIndex int) bool {
	allViewed := true
	for _, player := range gameStates[tableIndex].Players {
		if player.Status != STATUS_GAMEOVER_VIEWED && player.Human {
			allViewed = false
			break
		}
	}
	return allViewed
}

// Reset the entire game state for the table
func resetGame(tableIndex int) {
	fmt.Println("-------------Game Over Man !!  ------------------")

	tables[tableIndex].CurPlayers = 0
	tables[tableIndex].Status = 0

	gameStates[tableIndex] = GameState{
		Table:          tables[tableIndex],
		Maindeck:       Deck{},
		NumCards:       0,
		Discard:        Card{},
		Players:        Players{},
		LastMovePlayed: "Waiting for players to join",
	}
	setUpTable(tableIndex)  // Initialize each table with a new deck and shuffle it
	updateLobby(tableIndex) // Update the lobby with the new table state
}

// Reset the game state for the next round
func resetTable(tableIndex int) {
	fmt.Println("------------- Resetting table  ------------------")
	shuffleDeck(gameStates[tableIndex].Maindeck, tableIndex)
	gameStates[tableIndex].LastMovePlayed = "New Round, waiting for players to return to the table" // Reset the last move played message
	gameStates[tableIndex].RoundOver = false                                                        // Reset the round over flag for the next
	gameStates[tableIndex].startTime = time.Now()                                                   // Reset the waiting timer for the gamestate
	setPlayorOrder(tableIndex)                                                                      // Set the play order for each player based on their index in the Players slice
	// Reset the players' status and hands for the next round
	for i := 0; i < len(gameStates[tableIndex].Players); i++ {
		gameStates[tableIndex].Players[i].Status = STATUS_WAITING // Set all players status to waiting for the next round
		gameStates[tableIndex].Players[i].Hand = Deck{}           // Reset the player's hand for the next round
		gameStates[tableIndex].Players[i].NumCards = 0            // Reset the number of cards in hand for the next round
		gameStates[tableIndex].Players[i].ValidMove = ""          // Clear the valid moves for the next round
	}
	dealCards(tableIndex)                                                                    // Deal cards to all players at the table for the next round
	gameStates[tableIndex].Players[gameStates[tableIndex].EndedLast].Status = STATUS_PLAYING // Set the player who ended the last round to be the player that starts the next round
	gameStates[tableIndex].Table.Status = 3
}

// Set the play order for each player based on their index in the Players slice
func setPlayorOrder(tableIndex int) {

	sort.SliceStable(gameStates[tableIndex].Players[:], func(i, j int) bool {
		return gameStates[tableIndex].Players[i].Playorder < gameStates[tableIndex].Players[j].Playorder
	})

}

func makeHandSummary(tableIndex int, playerIndex int) string {
	summary := ""
	for _, card := range gameStates[tableIndex].Players[playerIndex].Hand {
		summary += strconv.Itoa(card.Cardvalue)
	}
	return strings.TrimSpace(summary)
}

// update game table info to the lobby fujinet lobby server
func updateLobby(tableIndex int) {
	instanceUrlSuffix := "/?table=" + gameStates[tableIndex].Table.Table
	sendStateToLobby(gameStates[tableIndex].Table.MaxPlayers, gameStates[tableIndex].Table.CurPlayers, true, gameStates[tableIndex].Table.Name, instanceUrlSuffix)

	fmt.Println("lobby updated for :", string(gameStates[tableIndex].Table.Name))
}

func SortHand(tableIndex int, playerIndex int) {
	sort.SliceStable(gameStates[tableIndex].Players[playerIndex].Hand[:], func(i, j int) bool {
		return gameStates[tableIndex].Players[playerIndex].Hand[i].Cardvalue < gameStates[tableIndex].Players[playerIndex].Hand[j].Cardvalue
	})
}

func RemoveDuplicateCards(tableIndex int, playerIndex int) {
	seen := make(map[int]bool)
	uniqueHand := Deck{}

	for _, card := range gameStates[tableIndex].Players[playerIndex].Hand {
		if !seen[card.Cardvalue] {
			seen[card.Cardvalue] = true
			uniqueHand = append(uniqueHand, card)
		}
	}
	gameStates[tableIndex].Players[playerIndex].Hand = uniqueHand
}
