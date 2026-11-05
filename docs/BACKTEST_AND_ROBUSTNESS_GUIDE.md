# Quy Trình Kiểm Định Độ Tin Cậy (Robustness Checklist) Trước Khi Chạy Live

Tài liệu hướng dẫn kiểm thử EA theo tiêu chuẩn định lượng trước khi đưa vào vận hành tiền thật trên MetaTrader 5.

## 1. Kiểm thử Walk-Forward trên MT5 Strategy Tester
1. Mở **Strategy Tester (Ctrl+R)** trên MT5 và chọn file `DualCore_Quant_EA.mq5`.
2. Chọn cặp tiền (`EURUSD` hoặc `XAUUSD`) và khung thời gian (`H1` hoặc `M15`).
3. Khoảng thời gian: Tối thiểu 3 năm (ví dụ `2023.01.01` đến `2026.11.01`).
4. Mục **Forward**: Chọn **`1/3`** (tối ưu trên 2/3 dữ liệu đầu và kiểm chứng mù trên 1/3 dữ liệu cuối chưa từng thấy).
5. Mục **Modeling**: Chọn **Every tick based on real ticks** (Dữ liệu tick thực tế từ máy chủ sàn của bạn).
6. **Tiêu chuẩn Đạt (Pass):** Tỷ lệ **Walk-Forward Efficiency (WFE)** đạt từ `50% - 60%` trở lên, Profit Factor trên tập Forward >= `1.25`.

## 2. Kiểm định chéo giữa 2 sàn (Cross-Broker Validation)
1. Chạy bộ thông số đã chọn trên tài khoản MT5 của sàn chính (ví dụ **ThinkMarkets**).
2. Giữ nguyên hoàn toàn bộ thông số đó (không tối ưu lại) và chạy backtest trên dữ liệu Real Ticks của một sàn ECN thứ hai cùng chuẩn giờ `GMT+2/+3` (ví dụ **IC Markets** hoặc **Vantage**).
3. Nếu kết quả giữa 2 sàn lệch nhau nhiều do râu nến (Wick), hãy:
   - Tăng tham số `InpCore1_MinSweepATR` từ `0.05` lên `0.10` hoặc `0.15`.
   - Hoặc bật `InpUseBodyForRange = true` để EA đo vùng cản theo **Thân nến (Open/Close)** thay vì Râu nến.

## 3. Quy tắc giám sát khi chạy thực tế (Live Supervision)
* **Không can thiệp tay vào từng lệnh:** Để EA tự động xử lý Hard Stop Loss, Breakeven (`1.0R`), Trailing Stop (`1.5R`) và Time Exit (`36 nến`).
* **Can thiệp vĩ mô & hạ tầng:**
  - Tạm tắt `Algo Trading` 30 phút trước và sau các bản tin lãi suất Fed (FOMC), CPI Mỹ, Non-Farm Payrolls (NFP).
  - Bật sẵn `InpCloseOnFridayNight = true` (mặc định đóng lệnh lúc `21:00` giờ Server tối Thứ Sáu) để tránh nhảy Gap cuối tuần.
  - Ngưng EA để kiểm tra lại nếu mức sụt giảm thực tế (Live Drawdown) vượt quá ngưỡng Max Drawdown dự kiến của bài test Monte Carlo.
