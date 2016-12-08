# Kollar, Edward ekollar@ford.com 
# 2016/12/07 
 
cls 
taskkill /F /FI "USERNAME eq %username%" /IM rdpclip.exe 
ping -n 1 -w 1000 1.1.1.1>nul 
start rdpclip.exe 
exit