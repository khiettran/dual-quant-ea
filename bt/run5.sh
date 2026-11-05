cd "/c/Program Files/TF Global Markets MetaTrader 5 Terminal"
for n in sweep15 h1 hours minsl15 rr15; do ./terminal64.exe "/config:C:\Users\ADMIN\dual-quant-ea\bt\eur_$n.ini"; done
cd /c/Users/ADMIN/AppData/Roaming/MetaQuotes/Terminal/D3966AA92A61BDC959A1092A330FDFD3
for n in sweep15 h1 hours minsl15 rr15; do echo "=== $n"; iconv -f UTF-16 -t UTF-8 bt5_$n.htm | sed 's/<[^>]*>/|/g' | tr -s '| \n' | tr '\n' ' ' | grep -o -E "History Quality:.{0,22}|Total Net Profit:.{0,18}|Profit Factor:.{0,10}|Equity Drawdown Maximal:.{0,26}|Total Trades:.{0,8}|Profit Trades.{0,26}"; done
