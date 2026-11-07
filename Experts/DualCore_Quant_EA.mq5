//+------------------------------------------------------------------+
//|                                            DualCore_Quant_EA.mq5 |
//|                        Dual-Core Quantitative EA for EURUSD/XAUUSD|
//|   Core 1: Turtle Soup / False Breakout (Liquidity Sweep Reclaim) |
//|   Core 2: Swing Volatility Breakout (R:R 1:3 + Time Exit + ATR)  |
//+------------------------------------------------------------------+
#property copyright "Quantitative EA Architecture - MT5"
#property version   "1.11"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Enum cho che do khop lenh cua Core 2
enum ENUM_BREAKOUT_EXEC
  {
   EXEC_MARKET_ON_CLOSE = 0, // Vao lenh Market khi nen dong cua pha vo dinh/day
   EXEC_PENDING_STOP    = 1  // Dat lenh cho Buy/Sell Stop (tu huy sau N nen)
  };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "=== 1. CHON LOI CHIEN LUOC (DUAL-CORE SWITCH) ==="
input bool                 InpEnableCore1_TurtleSoup = false;              // Bat Core 1: False Breakout / Turtle Soup (Tot cho EURUSD & XAUUSD)
input bool                 InpEnableCore2_SwingBreak = true;              // Bat Core 2: Swing Breakout R:R 1:3 (Tot cho XAUUSD H1)
input bool                 InpUseBodyForRange        = false;             // Dung Than nen (Open/Close) thay Rau nen (High/Low) de dong bo giua cac san
input ulong                InpMagicCore1             = 202601;            // Magic Number Core 1
input ulong                InpMagicCore2             = 202602;            // Magic Number Core 2

input group "=== 2. QUAN TRI VON & BAO VE TAI KHOAN (RISK ENGINE) ==="
input double               InpRiskPercentPerTrade    = 1.0;               // Rui ro moi lenh (% Balance, 0 = dung Lot co dinh)
input double               InpFixedLot               = 0.01;              // Lot co dinh (neu Risk % = 0)
input double               InpMaxDailyLossPct        = 3.0;               // Ngung giao dich trong ngay neu lo vuot (% Equity dau ngay)
input int                  InpMaxTradesPerDay        = 3;                 // So lenh toi da moi ngay
input int                  InpMaxSpreadPoints        = 350;               // Spread toi da cho phep (Points - VD: 350 = 35 pips XAU / 3.5 pips EU)

input group "=== 3. BO LOC XU HUONG LON & THOI GIAN (REGIME & SESSION) ==="
input ENUM_TIMEFRAMES      InpTrendTimeframe         = PERIOD_H1;         // Khung thoi gian loc xu huong EMA 200
input int                  InpEMA_TrendPeriod        = 200;               // Chu ky EMA loc xu huong chinh
input int                  InpATR_Period             = 14;                // Chu ky ATR tinh bien do Stop Loss
input bool                 InpUseTimeFilter          = true;              // Bat bo loc gio giao dich (Phien Au - My)
input int                  InpStartHourServer        = 7;                 // Gio bat dau giao dich (Server Time)
input int                  InpEndHourServer          = 20;                // Gio ket thuc mo lenh moi (Server Time)
input bool                 InpCloseOnFridayNight     = true;              // Tu dong dong lenh toi Thu Sau (tranh Gap cuoi tuan)
input int                  InpFridayCloseHour        = 21;                // Gio dong lenh Thu Sau (Server Time)

input group "=== 4. THONG SO CORE 1: FALSE BREAKOUT / TURTLE SOUP ==="
input int                  InpCore1_LookbackBars     = 20;                // So nen xac dinh dinh/day thanh khoan (Chuan Linda Raschke = 20)
input double               InpCore1_MinSweepATR      = 0.05;              // Do quet toi thieu qua dinh/day (x ATR)
input double               InpCore1_MaxSweepATR      = 1.20;              // Do quet toi da (tranh nen tin tuc pha vo that, x ATR)
input double               InpCore1_SL_BufferATR     = 0.35;              // Khoang dem dat SL sau rau nen quet (x ATR)
input double               InpCore1_MinSL_ATR        = 1.00;              // Khoang cach SL toi thieu (x ATR)
input double               InpCore1_RR_Ratio         = 2.0;               // Ty le Reward:Risk cua Core 1 (Mac dinh 1:2)

input group "=== 5. THONG SO CORE 2: SWING BREAKOUT (XAUUSD H1) ==="
input ENUM_BREAKOUT_EXEC   InpCore2_ExecMode         = EXEC_MARKET_ON_CLOSE; // Che do vao lenh Core 2
input int                  InpCore2_LookbackBars     = 24;                // So nen xac dinh dinh/day Swing Breakout
input int                  InpCore2_ADX_Period       = 14;                // Chu ky ADX xac nhan xung luc
input double               InpCore2_MinADX           = 20.0;              // Nguong ADX toi thieu de vao lenh Breakout
input double               InpCore2_MaxCandleATR     = 2.50;              // Bo loc kiet suc: Bo qua neu nen truoc gian > X * ATR
input double               InpCore2_SL_ATR_Mult      = 1.50;              // Khoang cach Stop Loss Core 2 (x ATR)
input double               InpCore2_RR_Ratio         = 3.00;              // Ty le Reward:Risk Core 2 (Mac dinh 1:3)
input int                  InpCore2_PendingExpireBars= 6;                 // So nen tu huy lenh cho Stop (neu dung Pending Stop)
input int                  InpCore2_MaxHoldBars      = 36;                // Time Exit: Tu dong dong lenh sau N nen (0 = tat)

input group "=== 6. QUAN LY LENH DONG (BREAKEVEN & TRAILING STOP) ==="
input bool                 InpUseBreakeven           = false;              // Tu dong doi SL ve Hoa von (Breakeven)
input double               InpBreakevenTriggerR      = 1.0;               // Kich hoat Breakeven khi lai dat X * R (1.0R)
input double               InpBreakevenLockATR       = 0.10;              // Khoa lai nho khi doi Breakeven (x ATR)
input bool                 InpUseTrailingStop        = false;              // Bat Trailing Stop theo ATR
input double               InpTrailingStartR         = 1.5;               // Kich hoat Trailing khi lai dat X * R
input double               InpTrailingStepATR        = 1.2;               // Khoang cach truot Trailing Stop (x ATR)

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;
COrderInfo     m_order;

int            g_handleEMA_HTF = INVALID_HANDLE;
int            g_handleATR     = INVALID_HANDLE;
int            g_handleADX     = INVALID_HANDLE;

datetime       g_lastBarTime   = 0;
int            g_currentDayOfYear = -1;
double         g_dayStartEquity   = 0.0;
bool           g_dailyLossBreached = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_handleEMA_HTF = iMA(_Symbol, InpTrendTimeframe, InpEMA_TrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_handleATR     = iATR(_Symbol, PERIOD_CURRENT, InpATR_Period);
   g_handleADX     = iADX(_Symbol, PERIOD_CURRENT, InpCore2_ADX_Period);

   if(g_handleEMA_HTF == INVALID_HANDLE || g_handleATR == INVALID_HANDLE || g_handleADX == INVALID_HANDLE)
     {
      Print("Loi khoi tao Indicator Handles! Ma loi: ", GetLastError());
      return(INIT_FAILED);
     }

   m_trade.SetTypeFillingBySymbol(_Symbol);
   m_trade.SetDeviationInPoints(30);

   g_dayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   MqlDateTime dt;
   TimeCurrent(dt);
   g_currentDayOfYear = dt.day_of_year;
   g_dailyLossBreached = false;

   Print("DualCore_Quant_EA v1.11 khoi tao thanh cong tren ", _Symbol);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_handleEMA_HTF != INVALID_HANDLE) IndicatorRelease(g_handleEMA_HTF);
   if(g_handleATR     != INVALID_HANDLE) IndicatorRelease(g_handleATR);
   if(g_handleADX     != INVALID_HANDLE) IndicatorRelease(g_handleADX);
  }

//+------------------------------------------------------------------+
//| Cap nhat trang thai gioi han lo ngay (Daily Circuit Breaker)     |
//+------------------------------------------------------------------+
void CheckDailyCircuitBreaker()
  {
   MqlDateTime dt;
   TimeCurrent(dt);

   if(dt.day_of_year != g_currentDayOfYear)
     {
      g_currentDayOfYear  = dt.day_of_year;
      g_dayStartEquity    = AccountInfoDouble(ACCOUNT_EQUITY);
      g_dailyLossBreached = false;
     }

   if(InpMaxDailyLossPct <= 0.0 || g_dayStartEquity <= 0.0)
      return;

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double lossPct = ((g_dayStartEquity - currentEquity) / g_dayStartEquity) * 100.0;

   if(lossPct >= InpMaxDailyLossPct && !g_dailyLossBreached)
     {
      g_dailyLossBreached = true;
      Print("CANH BAO BAO VE VON: Lo trong ngay dat ", DoubleToString(lossPct, 2),
            "% (>= ", InpMaxDailyLossPct, "%). Dong toan bo lenh va ngung giao dich hom nay!");
      CloseAllOurPositions();
      DeleteAllOurPendingOrders();
     }
  }

//+------------------------------------------------------------------+
//| Dong toan bo vi the cua EA                                       |
//+------------------------------------------------------------------+
void CloseAllOurPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         ulong magic = m_position.Magic();
         if(m_position.Symbol() == _Symbol && (magic == InpMagicCore1 || magic == InpMagicCore2))
            m_trade.PositionClose(m_position.Ticket());
        }
     }
  }

//+------------------------------------------------------------------+
//| Xoa toan bo lenh cho cua EA                                      |
//+------------------------------------------------------------------+
void DeleteAllOurPendingOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(m_order.SelectByIndex(i))
        {
         ulong magic = m_order.Magic();
         if(m_order.Symbol() == _Symbol && (magic == InpMagicCore1 || magic == InpMagicCore2))
            m_trade.OrderDelete(m_order.Ticket());
        }
     }
  }

//+------------------------------------------------------------------+
//| Dem so lenh da khop trong ngay hom nay                           |
//+------------------------------------------------------------------+
int CountTodayDeals()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   datetime dayStart = StructToTime(dt);

   if(!HistorySelect(dayStart, TimeCurrent()))
      return 0;

   int count = 0;
   int totalDeals = HistoryDealsTotal();
   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      ulong magic = (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC);
      if(magic != InpMagicCore1 && magic != InpMagicCore2) continue;
      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry == DEAL_ENTRY_IN)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Kiem tra vi the dang mo theo Magic Number                        |
//+------------------------------------------------------------------+
bool HasOpenPosition(ulong magic)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == magic)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Kiem tra lenh cho theo Magic Number                              |
//+------------------------------------------------------------------+
bool HasPendingOrder(ulong magic)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(m_order.SelectByIndex(i))
        {
         if(m_order.Symbol() == _Symbol && m_order.Magic() == magic)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Tinh khoi luong Lot theo % Rui ro va khoang cach Stop Loss       |
//+------------------------------------------------------------------+
//| Tra ve 0.0 neu khong the dat dung muc rui ro (lot < minLot) -> bo qua lenh |
//+------------------------------------------------------------------+
int LotDigits(double lotStep)
  {
   int d = 0;
   while(d < 8 && MathAbs(lotStep * MathPow(10, d) - MathRound(lotStep * MathPow(10, d))) > 1e-9)
      d++;
   return d;
  }

double CalculateLotSize(double slDistancePrice)
  {
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(lotStep <= 0.0) return 0.0;
   int    digits  = LotDigits(lotStep);

   if(InpRiskPercentPerTrade <= 0.0 || slDistancePrice <= 0.0)
     {
      double fixedVol = MathFloor(InpFixedLot / lotStep + 1e-9) * lotStep;
      return NormalizeDouble(MathMax(minLot, MathMin(maxLot, fixedVol)), digits);
     }

   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney  = balance * (InpRiskPercentPerTrade / 100.0);
   double tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   if(tickSize <= 0.0 || tickValue <= 0.0)
      return 0.0;

   double lossPerLot = (slDistancePrice / tickSize) * tickValue;
   if(lossPerLot <= 0.0)
      return 0.0;

   double rawLot = riskMoney / lossPerLot;
   double normLot = MathFloor(rawLot / lotStep + 1e-9) * lotStep;
   if(normLot < minLot)
     {
      Print("Bo qua lenh: lot theo rui ro ", DoubleToString(rawLot, 4), " < minLot ", minLot);
      return 0.0;
     }
   normLot = MathMin(maxLot, normLot);

   return NormalizeDouble(normLot, digits);
  }

//+------------------------------------------------------------------+
//| Kiem tra du ky quy truoc khi vao lenh                            |
//+------------------------------------------------------------------+
bool HasEnoughMargin(ENUM_ORDER_TYPE type, double lots, double price)
  {
   if(lots <= 0.0) return false;
   double margin = 0.0;
   if(!OrderCalcMargin(type, _Symbol, lots, price, margin))
      return false;
   return (margin <= AccountInfoDouble(ACCOUNT_MARGIN_FREE));
  }

//+------------------------------------------------------------------+
//| Xac dinh dinh/day trong khoang nen [2 .. lookback+1]             |
//+------------------------------------------------------------------+
void GetRangeExtremes(const MqlRates &rates[], int lookback, double &hi, double &lo)
  {
   hi = InpUseBodyForRange ? MathMax(rates[2].open, rates[2].close) : rates[2].high;
   lo = InpUseBodyForRange ? MathMin(rates[2].open, rates[2].close) : rates[2].low;
   for(int i = 3; i <= lookback + 1; i++)
     {
      double barHigh = InpUseBodyForRange ? MathMax(rates[i].open, rates[i].close) : rates[i].high;
      double barLow  = InpUseBodyForRange ? MathMin(rates[i].open, rates[i].close) : rates[i].low;
      if(barHigh > hi) hi = barHigh;
      if(barLow  < lo) lo = barLow;
     }
  }

//+------------------------------------------------------------------+
//| Quan ly Breakeven, Trailing Stop va Time Exit                    |
//+------------------------------------------------------------------+
void ManageOpenPositions(double currentATR)
  {
   if(currentATR <= 0.0) return;

   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStopDist = stopsLevel * _Point;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol) continue;

      ulong magic = m_position.Magic();
      if(magic != InpMagicCore1 && magic != InpMagicCore2) continue;

      ulong  ticket     = m_position.Ticket();
      long   posType    = m_position.PositionType();
      double openPrice  = m_position.PriceOpen();
      double currentSL  = m_position.StopLoss();
      double currentTP  = m_position.TakeProfit();
      datetime openTime = m_position.Time();

      if(magic == InpMagicCore2 && InpCore2_MaxHoldBars > 0)
        {
         int barsHeld = iBarShift(_Symbol, PERIOD_CURRENT, openTime);
         if(barsHeld >= InpCore2_MaxHoldBars)
           {
            Print("Core 2 Time Exit: Dong lenh #", ticket, " sau ", barsHeld, " nen.");
            m_trade.PositionClose(ticket);
            continue;
           }
        }

      double rrRatio = (magic == InpMagicCore1) ? InpCore1_RR_Ratio : InpCore2_RR_Ratio;
      double initialRisk = 0.0;
      if(currentTP > 0.0 && rrRatio > 0.0)
         initialRisk = MathAbs(currentTP - openPrice) / rrRatio;
      else if(currentSL > 0.0)
         initialRisk = MathAbs(openPrice - currentSL);

      if(initialRisk <= 0.0) continue;

      if(posType == POSITION_TYPE_BUY)
        {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double profitDist = bid - openPrice;

         if(InpUseBreakeven && profitDist >= InpBreakevenTriggerR * initialRisk)
           {
            double newSL = NormalizeDouble(openPrice + InpBreakevenLockATR * currentATR, _Digits);
            if((currentSL == 0.0 || currentSL < openPrice) && (bid - newSL > minStopDist))
              {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
                  currentSL = newSL;
              }
           }

         if(InpUseTrailingStop && profitDist >= InpTrailingStartR * initialRisk)
           {
            double trailSL = NormalizeDouble(bid - InpTrailingStepATR * currentATR, _Digits);
            if(trailSL > currentSL + (10 * _Point) && (bid - trailSL > minStopDist))
              {
               m_trade.PositionModify(ticket, trailSL, currentTP);
              }
           }
        }
      else if(posType == POSITION_TYPE_SELL)
        {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double profitDist = openPrice - ask;

         if(InpUseBreakeven && profitDist >= InpBreakevenTriggerR * initialRisk)
           {
            double newSL = NormalizeDouble(openPrice - InpBreakevenLockATR * currentATR, _Digits);
            if((currentSL == 0.0 || currentSL > openPrice) && (newSL - ask > minStopDist))
              {
               if(m_trade.PositionModify(ticket, newSL, currentTP))
                  currentSL = newSL;
              }
           }

         if(InpUseTrailingStop && profitDist >= InpTrailingStartR * initialRisk)
           {
            double trailSL = NormalizeDouble(ask + InpTrailingStepATR * currentATR, _Digits);
            if((currentSL == 0.0 || trailSL < currentSL - (10 * _Point)) && (trailSL - ask > minStopDist))
              {
               m_trade.PositionModify(ticket, trailSL, currentTP);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| CORE 1: False Breakout / Turtle Soup (Liquidity Sweep & Reclaim) |
//+------------------------------------------------------------------+
void EvaluateCore1_TurtleSoup(double emaHTF, double atr)
  {
   if(HasOpenPosition(InpMagicCore1)) return;

   int lookback = InpCore1_LookbackBars;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, lookback + 5, rates) < lookback + 3)
      return;

   double highestLevel, lowestLevel;
   GetRangeExtremes(rates, lookback, highestLevel, lowestLevel);

   double high1  = rates[1].high;
   double low1   = rates[1].low;
   double close1 = rates[1].close;
   double open1  = rates[1].open;

   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStopDist = MathMax(stopsLevel * _Point, InpCore1_MinSL_ATR * atr);

   //--- 1. Kich ban BUY (Bullish Liquidity Sweep thuan xu huong tang EMA 200)
   bool isBullTrend = (close1 > emaHTF);
   double sweepDown = lowestLevel - low1;
   bool sweptLow    = (sweepDown >= InpCore1_MinSweepATR * atr && sweepDown <= InpCore1_MaxSweepATR * atr);
   bool reclaimedUp = (close1 > lowestLevel && close1 > open1);

   if(isBullTrend && sweptLow && reclaimedUp)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double rawSL = low1 - (InpCore1_SL_BufferATR * atr);
      double slDist = MathMax(ask - rawSL, minStopDist);
      double slPrice = NormalizeDouble(ask - slDist, _Digits);
      double tpPrice = NormalizeDouble(ask + (slDist * InpCore1_RR_Ratio), _Digits);
      double lots    = CalculateLotSize(slDist);
      if(!HasEnoughMargin(ORDER_TYPE_BUY, lots, ask)) return;

      m_trade.SetExpertMagicNumber(InpMagicCore1);
      if(m_trade.Buy(lots, _Symbol, ask, slPrice, tpPrice, "Core1_TurtleSoup_Buy"))
         Print("Core 1 BUY khop tai ", ask, " | SL: ", slPrice, " | TP: ", tpPrice);
      else
         Print("Core 1 BUY that bai: retcode=", m_trade.ResultRetcode(), " ", m_trade.ResultRetcodeDescription());
      return;
     }

   //--- 2. Kich ban SELL (Bearish Liquidity Sweep thuan xu huong giam EMA 200)
   bool isBearTrend = (close1 < emaHTF);
   double sweepUp   = high1 - highestLevel;
   bool sweptHigh   = (sweepUp >= InpCore1_MinSweepATR * atr && sweepUp <= InpCore1_MaxSweepATR * atr);
   bool reclaimedDn = (close1 < highestLevel && close1 < open1);

   if(isBearTrend && sweptHigh && reclaimedDn)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double rawSL = high1 + (InpCore1_SL_BufferATR * atr);
      double slDist = MathMax(rawSL - bid, minStopDist);
      double slPrice = NormalizeDouble(bid + slDist, _Digits);
      double tpPrice = NormalizeDouble(bid - (slDist * InpCore1_RR_Ratio), _Digits);
      double lots    = CalculateLotSize(slDist);
      if(!HasEnoughMargin(ORDER_TYPE_SELL, lots, bid)) return;

      m_trade.SetExpertMagicNumber(InpMagicCore1);
      if(m_trade.Sell(lots, _Symbol, bid, slPrice, tpPrice, "Core1_TurtleSoup_Sell"))
         Print("Core 1 SELL khop tai ", bid, " | SL: ", slPrice, " | TP: ", tpPrice);
      else
         Print("Core 1 SELL that bai: retcode=", m_trade.ResultRetcode(), " ", m_trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| CORE 2: Swing Volatility Breakout (R:R 1:3 + ADX + Exhaustion)   |
//+------------------------------------------------------------------+
void EvaluateCore2_SwingBreakout(double emaHTF, double atr, double adxVal)
  {
   if(HasOpenPosition(InpMagicCore2) || HasPendingOrder(InpMagicCore2))
      return;

   if(adxVal < InpCore2_MinADX)
      return;

   int lookback = InpCore2_LookbackBars;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, lookback + 5, rates) < lookback + 3)
      return;

   double candle1Range = rates[1].high - rates[1].low;
   if(candle1Range > InpCore2_MaxCandleATR * atr)
      return;

   double swingHigh, swingLow;
   GetRangeExtremes(rates, lookback, swingHigh, swingLow);

   double close1 = rates[1].close;
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double slDist  = MathMax(InpCore2_SL_ATR_Mult * atr, (stopsLevel + 10) * _Point);
   double tpDist  = slDist * InpCore2_RR_Ratio;
   double lots    = CalculateLotSize(slDist);
   if(lots <= 0.0) return;

   m_trade.SetExpertMagicNumber(InpMagicCore2);

   if(InpCore2_ExecMode == EXEC_MARKET_ON_CLOSE)
     {
      if(close1 > emaHTF && close1 > swingHigh)
        {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double sl  = NormalizeDouble(ask - slDist, _Digits);
         double tp  = NormalizeDouble(ask + tpDist, _Digits);
         if(!HasEnoughMargin(ORDER_TYPE_BUY, lots, ask)) return;
         if(m_trade.Buy(lots, _Symbol, ask, sl, tp, "Core2_SwingBreak_Buy"))
            Print("Core 2 Breakout BUY khop tai ", ask, " | SL: ", sl, " | TP: ", tp);
         else
            Print("Core 2 BUY that bai: retcode=", m_trade.ResultRetcode(), " ", m_trade.ResultRetcodeDescription());
        }
      else if(close1 < emaHTF && close1 < swingLow)
        {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl  = NormalizeDouble(bid + slDist, _Digits);
         double tp  = NormalizeDouble(bid - tpDist, _Digits);
         if(!HasEnoughMargin(ORDER_TYPE_SELL, lots, bid)) return;
         if(m_trade.Sell(lots, _Symbol, bid, sl, tp, "Core2_SwingBreak_Sell"))
            Print("Core 2 Breakout SELL khop tai ", bid, " | SL: ", sl, " | TP: ", tp);
         else
            Print("Core 2 SELL that bai: retcode=", m_trade.ResultRetcode(), " ", m_trade.ResultRetcodeDescription());
        }
     }
   else if(InpCore2_ExecMode == EXEC_PENDING_STOP)
     {
      datetime expireTime = TimeCurrent() + (InpCore2_PendingExpireBars * PeriodSeconds(PERIOD_CURRENT));
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      if(close1 > emaHTF && swingHigh > ask + (stopsLevel * _Point))
        {
         double entry = NormalizeDouble(swingHigh + (2 * _Point), _Digits);
         double sl    = NormalizeDouble(entry - slDist, _Digits);
         double tp    = NormalizeDouble(entry + tpDist, _Digits);
         if(HasEnoughMargin(ORDER_TYPE_BUY_STOP, lots, entry) &&
            !m_trade.BuyStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expireTime, "Core2_BuyStop"))
            Print("Core 2 BuyStop that bai: retcode=", m_trade.ResultRetcode(), " ", m_trade.ResultRetcodeDescription());
        }
      else if(close1 < emaHTF && swingLow < bid - (stopsLevel * _Point))
        {
         double entry = NormalizeDouble(swingLow - (2 * _Point), _Digits);
         double sl    = NormalizeDouble(entry + slDist, _Digits);
         double tp    = NormalizeDouble(entry - tpDist, _Digits);
         if(HasEnoughMargin(ORDER_TYPE_SELL_STOP, lots, entry) &&
            !m_trade.SellStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expireTime, "Core2_SellStop"))
            Print("Core 2 SellStop that bai: retcode=", m_trade.ResultRetcode(), " ", m_trade.ResultRetcodeDescription());
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CheckDailyCircuitBreaker();
   if(g_dailyLossBreached) return;

   MqlDateTime dt;
   TimeCurrent(dt);
   if(InpCloseOnFridayNight && dt.day_of_week == 5 && dt.hour >= InpFridayCloseHour)
     {
      CloseAllOurPositions();
      DeleteAllOurPendingOrders();
      return;
     }

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(g_handleATR, 0, 1, 1, atrBuf) < 1) return;
   double currentATR = atrBuf[0];

   ManageOpenPositions(currentATR);

   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == g_lastBarTime)
      return;

   long currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(currentSpread > InpMaxSpreadPoints)
      return;

   if(InpUseTimeFilter)
     {
      if(dt.hour < InpStartHourServer || dt.hour >= InpEndHourServer)
         return;
     }

   if(CountTodayDeals() >= InpMaxTradesPerDay)
      return;

   double emaBuf[], adxBuf[];
   ArraySetAsSeries(emaBuf, true);
   ArraySetAsSeries(adxBuf, true);
   if(CopyBuffer(g_handleEMA_HTF, 0, 1, 1, emaBuf) < 1) return;
   if(CopyBuffer(g_handleADX, 0, 1, 1, adxBuf) < 1)     return;

   g_lastBarTime = currentBarTime;

   if(InpEnableCore1_TurtleSoup)
      EvaluateCore1_TurtleSoup(emaBuf[0], currentATR);

   if(InpEnableCore2_SwingBreak)
      EvaluateCore2_SwingBreakout(emaBuf[0], currentATR, adxBuf[0]);
  }
//+------------------------------------------------------------------+
