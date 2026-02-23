@echo off
echo ==========================================
echo ARIA - Docker Setup
echo ==========================================
echo.

cd /d "C:\Users\43wq\.openclaw\workspace\ARIA-Project\backend"

echo [1/6] Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not found. Please install Docker Desktop.
    pause
    exit /b 1
)
echo Docker OK
echo.

echo [2/6] Starting PostgreSQL and Redis...
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

echo [3/6] Waiting for database to be ready...
timeout /t 5 /nobreak >nul
echo Ready
echo.

echo [4/6] Installing Node dependencies...
npm install
if errorlevel 1 (
    echo ERROR: npm install failed
    pause
    exit /b 1
)
echo Dependencies installed
echo.

echo [5/6] Setting up database...
npx prisma generate
if errorlevel 1 (
    echo ERROR: Prisma generate failed
    pause
    exit /b 1
)

echo init | npx prisma migrate dev --name init
echo Database ready
echo.

echo [6/6] Creating start script...
cd ..
(
echo @echo off
echo echo Starting ARIA Server...
echo echo.
echo echo Checking Docker...
echo docker ps >nul 2>&1
echo if errorlevel 1 (
echo     echo ERROR: Docker not running. Start Docker Desktop first.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo Checking database containers...
echo docker ps ^| findstr aria-postgres >nul
echo if errorlevel 1 (
echo     echo Starting database containers...
echo     docker-compose up -d postgres redis
necho ^)
echo.
echo cd backend
necho echo.
echo echo ==========================================
echo echo Server starting on http://localhost:3000
echo echo ==========================================
echo echo.
echo npx tsx watch src/server.ts
echo pause
) > START-ARIA.bat

echo Start script created
echo.
echo ==========================================
echo SETUP COMPLETE!
echo ==========================================
echo.
echo To start ARIA:
echo   1. Make sure Docker Desktop is running
echo   2. Double-click START-ARIA.bat
echo.
echo Dashboard:
echo   file:///C:/Users/43wq/.openclaw/workspace/ARIA-Project/dashboard/index.html
echo.
pause
