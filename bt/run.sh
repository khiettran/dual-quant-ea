cd "/c/Program Files/TF Global Markets MetaTrader 5 Terminal"
./terminal64.exe '/config:C:\Users\ADMIN\dual-quant-ea\bt\xau_h1.ini'
./terminal64.exe '/config:C:\Users\ADMIN\dual-quant-ea\bt\eur_m15.ini'
./terminal64.exe '/config:C:\Users\ADMIN\dual-quant-ea\bt\eur_noBE.ini'
cd /c/Users/ADMIN/AppData/Roaming/MetaQuotes/Terminal/D3966AA92A61BDC959A1092A330FDFD3
for n in xau_h1 eur_m15 eur_noBE; do echo "=== $n"; iconv -f UTF-16 -t UTF-8 bt4_$n.htm | sed 's/<[^>]*>/|/g' | tr -s '| \n' | tr '\n' ' ' | grep -o -E "History Quality:.{0,25}|Total Net Profit:.{0,20}|Profit Factor:.{0,12}|Equity Drawdown Maximal:.{0,28}|Total Trades:.{0,10}|Profit Trades.{0,28}|Average (profit|loss) trade:.{0,14}"; done
