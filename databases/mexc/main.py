import requests
import environs
import pandas as pd
from sqlalchemy import create_engine

env = environs.Env()
env.read_env('.env')

DB_USER = env('DB_USER')
DB_PASS = env('DB_PASS')
DB_HOST = env('DB_HOST')
DB_PORT = env('DB_PORT')
DB_NAME = env('DB_NAME')
ENGINE = create_engine(
    f'postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
)


def main(symbol: str, interval: str = 'Min15'):
    res = requests.get(
        f'https://contract.mexc.com/api/v1/contract/kline/{symbol}?interval={interval}'
    )
    res_time = res.json()['data']['time']
    res_open = res.json()['data']['open']
    res_high = res.json()['data']['high']
    res_low = res.json()['data']['low']
    res_close = res.json()['data']['close']
    data = {
        'm_time': res_time,
        'm_open': res_open,
        'm_high': res_high,
        'm_low': res_low,
        'm_close': res_close,
    }
    df = pd.DataFrame(data)
    df = df.astype(float)
    df.to_sql(name=f'{symbol.replace("_", "").lower()}', con=ENGINE, if_exists='append', index=False)
    print('[SUCCESS]')

main('XRP_USDT')