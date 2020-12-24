//+------------------------------------------------------------------+
//|                                                     Breakout.mq4 |
//|                                       Copyright 2020, 4Bet-Allin |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, 4Bet-Allin"
#property link      ""
#property version   "1.00"
#property strict
#property show_inputs
bool TradeBuy = true;
bool TradeSell = true;
int ticket;

double LotSize = 0;
double Price = 0.0;
double StopLoss = 0.0;
double TakeProfit = 0.0;
double min = 2;
double max = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
   //特になし
}

//+------------------------------------------------------------------+
//|  Calculate Lot size from Stop Loss function                     |
//+------------------------------------------------------------------+
double CalculateLotSize(double SL){
   double AccountBalance = 3000;
   double MaxRiskPerTrade = 2;
   //
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   //ティックバリューが3,5の時は10倍
   if(Digits == 3 || Digits == 5){
      nTickValue = nTickValue*10;
   }
   //証拠金に対してロットを計算
   LotSize = (AccBalance * (MaxRiskPerTrade / 100))/(SL*nTickValue);
   LotSize = MathRound(LotSize/MarketInfo(Symbol(), MODE_LOTSTEP))*MarketInfo(Symbol(), MODE_LOTSTEP);
   return LotSize;
   
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   // 稼働開始時にとりあえず全部クローズ　.
   if(OrdersTotal() > 1){
     TrailingStop();
     CloseOrders();
   }
   
   // 直近10時間からの高値安値
   if(Hour() == 10 && Minute() == 0){
      for(int i=1;i<=3;i++){
         if(max < iHigh(Symbol(), PERIOD_H1, i)){
            max = iHigh(Symbol(), PERIOD_H1, i);
         }
         if(min > iLow(Symbol(), PERIOD_H1, i)){
            min = iLow(Symbol(), PERIOD_H1, i);
         }
      }
   }

   // Long
   if(Hour() >= 10 && max != 0 && TradeBuy){
      TakeProfit = max + 130 * Point();
      StopLoss = max - (2* iATR(Symbol(), PERIOD_H1, 14, 0));
      LotSize = (2* iATR(Symbol(), PERIOD_H1, 14, 0)) * 10000;
      Price = max;
      ticket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, Price, 3, StopLoss, TakeProfit, "London breakout BUYSTOP", 0, 0, clrGreen);
      if(ticket<0){
         Print("OrderSend failed with error #", GetLastError());
      }else{
         Print("OrderSend placed successfully");
      }
      TradeBuy = false;
   }
   
   // Short
   if(Hour() >= 10 && min != 2 && TradeSell){
      TakeProfit = min - 130 * Point();
      StopLoss = min + (2* iATR(Symbol(), PERIOD_H1, 14, 0));
      LotSize = (2* iATR(Symbol(), PERIOD_H1, 14, 0)) * 10000;
      Price = min;
      ticket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, Price, 3, StopLoss, TakeProfit, "London breakout SELLSTOP", 0, 0, clrRed);
      if(ticket<0){
         Print("OrderSend failed with error #", GetLastError());
      }else{
         Print("OrderSend placed successfully");
      }
      TradeSell = false;
   }
}

}
//+------------------------------------------------------------------+
//| Trailing Take profit and Stop Loss function                      |
//+------------------------------------------------------------------+
void TrailingStop(){
   bool res;
   for(int i=0;i<OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if(OrderType() == OP_BUY && OrderSymbol() == Symbol()){
            if(Ask > OrderOpenPrice() + (100 * Point())){
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + (100 * Point()), OrderTakeProfit(), 0, clrNONE);
               if(!res){
                  Print("Error in OrderModify. Error code=", GetLastError());
               }else{
                  Print("Order modified successfully.");
               }
            }
            if(Ask > OrderTakeProfit() - 20 * Point()){
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), OrderTakeProfit() + (20 * Point()), 0, clrNONE);
               if(!res){
                  Print("Error in OrderModify. Error code=", GetLastError());
               }else{
                  Print("Order modified successfully.");
               }
            }
         }else if(OrderType() == OP_SELL && OrderSymbol() == Symbol()){
            if(Bid < OrderOpenPrice() - (100 * Point())){
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - (100 * Point()), OrderTakeProfit(), 0, clrNONE);
               if(!res){
                  Print("Error in OrderModify. Error code=", GetLastError());
               }else{
                  Print("Order modified successfully.");
               }
            }
           if(Bid < OrderTakeProfit() + 20 * Point()){
               res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), OrderTakeProfit() - (20 * Point()), 0, clrNONE);
               if(!res){
                  Print("Error in OrderModify. Error code=", GetLastError());
               }else{
                  Print("Order modified successfully.");
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
//| Close inactive orders                                            |
//+------------------------------------------------------------------+
void CloseOrders(){
   bool res;
   if(Hour() >= 11){
      for(int i=0;i<OrdersTotal(); i++){
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
            if(OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT){
               res = OrderDelete(OrderTicket());
               if(!res){
                  Print("Error in OrderDelete. Error code=", GetLastError());
               }else{
                  Print("Order deleted successfully.");
               }
            }
         }
      }
   }
}