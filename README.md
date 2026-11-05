# DualCore Quant EA (MT5) — Hệ Thống Giao Dịch Định Lượng Cho XAU/USD & EUR/USD

Tài liệu nghiên cứu, kiểm định độ tin cậy thực nghiệm và mã nguồn **Expert Advisor (EA) trên MetaTrader 5 (`DualCore_Quant_EA.mq5`)** được tổng hợp từ quá trình phân tích dữ liệu định lượng cho **Vàng (XAU/USD)** và **EUR/USD**.

## 1. Đánh giá các chiến lược giao dịch Vàng trên Forex Strategies Resources

Qua khảo sát các phương pháp giao dịch vàng trên chuyên trang Forex Strategies Resources, dưới đây là bảng phân loại mức độ khả thi khi đưa vào lập trình EA tự động:

| Phương pháp | Khung thời gian | Chỉ báo cốt lõi | Quy tắc vào lệnh & thoát lệnh | Đánh giá mức độ phù hợp để viết EA |
| :--- | :--- | :--- | :--- | :--- |
| **[163# Gold Scalping Strategy (MTF Filtering)](https://www.forexstrategiesresources.com/metatrader-trading-system-ii/163-gold-scalping-strategy/)** | M5, M15 (lọc MTF M30/H1) | Supertrend, EMA 9 (hoặc SMA 9), MTF SMA 9, ATR | **Buy** khi giá cắt lên Supertrend và nằm trên EMA 9 ở cả khung hiện tại lẫn khung lớn; **Sell** khi ngược lại; SL/TP cố định hoặc nhân hệ số ATR | **Tốt nhất trong nhóm Indicator:** Thuật toán chuẩn 100%, không phụ thuộc file `.ex4/.ex5` ngoài, không repaint, tự co giãn SL/TP theo biên độ ATR |
| **[205# M1 Gold Scalping – EMA Confluence with SR](https://www.forexstrategiesresources.com/scalping-forex-strategies-ii/205-m1-gold-scalping-trading-strategy/)** | M1 (phiên Âu & Mỹ) | EMA 30, EMA 50, EMA 80, vùng cản tự động (MarketPro S/R) | Chờ giá chạm vùng Support/Resistance >= 2 lần và từ chối giá, vào lệnh khi nến đóng cửa phá qua cả 3 đường EMA (30, 50, 80); SL sau vùng cản, TP theo R:R 1:2 hoặc 1:3 | **Rất tốt:** Logic Price Action kết hợp xu hướng rõ ràng; khi viết EA dùng Fractal/Swing High-Low thay cho custom indicator S/R |
| **[380# Gold Trading System (RSIOMA)](https://www.forexstrategiesresources.com/trading-system-metatrader-4-iii/380-gold-trading-system/)** | M15, M30, H1 | RSIOMA (RSI của MA), Williams' %R, Fibonacci Zone, Pivot Points | **Buy** trên vùng Fib khi Williams' %R > -25 và RSIOMA cắt lên; **Sell** dưới vùng Fib khi Williams' %R < -75 và RSIOMA cắt xuống; TP tại Pivot tiếp theo | **Tốt cho Intraday:** Có quy tắc lọc kiệt sức (bỏ qua lệnh nếu 4h trước 14:00 GMT có nến giãn >= 1000 points) rất hữu ích cho EA |
| **[287# Gold 5 min Scalping (GP Trend)](https://www.forexstrategiesresources.com/scalping-forex-strategies-ii/287-gold-5-min-scalping/)** | M5 | EMA 4, EMA 16, EMA 60, GP Trend, Delta Trend Arrow | Chỉ vào lệnh thuận xu hướng khi `EMA 4 > EMA 16 > EMA 60` (Buy) hoặc `EMA 4 < EMA 16 < EMA 60` (Sell) có xác nhận từ GP Trend và mũi tên Delta Trend | **Trung bình:** Bộ lọc cụm 3 đường EMA rất dễ code, nhưng tín hiệu kích hoạt phụ thuộc vào 2 chỉ báo custom cần gọi qua hàm `iCustom` |
| **[139# AI Gold Scalping Strategy](https://www.forexstrategiesresources.com/scalping-forex-strategies/139-ai-gold-scalping-strategy/)** | M1, M5 | EMA 200, AI Gold Scalping Indicator (TradingView) | Giao dịch thuận xu hướng theo bộ lọc EMA 200 kết hợp nhãn tín hiệu Buy/Sell và thoát lệnh ngay khi xuất hiện tín hiệu ngược chiều | **Trung bình:** Bộ lọc EMA 200 chuẩn xác nhưng thuật toán nhãn tín hiệu gốc nằm trên script riêng của TradingView |
| **[22# King Gold Pro](https://www.forexstrategiesresources.com/metatrader-trading-system-mt4/22-king-gold-pro-trading-strategy/)** & **[38# TMA with NRP Arrow](https://www.forexstrategiesresources.com/metatrader-trading-system-mt4/38-tma-with-nrp-arrow-mt5/)** | M15, M30, H1, H4 | Standard Deviation, Volume Level, TMA Centered Bands, Arrow | Đánh đảo chiều hoặc phá vỡ khi giá chạm biên kênh biến động (TMA/StdDev) kèm mũi tên xác nhận và đóng nến qua đường Volume | **Không khuyến nghị cho EA:** Dải TMA Centered và mũi tên định hướng có tính chất tự điều chỉnh lại (recalibrate/repaint) theo dữ liệu mới, gây sai lệch giữa backtest và thực tế |

## 2. Các nền tảng nghiên cứu định lượng & Mã nguồn mở bền vững hơn

Để xây dựng EA tồn tại qua nhiều chu kỳ thị trường, dưới đây là 5 nguồn dữ liệu định lượng và mã nguồn mở uy tín hơn so với các trang chia sẻ indicator truyền thống:

| Nền tảng / Chuyên trang | Điểm mạnh về tính bền vững | Chiến lược tiêu biểu | Dữ liệu kiểm chứng & Mã nguồn |
| :--- | :--- | :--- | :--- |
| **[Quantified Strategies](https://www.quantifiedstrategies.com/gold-trading-strategies/)** | Mọi quy tắc vào/thoát lệnh đều được lượng hóa bằng thống kê toán học, loại bỏ hoàn toàn cảm tính và chỉ báo vẽ lại | **Breakout kết hợp lọc ADX/Volume** và **Overnight/Seasonal Drift** | Công bố đường cong vốn (Equity Curve) thực tế, ví dụ hệ thống Breakout đạt 446 lệnh từ khi quỹ GLD ra đời với kỳ vọng thắng trung bình `0.35%/lệnh` |
| **[MQL5 CodeBase – MT5 Experts](https://www.mql5.com/en/code/mt5/experts)** & **[Top Rated EAs](https://www.mql5.com/en/code/mt5/experts/best)** | Kho mã nguồn chính thức của MetaQuotes; code được kiểm duyệt kỹ thuật bởi cộng đồng lập trình viên MQL5 | Các hệ thống EA đánh theo **Price Action**, **ATR Volatility Breakout**, **Donchian Channel** và quản lý vốn tự thích ứng | Cung cấp miễn phí 100% mã nguồn mở (`.mq5`) để tải về chạy kiểm thử trên Strategy Tester với dữ liệu Real Ticks |
| **[QuantPedia](https://quantpedia.com/cross-asset-price-based-regimes-for-gold/)** | Tổng hợp chiến lược từ nghiên cứu học thuật và quỹ định lượng (Hedge Funds), giải thích rõ nguyên lý kinh tế đằng sau lợi thế thống kê | **Cross-Asset Momentum** kết hợp động lượng của Vàng và Trái phiếu Mỹ (IEF 7–10 năm) cùng **[Momentum Effect in Commodities](https://quantpedia.com/strategies/momentum-effect-in-commodities)** | Kiểm thử dữ liệu lịch sử dài hạn từ `1969–2025` kèm đầy đủ chỉ số CAGR, Sharpe Ratio, Calmar Ratio và Maximum Drawdown |
| **[QuantConnect – Strategy Library](https://www.quantconnect.com/docs/v2/writing-algorithms/strategy-library)** | Nền tảng thuật toán cấp độ tổ chức (Institutional-grade) dùng Python/C#, tích hợp mô hình phí giao dịch và trượt giá sát thực tế | Mô hình **[Gold Market Timing](https://www.quantconnect.com/learning/articles/investment-strategy-library)** và các thuật toán Breakout/Trend đa khung | Mã nguồn mở hoàn toàn bằng Python/C#, cho phép clone và backtest miễn phí trên dữ liệu tick/phút |
| **[Forex Factory – Trading Systems](https://www.forexfactory.com/forum/71-trading-systems)** | Cộng đồng trader thực chiến lớn nhất thế giới với hàng trăm trang nhật ký giao dịch sống (forward-test) qua nhiều năm | **[Gold New York Open Range Breakout](https://www.forexfactory.com/thread/1385208-gold-trading-strategy-new-york-open-range)** và **[Gold Trading – An Institutional Way](https://www.forexfactory.com/thread/1350216-gold-trading-an-institutional-way)** | Có sẵn các bản EA do thành viên code lại kèm lịch sử khớp lệnh thực tế của cộng đồng |

## 3. So sánh vận hành EA trên MT5: EUR/USD vs. XAU/USD

| Tiêu chí vận hành EA | EUR/USD ("Vua thanh khoản") | XAU/USD ("Cỗ máy biến động") |
| :--- | :--- | :--- |
| **Thanh khoản & Chi phí ([TradingCup](https://www.tradingcup.com/en/learn/eurusd-vs-xauusd-best-forex-pair-copy-trade))** | Chiếm `~23%` thanh khoản toàn cầu; spread siêu mỏng (gần bằng `0` trên tài khoản ECN) và độ trượt giá rất thấp | Spread rộng hơn và yêu cầu ký quỹ (margin) cao hơn; đòi hỏi mục tiêu Take Profit lớn để bù đắp chi phí giao dịch |
| **Đặc tính đường giá ([QuantPedia](https://quantpedia.com/how-to-build-mean-reversion-strategies-in-currencies/))** | Dao động có biên độ chuẩn mực, tôn trọng các vùng hỗ trợ/kháng cự và có tính **hồi quy về trung bình (Mean Reversion)** cao | Không có trần biên độ; thường xuyên xảy ra các đợt bứt phá một chiều cực gắt khi có tin lạm phát hoặc căng thẳng địa chính trị |
| **Thuật toán EA tối ưu ([TradingCup](https://www.tradingcup.com/en/learn/eurusd-vs-xauusd-best-forex-pair-copy-trade))** | **False Breakout / Liquidity Sweep (Turtle Soup)**, **Pullback theo xu hướng**, hoặc **Mean Reversion** | **Swing Volatility Breakout**, **Trend-Following đa khung** kèm Trailing Stop rộng và bộ lọc kiệt sức |
| **Khung giờ vàng cho EA ([Quantified Strategies](https://www.quantifiedstrategies.com/eurusd-pair-trading-strategy/))** | Mở cửa phiên Âu (`07:00–09:00 GMT`) và phiên giao thoa London – New York (`12:00–16:00 GMT` mùa hè / `13:00–17:00 GMT` mùa đông) | Giao thoa London – New York (`13:00–17:00 GMT`), cần tránh mở lệnh mới ngay trước giờ công bố tin đỏ Mỹ |
| **Hiệu suất & Rủi ro kiểm thử ([Quantified Strategies](https://www.quantifiedstrategies.com/eurusd-pair-trading-strategy/))** | Kiểm thử `713 lệnh` đạt Win Rate `53.30%` (thắng trung bình `+0.53%`, thua `-0.47%`) với **Max Drawdown chỉ `-9.43%`** | Lợi nhuận kỳ vọng mỗi lệnh cao hơn nhưng biên độ sụt giảm tài khoản lớn nếu EA không có Hard Stop Loss |

## 4. Kiểm định độ tin cậy thực tế (Audit) & Bằng chứng lợi nhuận

### 4.1. Tại sao nhiều chiến lược phổ biến thất bại khi kiểm thử Out-of-Sample?
* **London Breakout cơ bản trên EUR/USD ([Quantified Strategies](https://www.quantifiedstrategies.com/london-breakout-strategies/)):** Khi đo đỉnh/đáy phiên Á (`03:00–08:00` giờ London) và đặt lệnh mua/bán thuận chiều phá vỡ một cách máy móc, kết quả backtest thực tế bị **âm vốn** vì các tổ chức lớn thường đẩy giá quét lệnh chờ Stop ở hai đầu biên phiên Á (Stop Hunt / False Breakout) rồi mới đảo chiều.
* **Mean Reversion đi đều lệnh trên Tiền tệ ([QuantPedia](https://quantpedia.com/how-to-build-mean-reversion-strategies-in-currencies/)):** Kiểm thử giai đoạn `2007–2024` cho thấy nếu đi lệnh tuyến tính (Linear Sizing), danh mục đi ngang suốt 10 năm với **Sharpe Ratio `0.12`**. Nếu dùng nhồi lệnh hàm mũ (Exponential Sizing / Grid) thì Sharpe Ratio tăng lên `0.35` nhưng đòn bẩy vọt lên `450%`, mang rủi ro cháy tài khoản.
* **Scalping M1–M5 ([NYCServers Algo Lab](https://newyorkcityservers.com/blog/walk-forward-monte-carlo-testing-eas)):** 90%–95% thất bại khi chạy tiền thật vì lợi nhuận kỳ vọng mỗi lệnh quá mỏng, bị trượt giá (`1–2 points`) và giãn spread xóa sổ hoàn toàn.

### 4.2. Hai phương pháp có hồ sơ lợi nhuận thực tế (Verified Track Records) vững chắc nhất
1. **Lõi 1 – False Breakout / Liquidity Sweep ("Turtle Soup" của Linda Bradford Raschke) ([Alchemy Markets](https://alchemymarkets.com/education/strategies/turtle-soup-strategy/), [RoboForex](https://roboforex.com/blog/education/trading-strategies-that-were-a-revolution-three-strategies-of-linda-raschke/)):**
   * Được sáng tạo bởi huyền thoại quỹ đầu cơ Linda Raschke (ghi nhận trong *The New Market Wizards*) để khai thác chính các cú phá vỡ giả 20 phiên.
   * Thay vì mua đuổi khi giá phá đỉnh/đáy, hệ thống chờ giá **quét qua đỉnh/đáy 20 nến để lấy thanh khoản (Liquidity Sweep) rồi đóng nến rút chân quay ngược vào trong vùng giá (Reclaim)** thuận theo xu hướng khung lớn (`EMA 200`). Điểm đặt Stop Loss nằm ngay sau râu nến quét giúp đạt tỷ lệ R:R `1:2` đến `1:3` với rủi ro rất nhỏ, hiện là chiến lược chủ lực của giới thi quỹ cấp vốn (FTMO, [Darwinex Zero](https://www.darwinexzero.com/)).
2. **Lõi 2 – Swing Volatility Breakout R:R `1:3` kèm Quản trị vốn ATR ([Quantified Strategies – Turtle Trading](https://www.quantifiedstrategies.com/turtle-trading-strategy/), [StrategyQuant H1 Gold Swing](https://strategyquant.com/shared/swing-strategy-for-gold-h1-timeframe/)):**
   * Bắt nguồn từ hệ thống của Richard Dennis & William Eckhardt (giúp nhóm Turtle Traders kiếm hơn **`175 triệu USD` trong 5 năm**, và quỹ CTA của Eckhardt duy trì **`17.35% CAGR` suốt 20 năm**). Các quỹ định lượng hiện đại dùng nguyên lý này như quỹ **Lynx** vẫn lãi **`+38.24%` (2007)**, **`+28.78%` (2021)** và **`+40.81%` (2022)**.
   * Trên nền tảng MT5 hiện nay, các EA chạy thực tế kết hợp Trend + Breakout trên khung H1 của XAU/USD (không Grid/Martingale, có Hard SL trên mọi lệnh như **[Aura Ultimate EA](https://newyorkcityservers.com/blog/aura-ultimate-ea-review)** hay bản **[StrategyQuant H1 Gold Swing](https://strategyquant.com/shared/swing-strategy-for-gold-h1-timeframe/)**) đều chứng minh khả năng vượt qua bài kiểm tra Out-of-Sample, trượt giá và Monte Carlo.

## 5. Phân vai giữa Con người và EA & Cách xử lý lệch nến giữa các sàn

### 5.1. Khi chạy thực tế (Live) có cần con người can thiệp không?
* **Tuyệt đối phó mặc 100% cho EA ở cấp độ từng lệnh:** Không tự ý cắt non lệnh đang lãi, không dời bỏ Stop Loss và không tắt bot vì tâm lý sau vài lệnh thua nhỏ.
* **Con người chỉ can thiệp ở cấp độ "Giám sát viên Hệ thống & Vĩ mô" (5–10 phút/tuần):**
  1. Tạm ngắt `Algo Trading` trước các bản tin vĩ mô/địa chính trị cực đoan (FOMC, CPI, NFP) 30 phút để tránh giãn spread và trượt giá hàng chục pip.
  2. Kiểm tra định kỳ hàng tháng xem mức sụt giảm vốn thực tế (Live Drawdown) có vượt quá phân vị 95% của bài test Monte Carlo hay không ([NYCServers Algo Lab](https://newyorkcityservers.com/blog/walk-forward-monte-carlo-testing-eas)).
  3. Đảm bảo kết nối máy chủ VPS ổn định 24/5.

### 5.2. Cách xử lý hiện tượng mỗi sàn (như ThinkMarkets vs. IC Markets) có nến (Body, Wick) khác nhau
* **Nguyên nhân ([Vantage Academy](https://www.vantagemarkets.com/en/academy/mt4-vs-mt5/), [VPSForexTrader](https://www.vpsforextrader.com/blog/hammer-candlestick-patterns-and-guide/)):** Do nguồn thanh khoản OTC của từng sàn khác nhau (lệch `0.5–2 pips` ở râu nến) và múi giờ Server (các sàn chuẩn New York Close dùng `GMT+2/+3`).
* **Giải pháp kỹ thuật đã áp dụng trong `DualCore_Quant_EA.mq5`:**
  1. **Bộ đệm tỷ lệ ATR (`InpCore1_MinSweepATR = 0.05`):** Bắt buộc râu nến phải quét qua đỉnh/đáy tối thiểu một tỷ lệ phần trăm của biên độ `ATR(14)` chứ không tính các cú nhích giá 1–2 point do lệch spread giữa các sàn.
  2. **Tùy chọn đo vùng cản theo Thân nến (`InpUseBodyForRange`):** Cho phép xác định vùng đỉnh/đáy bằng giá đóng/mở nến (`Open/Close`) thay vì râu nến (`High/Low`) theo khuyến nghị của [Quantified Strategies](https://www.quantifiedstrategies.com/london-breakout-strategies/), giúp đồng bộ tín hiệu giữa các sàn trên `95%`.
  3. **Ưu tiên chạy khung H1 & Kiểm định chéo 2 sàn (Cross-Broker Validation) ([EA-Coder](https://www.ea-coder.com/ebook-create-better-forex-robots/download-pdf.php)):** Nến H1 mở và đóng cùng phút `:00` trên mọi sàn thế giới. Khi tối ưu trên dữ liệu Real Ticks của ThinkMarkets xong, giữ nguyên thông số chạy thử trên 1 sàn ECN thứ hai để xác nhận tính bền vững.

## 6. Hướng dẫn cài đặt và chạy kiểm thử `DualCore_Quant_EA.mq5` trên MT5

1. Copy file `DualCore_Quant_EA.mq5` vào thư mục `MQL5/Experts/` trên MetaTrader 5.
2. Mở **MetaEditor (F4)** và nhấn **Compile (F7)**.
3. Mở **Strategy Tester (Ctrl+R)** trên MT5:
   * **Cặp tiền & Khung thời gian:** `EURUSD` (M15 hoặc H1) hoặc `XAUUSD` (H1).
   * **Modeling:** Chọn **Every tick based on real ticks** (Dữ liệu tick thực tế của sàn).
   * **Forward Mode:** Chọn **`1/3`** hoặc **`1/4`** để kiểm tra hiệu suất ngoài mẫu (Out-of-Sample Walk-Forward Efficiency >= 50%–60%).
   * **Cấu hình gợi ý:**
     * Chạy riêng cho **EUR/USD**: Bật `InpEnableCore1_TurtleSoup = true`, tắt `InpEnableCore2_SwingBreak = false`, đặt `InpMaxSpreadPoints = 20`.
     * Chạy cho **XAU/USD (H1)**: Bật `InpEnableCore2_SwingBreak = true` (có thể bật song song `InpEnableCore1_TurtleSoup = true`), đặt `InpMaxSpreadPoints = 350`.

## 7. Kết quả backtest ThinkMarkets (cent, real ticks 100%)

Khoảng test: 2026.05.01 – 2026.11.01 (ThinkMarkets chỉ cung cấp tick thật từ 2026.04; test dài hơn sẽ không đạt 100% chất lượng). Deposit 10000 USC, đòn bẩy 1:500, v1.11.

| Cấu hình | Net | PF | Lệnh | Max DD |
| :--- | :--- | :--- | :--- | :--- |
| XAUUSDc H1 gốc (cả 2 Core, BE+Trailing) | +262 | 1.07 | 91 | 7.3% |
| **XAUUSDc H1 preset mặc định hiện tại** (chỉ Core 2, tắt BE/Trailing) | +2440 | 1.89 | 58 | 7.6% |
| EURUSDc M15 (mọi biến thể thử) | −2073 … −3209 | 0.52–0.65 | 68–117 | 24–36% |
| EURUSDc H1 | +102 | 1.10 | 23 | 5.5% |

**Cảnh báo:** preset XAUUSD được chọn sau hơn 12 biến thể trên cùng 58–90 lệnh, nên rất dễ overfit. Cần forward test demo (>= 3 tháng) hoặc dữ liệu tick ngoài trước khi chạy tiền thật. EURUSD M15 không có edge, không nên chạy live. Preset gốc và các biến thể nằm trong `Presets/sweeps/`; cấu hình tester trong `bt/`.
