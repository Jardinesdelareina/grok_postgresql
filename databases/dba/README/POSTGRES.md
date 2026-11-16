# PostgreSQL

`pg_lsclusters`                        # список кластеров, портов, статусов

`sudo pg_ctlcluster 16 main start`     # запустить

`sudo pg_ctlcluster 16 main stop`      # остановить

`sudo pg_ctlcluster 16 main restart`   # перезапустить

`sudo pg_ctlcluster 16 main reload`    # перечитать конфиг без рестарта

`sudo pg_ctlcluster 16 main status`    # статус


### SSH

`sudo systemctl status postgresql@16-main`

`sudo systemctl restart postgresql@16-main`