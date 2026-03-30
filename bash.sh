#!/bin/bash

(cd server && npm i)
(cd client && npm i)

(cd server && npm run dev) &
(cd client && npm run dev) &

wait
