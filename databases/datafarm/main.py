import threading
import _thread
import json
import websocket
import datetime
from db import cursor, connection

symbol_list = [
    'btc', 'eth', 'sol', 'xrp', 'ada', 'avax', 'eos', 'trx',
    'bch', 'ltc', 'xlm', 'etc', 'neo', 'link', 'mx', 'pepe', 
    'luna', 'floki', 'ont', 'ksm', 'mln', 'dash', 'vet', 'doge'
]


class SocketConnection(websocket.WebSocketApp):

    def __init__(self, url, params=[]):
        super().__init__(url=url, on_open=self.on_open)
        self.params = params
        self.on_message = lambda ws, msg: self.message(msg)
        self.on_close = lambda ws: print('Closing')
        self.run_forever()


    def on_open(self, ws):
        def run(*args):
            tradeStr = {"method": "SUBSCRIPTION", "params": self.params}
            ws.send(json.dumps(tradeStr))
        _thread.start_new_thread(run, ())


    def message(self, msg): 
        json_data = json.loads(msg)
        time = datetime.datetime.fromtimestamp(json_data['t'] / 1000)
        formatted_time = time.strftime('%Y-%m-%d %H:%M:%S')
        symbol = json_data['s']
        price = json_data['d']['p']
        print(symbol, '|', formatted_time, '|', price)
        cursor.execute(
            "INSERT INTO market.tickers(fk_symbol, t_time, t_price) VALUES(%s, %s, %s)",
            (symbol.lower(), formatted_time, float(price))
        )
        connection.commit()


for i in symbol_list:
    threading.Thread(
        target=SocketConnection, 
        args=('wss://wbs.mexc.com/ws', [f'spot@public.miniTicker.v3.api@{i.upper()}USDT@UTC+8'])
    ).start()
