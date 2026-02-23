@echo off
cd /d "C:\Users\43wq\.openclaw\workspace\ARIA-Project\backend"
echo Starting ARIA Server...
echo.
echo Server will be available at: http://localhost:3000
echo.
npx tsx watch src/server.ts
pause
