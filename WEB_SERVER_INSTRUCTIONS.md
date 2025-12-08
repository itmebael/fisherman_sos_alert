# Running Flutter Web App Locally

Flutter web applications **cannot** be opened directly as a file (`file://` protocol) due to browser security restrictions. You need to serve it through a web server.

## Quick Start

### Option 1: Use the provided script (Windows)
```bash
serve_web.bat
```

### Option 2: Use the provided script (Linux/Mac)
```bash
chmod +x serve_web.sh
./serve_web.sh
```

### Option 3: Manual Python Server

1. Open terminal/command prompt
2. Navigate to the project directory
3. Run one of these commands:

**Python 3:**
```bash
cd build/web
python -m http.server 8000
```

**Python 2:**
```bash
cd build/web
python -m SimpleHTTPServer 8000
```

4. Open your browser and go to: `http://localhost:8000`

### Option 4: Use Flutter's Built-in Server

```bash
flutter run -d chrome --web-port=8080
```

This will automatically build and serve the web app.

### Option 5: Use Node.js http-server

If you have Node.js installed:
```bash
npm install -g http-server
cd build/web
http-server -p 8000
```

## Why can't I open index.html directly?

- Browser security restrictions (CORS)
- Service workers require HTTPS or localhost
- Flutter web apps need proper HTTP headers
- Relative paths don't work with `file://` protocol

## Production Deployment

For production, deploy the `build/web` folder to:
- Firebase Hosting
- GitHub Pages
- Netlify
- Vercel
- Any static web hosting service



