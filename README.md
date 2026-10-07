# Demo application

This repository includes a small Node.js HTTP server. Run it with `npm start`; it listens on port 3000 by default and uses the `PORT` environment variable when set. `GET /health` returns HTTP 200 with the JSON response `{"status":"ok","service":"hermes-demo-001"}`. Run `npm test` to check the endpoint through its HTTP interface.
