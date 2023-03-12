#include <stderror.mqh>
#include <stdlib.mqh>

bool FractalsUp=false;
bool FractalsDown=false;
double FractalsUpPrice=0;
double FractalsDownPrice=0;
int FractalsLimit=100;
double currentTarget = 0;
bool SLtoBE = False;
int gainer = 0;
string gold = "XAUUSD";
double lotsize;
extern double raw_lotsize = 0;
extern double lotsize_per_1k = 0.01;
double bePoint = 50;
double percent = 2.5;
double lot_size = 0.5;
double move_to_break_even_after_x_pips=1000;
double trail_kick_in_at_pips=1000;
double trail_behind_pips=1000;
double pip_value; 
int ticket;

void FindFractals(){
   //Initialization of the variables
   FractalsUp=false;
   FractalsDown=false;
   FractalsUpPrice=0;
   FractalsDownPrice=0;
   
   //For loop to scan the last FractalsLimit candles starting from the oldest and finishing with the most recent
   for(int i=FractalsLimit; i>=0; i--){
      //If there is a fractal on the candle the value will be greater than zero and equal to the highest or lowest price
      double fu=iFractals(Symbol(),0,MODE_UPPER,i);
      double fl=iFractals(Symbol(),0,MODE_LOWER,i);
      //If there is an upper fractal I store the value and set true the FractalsUp variable
      if(fu>0){
         FractalsUp=true;
         FractalsDown=false;
         FractalsUpPrice=fu;
      }
      //If there is an lower fractal I store the value and set true the FractalsDown variable
      if(fl>0){
         FractalsUp=false;
         FractalsDown=true;
         FractalsDownPrice=fl;
      } 
      //if the candle has both upper and lower fractal the values are stored but we do not consider it as last fractal
      if(fu>0 && fl>0){
         FractalsUp=false;
         FractalsDown=false;
         FractalsUpPrice=fu;        
         FractalsDownPrice=fl;
      }
  }
}

void OnInit()
{
   pip_value = grab_pip_value();
}

void OnTick()
{
   FindFractals();
   Print("The last Bullish Fractal was: ",FractalsUpPrice," ","The last Bearish Fractal was: ",FractalsDownPrice);
   RefreshRates();
   double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
   double PriceBid = MarketInfo(Symbol(), MODE_BID);
   double tpBuy = PriceBid + 30;
   double slBuy = PriceBid - 5;
   double tpSell = PriceAsk - 30;
   double slSell = PriceAsk + 5;
   
   if(CheckOrders()==0)
   {
      if(PriceBid <= FractalsDownPrice)
      {
         int orderIdSell = OrderSend(Symbol(),OP_SELL,lotsize(),PriceBid,1,FractalsUpPrice,0,NULL,NULL,NULL,NULL);
      }
      if(PriceAsk >= FractalsUpPrice)
      {
         int orderIdBuy = OrderSend(Symbol(),OP_BUY,lotsize(),PriceAsk,1,FractalsDownPrice,0,NULL,NULL,NULL,NULL);
      }
   }
   
   check_trailing_stop();
}

int CheckOrders()
{
   int Orders= 0;
   for(int i = OrdersTotal()-1; i >=0; i--)
   {
      OrderSelect(i, SELECT_BY_POS,MODE_TRADES);   
      if(TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent())&& (OrderSymbol() == Symbol()))
      {
         Orders += 1;
      }
   }
   return(Orders);
}




void check_trailing_stop()
  {
   for(int i=0; i<OrdersTotal(); i++)
     {
      double gap;
      double pnl_pips;
      OrderSelect(i,SELECT_BY_POS);
      if(OrderType()==OP_BUY)
        {
         pnl_pips = (OrderClosePrice()-OrderOpenPrice())/pip_value;
         if(pnl_pips>=trail_kick_in_at_pips)
           {
            gap = (Bid-OrderStopLoss())/pip_value;
            if(gap>trail_behind_pips)
              {
               OrderModify(OrderTicket(),Bid,Bid-(trail_behind_pips*pip_value),OrderTakeProfit(),NULL);
              }
           }
        }
      if(OrderType()==OP_SELL)
        {
         pnl_pips = (OrderOpenPrice()-OrderClosePrice())/pip_value;
         if(pnl_pips>=trail_kick_in_at_pips)
           {
            gap = (OrderStopLoss()-Ask)/pip_value;
            if(gap>trail_behind_pips)
              {
               OrderModify(OrderTicket(),Ask,Ask+(trail_behind_pips*pip_value),OrderTakeProfit(),NULL);
              }
           }
        }
     }
  }
  
double grab_pip_value()
  {
   double digits = MarketInfo(Symbol(),MODE_DIGITS);
   double pip;
   if(digits==2 || digits==3)
     {
         pip = 0.01;
     }
   else
      if(digits==4 || digits==5)
        {
            pip = 0.0001;
        }
   else
      {
         pip = 0.1;
      }
   return pip;
   Print(pip);
  }
  
double lotsize()
  {
   if(raw_lotsize>0)
      return raw_lotsize;
   return(AccountEquity()/1000)*lotsize_per_1k;
  }
  

