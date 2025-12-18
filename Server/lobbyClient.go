package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"

	"github.com/goccy/go-json"
)

// Defaults for this game server
// Appkey/game are hard coded, but the others could be read from a config file
var DefaultGameServerDetails = GameServer{
	Appkey:    4,
	Game:      "Fuji-Llama",
	Region:    "nz",
	Serverurl: "N:https://fuji-Hop.spysoft.nz",
	Clients: []GameClient{
		{Platform: "atari", Url: "tnfs://tnfs.spysoft.nz/atari/fujillama.xex"},
	},
}

type GameServer struct {
	// Properties being sent from Game Server
	Game       string       `json:"game"`
	Appkey     int          `json:"appkey"`
	Server     string       `json:"server"`
	Region     string       `json:"region"`
	Serverurl  string       `json:"serverurl"`
	Status     string       `json:"status"`
	Maxplayers int          `json:"maxplayers"`
	Curplayers int          `json:"curplayers"`
	Clients    []GameClient `json:"clients"`
}

type GameClient struct {
	Platform string `json:"platform"`
	Url      string `json:"url"`
}

func sendStateToLobby(maxPlayers int, curPlayers int, isOnline bool, server string, instanceUrlSuffix string) {

	// Start with copy of default game server details
	serverDetails := DefaultGameServerDetails
	serverDetails.Maxplayers = maxPlayers
	serverDetails.Curplayers = curPlayers
	if isOnline {
		serverDetails.Status = "online"
	} else {
		serverDetails.Status = "offline"
	}

	serverDetails.Server = server
	serverDetails.Serverurl += instanceUrlSuffix
	//serverDetails.Serverurl += ""

	jsonPayload, err := json.Marshal(serverDetails)
	if err != nil {
		panic(err)
	}
	fmt.Printf("Updating Lobby: %s", jsonPayload)

	request, err := http.NewRequest("POST", LOBBY_ENDPOINT_UPSERT, bytes.NewBuffer(jsonPayload))
	if err != nil {
		panic(err)
	}
	request.Header.Set("Content-Type", "application/json; charset=UTF-8")

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		log.Println(err)
		fmt.Println(err)
		return
	}
	defer response.Body.Close()

	log.Printf("Lobby Response: %s", response.Status)
	if response.StatusCode > 300 {
		body, _ := io.ReadAll(response.Body)
		fmt.Println("response Body:", string(body))
	}

}
