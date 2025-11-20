# MiniDex Web

Next.js frontend application for MiniDex.

## Getting Started

### Development

Install dependencies:

```bash
npm install
```

Run the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Building for Production

```bash
npm run build
npm start
```

## Environment Variables

- `API_URL` - The base URL of the Vapor API server (default: `http://localhost:8080`). Requests are proxied to `${API_URL}/v1/*`.
- `NEXT_PUBLIC_API_URL` - Public API URL for client-side requests (default: `/api`)
