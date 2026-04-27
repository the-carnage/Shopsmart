FROM node:20-alpine AS client-build
WORKDIR /app/client
COPY client/package*.json ./
RUN npm install
COPY client/ ./
RUN npm run build

FROM node:20-alpine AS server-build
WORKDIR /app/server
COPY server/package*.json ./
RUN npm install --omit=dev
COPY server/ ./

FROM node:20-alpine
WORKDIR /app/server
ENV NODE_ENV=production
ENV PORT=5001

COPY --from=server-build /app/server/package*.json ./
COPY --from=server-build /app/server/node_modules ./node_modules
COPY --from=server-build /app/server/src ./src
COPY --from=client-build /app/client/dist ./public

EXPOSE 5001
CMD ["node", "src/index.js"]
