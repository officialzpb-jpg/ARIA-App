@echo off
echo ==========================================
echo ARIA - Docker Setup (Fixed)
echo ==========================================
echo.

cd /d "C:\Users\43wq\.openclaw\workspace\ARIA-Project\backend"

echo [1/6] Checking Node.js...
"C:\Program Files\nodejs\node.exe" --version >nul 2>&1
if errorlevel 1 (
    echo Trying alternative Node.js location...
    "%LOCALAPPDATA%\Programs\nodejs\node.exe" --version >nul 2>&1
    if errorlevel 1 (
        echo ERROR: Node.js not found. Please install from nodejs.org
        pause
        exit /b 1
    ) else (
        set "NODE_CMD=%LOCALAPPDATA%\Programs\nodejs\node.exe"
        set "NPM_CMD=%LOCALAPPDATA%\Programs\nodejs\npm.cmd"
    )
) else (
    set "NODE_CMD=C:\Program Files\nodejs\node.exe"
    set "NPM_CMD=C:\Program Files\nodejs\npm.cmd"
)

echo Node.js found
echo.

echo [2/6] Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not found. Please start Docker Desktop.
    pause
    exit /b 1
)
echo Docker OK
echo.

echo [3/6] Starting PostgreSQL and Redis...
docker-compose up -d postgres redis
if errorlevel 1 (
    docker compose up -d postgres redis
    if errorlevel 1 (
        echo ERROR: Failed to start Docker containers
        pause
        exit /b 1
    )
)
echo Database containers started
echo.

echo [4/6] Waiting for database...
timeout /t 5 /nobreak >nul
echo Ready
echo.

echo [5/6] Installing dependencies...
"%NPM_CMD%" install
if errorlevel 1 (
    echo ERROR: npm install failed
    pause
    exit /b 1
)
echo Dependencies installed
echo.

echo [6/6] Setting up database...
"%NPM_CMD%" run db:generate
if errorlevel 1 (
    echo ERROR: Prisma generate failed
    pause
    exit /b 1
)

echo init | "%NPM_CMD%" run db:migrate
echo Database ready
echo.

echo Creating start script...
cd ..
(
echo @echo off
echo cd /d "C:\Users\43wq\.openclaw\workspace\ARIA-Project\backend"
echo echo Starting ARIA Server...
echo echo.
echo "C:\Program Files\nodejs\npx.cmd" tsx watch src/server.ts
echo pause
) > START-ARIA.bat

echo.
echo ==========================================
echo SETUP COMPLETE!
echo ==========================================
echo.
echo To start ARIA:
echo   1. Make sure Docker Desktop is running
echo   2. Double-click START-ARIA.bat
echo.
pause
