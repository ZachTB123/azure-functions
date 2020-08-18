package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

type InvokeResponse struct {
	Outputs     map[string]interface{}
	Logs        []string
	ReturnValue interface{}
}

type InvokeRequest struct {
	Data     map[string]interface{}
	Metadata map[string]interface{}
}

func timerTrigger(w http.ResponseWriter, r *http.Request) {
	log.Println("Timer trigger was invoked: Version 1")

	invokeResponse := InvokeResponse{
		Logs: []string{"success"},
	}

	js, err := json.Marshal(invokeResponse)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(js)
}

func main() {
	httpInvokerPort, exists := os.LookupEnv("FUNCTIONS_HTTPWORKER_PORT")
	if exists {
		fmt.Println("FUNCTIONS_HTTPWORKER_PORT: " + httpInvokerPort)
	} else {
		httpInvokerPort = "0"
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/timerTrigger", timerTrigger)
	log.Println("Go server Listening...on httpInvokerPort:", httpInvokerPort)
	log.Fatal(http.ListenAndServe(":"+httpInvokerPort, mux))
}
