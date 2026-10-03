# Immunotec site assistant setup

The site remains published by GitHub Pages. Vercel hosts only the secure chat API and runs the knowledge-index build.

## Vercel

1. Import this same GitHub repository into Vercel. Keep the project root at the repository root and use the Other framework preset.
2. Keep the build command as `npm run build:knowledge`. The build needs `OPENAI_API_KEY` because it creates embeddings for the current pages.
3. Create an Upstash Redis REST database and add its REST URL and token to Vercel project environment variables.
4. Add these variables in Vercel for Production and Preview as needed:
   - `OPENAI_API_KEY`: secret API key from the OpenAI project.
   - `OPENAI_MODEL`: a chat model enabled for the OpenAI project, for example `gpt-4.1-mini`.
   - `OPENAI_EMBEDDING_MODEL`: `text-embedding-3-small`.
   - `UPSTASH_REDIS_REST_URL`: Upstash REST database URL.
   - `UPSTASH_REDIS_REST_TOKEN`: Upstash REST token.
   - `RATE_LIMIT_SALT`: a long random server-only value used to HMAC-hash IPs before rate-limit keys reach Upstash.
   - `ALLOWED_ORIGINS`: comma-separated exact origins, without paths or trailing slashes. Include the live GitHub Pages origin and both GoDaddy-domain variants if both serve the site, for example `https://OWNER.github.io,https://example.com,https://www.example.com`.
5. Deploy the production branch and copy the Vercel deployment URL.

## Public widget configuration

Set `apiUrl` in `js/assistant-config.js` to the deployed endpoint, such as `https://YOUR-VERCEL-PROJECT.vercel.app/api/chat`, then commit and push that change. This URL is public and is not a secret. Never put `OPENAI_API_KEY` or Upstash credentials in this file.

## Knowledge updates

Add each new Spanish or English HTML page to `agent/sources.json`, with its relative path and language (`es` or `en`). Push to GitHub. Vercel rebuilds the embeddings from the registered pages during deployment; GitHub Pages continues publishing the website as before.

## Local development

The local machine needs Node.js 20 or newer. Copy `.env.example` to `.env.local`, populate it locally, then run `npm install` and `npm run build:knowledge`. Use the Vercel CLI for local API testing so environment variables and the `/api/chat` route behave like deployment. Do not commit `.env.local`.

The chat permits up to 12 requests per minute per IP. Only an HMAC of the client IP is used as the Upstash rate-limit key. The browser keeps conversation context only in memory and sends at most the latest eight messages. OpenAI responses use `store: false`; Vercel and Upstash configuration should also be reviewed for logging and retention settings.