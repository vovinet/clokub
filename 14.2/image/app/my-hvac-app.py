import hvac
import os

url = os.environ['VAULT_URL']
token = os.environ['VAULT_TOKEN']

client = hvac.Client(
    url, token
)
client.is_authenticated()

# не пишем, а только читаем секрет
client.secrets.kv.v2.create_or_update_secret(
    path='hvac',
    secret=dict(netology='Big secret!!!'),
)

# Читаем секрет
read_secret_result = client.secrets.kv.v2.read_secret_version(
    path='hvac',
)

print(read_secret_result)