package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	// Create HTTP server
	mux := http.NewServeMux()
	
	// Health check endpoint
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `{"status":"ok","service":"voter-api","timestamp":"`+time.Now().Format(time.RFC3339)+`"}`)
		log.Printf("Health check requested from %s", r.RemoteAddr)
	})
	
	// Vote endpoint
	mux.HandleFunc("/vote", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `{"message":"Voter API - Ready to process votes!","service":"voter-api"}`)
		log.Printf("Vote endpoint requested from %s", r.RemoteAddr)
	})
	
	// Main endpoint
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `<!DOCTYPE html>
<html>
<head>
    <title>Voter API</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        .status { color: #28a745; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Voter API</h1>
        <p class="status">✅ Service is running</p>
        <p>Timestamp: `+time.Now().Format(time.RFC3339)+`</p>
        <p>Server: `+r.Host+`</p>
        <p>Path: `+r.URL.Path+`</p>
        <hr>
        <p><a href="/health">Health Check</a></p>
        <p><a href="/vote">Vote Endpoint</a></p>
    </div>
</body>
</html>`)
		log.Printf("Main page requested from %s", r.RemoteAddr)
	})
	
	server := &http.Server{
		Addr:    ":8082",
		Handler: mux,
	}
	
	// Graceful shutdown handling
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
		<-sigChan
		
		log.Println("Shutdown signal received, stopping server...")
		
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		
		if err := server.Shutdown(ctx); err != nil {
			log.Printf("Server shutdown error: %v", err)
		} else {
			log.Println("Server stopped gracefully")
		}
	}()
	
	log.Println("Starting Voter API server on :8082")
	log.Println("Endpoints available:")
	log.Println("  GET /        - Main page")
	log.Println("  GET /health  - Health check")
	log.Println("  GET /vote    - Vote endpoint")
	
	if err := server.ListenAndServe(); err != http.ErrServerClosed {
		log.Fatalf("Server error: %v", err)
	}
}

