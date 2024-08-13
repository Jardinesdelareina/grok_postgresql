import environs

env = environs.Env()
env.read_env('.env')

# Database
POSTGRES_USER = env('POSTGRES_USER')
POSTGRES_PASSWORD = env('POSTGRES_PASSWORD')
POSTGRES_HOST = env('POSTGRES_HOST')
POSTGRES_DB = env('POSTGRES_DB')

# Telegram
#TELETOKEN = env('TELETOKEN')
#CHAT_ID = env('CHAT_ID')