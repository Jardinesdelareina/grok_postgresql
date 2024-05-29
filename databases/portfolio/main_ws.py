import threading
import _thread
import json
import websocket
import datetime
from db import cursor, connection

deals_list = []
symbols_list = [
    'BTCUSDT', 
    'ETHUSDT', 
    'SOLUSDT',
    'XRPUSDT',
    'ADAUSDT',
    'AVAXUSDT',
    'DOTUSDT', 
    'LINKUSDT',
]


class SocketConnection(websocket.WebSocketApp):

    def __init__(self, url, params=[]):
        super().__init__(url=url, on_open=self.on_open)

        self.params = params
        self.on_message = lambda ws, msg: self.message(msg)
        self.on_close = lambda ws: print('Closing')

        self.run_forever()


    def on_open(self, ws):
        print(f'Соединение открыто')

        def run(*args):
            tradeStr = {"method": "SUBSCRIPTION", "params": self.params}

            ws.send(json.dumps(tradeStr))

        _thread.start_new_thread(run, ())


    def message(self, msg): 

        global deals_dict, symbols_list

        json_data = json.loads(msg)
        deals = json_data['d']['deals'][0]
        symbol = json_data['s']
        time = datetime.datetime.fromtimestamp(deals['t'] / 1000)
        formatted_time = time.strftime('%Y-%m-%d %H:%M:%S')
        cursor.execute(
            "INSERT INTO qts.deals(d_symbol, d_time, d_side, d_price, d_qty) VALUES (%s, %s, %s, %s, %s)",
            (
                symbol.replace("_", "").lower(), 
                formatted_time,
                'BUY' if deals['S'] == 1 else 'SELL',
                float(deals['p']), 
                float(deals['v']),
            )
        )
        connection.commit()


for symbol in symbols_list:
    threading.Thread(
        target=SocketConnection, 
        args=('wss://wbs.mexc.com/ws', [f'spot@public.deals.v3.api@{symbol}'])
    ).start()