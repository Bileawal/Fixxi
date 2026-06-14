@echo off
cd /d %~dp0
echo Starting Fixxi API on port 3000...
echo Make sure MongoDB service is running.
call npm run dev
