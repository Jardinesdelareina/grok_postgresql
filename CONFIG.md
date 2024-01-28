----------------------------------
# Конфигурационный файл PostgreSQL
----------------------------------

Этот файл состоит из строк вида:

    имя = значение

(Значок "=" не является обязательным.) Можно использовать пробелы. Комментарии вводятся с помощью
«#» в любом месте строки. Полный список названий параметров и разрешенных
значения можно найти в документации PostgreSQL.

Закомментированные настройки, показанные в этом файле, представляют собой значения по умолчанию.
Повторного комментирования параметра НЕДОСТАТОЧНО, чтобы вернуть его к значению по умолчанию;
вам нужно перезагрузить сервер.

Этот файл читается при запуске сервера и когда сервер получает SIGHUP.
сигнал. Если вы редактируете файл в работающей системе, вам необходимо ПОДПИСАТЬСЯ.
сервер, чтобы изменения вступили в силу, запустите «pg_ctl reload» или выполните
«ВЫБРАТЬ pg_reload_conf()». Некоторые параметры, отмеченные ниже,
требуют выключения и перезапуска сервера, чтобы изменения вступили в силу.

Любой параметр также может быть передан серверу в качестве параметра командной строки, например:
«postgres -c log_connections=on». Некоторые параметры можно изменить во время выполнения.
с помощью команды SQL «SET».

Блоки памяти:  
* B  = байты
* kB = килобайты
* MB = мегабайты
* GB = гигабайты
* TB = терабайты


Единицы времени:
* us = микросекунды
* ms = милисекунды
* s = секунды
* min = минуты
* h = часы
* d = дни


-----------------------
### РАСПОЛОЖЕНИЕ ФАЙЛОВ
-----------------------

Значения этих переменных по умолчанию задаются из командной строки -D 
или из переменной среды PGDATA, представленной здесь как ConfigDir.

`data_directory = '/var/lib/postgresql/14/main'`	определяет путь к директории, в которой хранятся данные PostgreSQL. Здесь указывается полный путь к каталогу, который содержит файлы баз данных, журналы операций с базами данных и другие связанные файлы.

`hba_file = '/etc/postgresql/14/main/pg_hba.conf'`	задает путь к файлу pg_hba.conf. Файл pg_hba.conf содержит правила аутентификации для подключения к PostgreSQL серверу. В этом файле определяются разрешенные методы аутентификации, разрешенные хосты и пользователи для подключения, а также настройки SSL-шифрования.

`ident_file = '/etc/postgresql/14/main/pg_ident.conf'`	указывает путь к файлу `pg_ident.conf`. Файл `pg_ident.conf` используется для настройки идентификации пользователей в системе PostgreSQL. В этом файле указываются соответствия между операционными системными пользователями и их именами в базе данных PostgreSQL.

`external_pid_file = '/var/run/postgresql/14-main.pid'`	указывает путь к файлу, в котором будет сохранен идентификатор процесса (PID) основного процесса PostgreSQL. Этот файл используется для контроля и мониторинга процесса PostgreSQL и может использоваться другими инструментами для управления сервером PostgreSQL. Если external_pid_file не задан явно, дополнительный файл PID не записывается.

--------------------------------
### ПОДКЛЮЧЕНИЯ И АУТЕНТИФИКАЦИЯ
--------------------------------

##### Настройки подключения

`#listen_addresses = 'localhost'`	используется для указания сетевых интерфейсов, на которых PostgreSQL будет прослушивать входящие соединения.

По умолчанию для параметра «listen_addresses» установлено значение «localhost», что означает, что PostgreSQL прослушивает соединения только на локальном компьютере. Если вы хотите разрешить подключения с удаленных хостов, вы можете установить для параметра «listen_addresses» IP-адрес сетевого интерфейса, на котором вы хотите принимать соединения, или вы можете установить для него значение «*», чтобы прослушивать все доступные сетевые интерфейсы.

`port = 5432`	задает порт, на котором будет слушать сервер базы данных PostgreSQL. Значение 5432 является портом по умолчанию для PostgreSQL. Когда клиентское приложение подключается к серверу, оно указывает порт, чтобы установить соединение с базой данных. 

`max_connections = 100`	устанавливает максимальное количество одновременных соединений с сервером базы данных PostgreSQL. Когда количество клиентов превышает это значение, новые соединения будут отклонены до тех пор, пока количество активных соединений не уменьшится.

`#superuser_reserved_connections = 3`	указывает количество подключений, зарезервированных для суперпользователей, которые все еще могут подключаться к серверу PostgreSQL даже при достижении максимального количества подключений. Это гарантирует, что несколько соединений всегда доступны для административных целей, что позволяет суперпользователям диагностировать и решать проблемы, когда сервер находится под большой нагрузкой.

`unix_socket_directories = '/var/run/postgresql'`	указывает директории, в которых сервер PostgreSQL будет искать UNIX-сокеты для подключения. UNIX-сокеты - это способ коммуникации между клиентом и сервером на локальной машине, который обеспечивает более эффективное взаимодействие, чем используемые TCP/IP соединения. Указание одной или нескольких директорий позволяет серверу приема подключений прослушивать сразу несколько мест, где могут находиться сокеты клиентов.
					
`#unix_socket_group = ''`	указывает группу, для которой будет доступно соединение через UNIX-сокет. 

В системах Unix, соединения через UNIX-сокеты обычно основаны на правах доступа к файлам и группах. Когда PostgreSQL создает UNIX-сокет для соединения клиента с сервером, он устанавливает группу сокета в указанное значение `unix_socket_group`. Это гарантирует, что только пользователи, принадлежащие к указанной группе, имеют доступ к этому сокету и могут подключаться к серверу.

Если параметр `unix_socket_group` установлен в пустую строку (`''`), то для сокета не устанавливается группа, и любой пользователь может подключиться к серверу через UNIX-сокет.

`#unix_socket_permissions = 0777`	определяет права доступа к файловому сокету Unix, который используется для локального подключения к серверу PostgreSQL. Значение `0777` указывает, что все пользователи, включая владельца, группу и остальных пользователей, имеют полный доступ на чтение, запись и выполнение файлового сокета. Это позволяет любым пользователям на хосте подключаться к серверу PostgreSQL через локальный сокет и выполнять операции базы данных.

`#bonjour = off`	относится к сетевому протоколу Bonjour. Bonjour – это технология, разработанная Apple, которая позволяет компьютерам и устройствам в сети автоматически находить друг друга и устанавливать соединение без необходимости настройки IP-адресов или DNS-серверов.

Когда параметр bonjour установлен в "off", PostgreSQL не будет рассылать свои сетевые анонсы или откликаться на запросы Bonjour других устройств в локальной сети. Это может быть полезно в ситуациях, когда вы не хотите, чтобы PostgreSQL обнаруживался и доступался из других устройств в сети.

Этот параметр может быть полезным при обеспечении безопасности или когда вы хотите ограничить доступ к вашей базе данных только для определенных машин или приложений.

`#bonjour_name = ''`	имя компьютера в протоколе Bonjour по-умолчанию.


##### - TCP Настройки -

Данные настройки относятся к TCP keepalive-механизму, который активируется для поддержания активного соединения между клиентом и сервером базы данных PostgreSQL.

`#tcp_keepalives_idle = 0`	задает время в секундах без активности, после которого TCP-соединение считается неактивным и отправляются keepalive-сообщения. Значение 0 отключает использование keepalive-сообщений.

`#tcp_keepalives_interval = 0`	указывает интервал между последовательными keepalive-сообщениями (в секундах). Также принимается значение 0 для отключения опции. Проверка наличия TCP-соединений включает отправку "keepalive" пакетов между клиентом и сервером с определенным интервалом. Это позволяет обнаруживать разорванные соединения или неактивные клиенты и реагировать на них соответствующим образом.

`#tcp_keepalives_count = 0`	определяет количество keepalive-сообщений, которые необходимо отправить, прежде чем соединение будет помечено как разорванное. Если значение равно 0, то количество keepalive-сообщений не ограничено.

`#tcp_user_timeout = 0`	определяет время в миллисекундах, после которого сервер обрывает соединение TCP, если клиент не ответил. Значение 0 указывает использовать системную настройку по умолчанию.

`#client_connection_check_interval = 0`	определяет интервал времени (в секундах), через который сервер будет проверять активность клиентских соединений. Если клиент не отправляет или не получает данные в течение указанного интервала, сервер может считать соединение неактивным и закрыть его. Значение 0 означает отключение этой проверки.


###### - Аутентификация -

`#authentication_timeout = 1min`	(1s-600s) указывает время ожидания сервера для аутентификации пользователя в минутах. Если сервер не получает ответ от клиента в течение указанного времени, то соединение будет разорвано.

`#password_encryption = scram-sha-256`	(scram-sha-256 или md5) задает алгоритм шифрования паролей пользователей. Значение "scram-sha-256" указывает на использование механизма аутентификации SCRAM-SHA-256, который обеспечивает более безопасное хранение паролей с использованием соли и итераций.

`#db_user_namespace = off`	определяет, будут ли имена пользователей связаны с именами баз данных. Если значение "off", то имена пользователей могут быть одинаковыми в разных базах данных. Если значение "on", то имена пользователей должны быть уникальными в пределах каждой базы данных.


<b>GSSAPI/Kerberos</b>
Начиная с версии 12, PostgreSQL поддерживает авторизацию с использованием GSSAPI/Kerberos. Эта функциональность позволяет клиентам аутентифицироваться на сервере PostgreSQL с использованием Kerberos-токенов, удобно интегрируясь с существующей инфраструктурой безопасности.

`#krb_server_keyfile = 'FILE:${sysconfdir}/krb5.keytab'`	определяет местоположение ключевого файла сервера Kerberos, который содержит необходимые ключи шифрования для аутентификации.

После включения авторизации GSSAPI/Kerberos в файле postgresql.conf, вы также должны настроить файл pg_hba.conf для определения правил аутентификации с использованием GSSAPI/Kerberos. Например:

```
# IPv4 local connections:
host    all             all             127.0.0.1/32             gss     include_realm=0
```

Здесь `gss` - это специальный тип аутентификации, позволяющий клиентам использовать GSSAPI/Kerberos для аутентификации. Вы можете определить различные правила для разных хостов, пользователей и баз данных.

`#krb_caseins_users = off`	используется для указания того, должен ли Kerberos учитывать регистр символов при аутентификации пользователей.

Когда этот параметр установлен в значение off, Kerberos будет регистронезависимым при поиске пользователей для аутентификации. Это означает, что пользователь с именем "John" сможет аутентифицироваться как "john" или "JOHN". Если параметр установлен в значение on, то регистр символов будет учитываться при аутентификации, и пользователь "John" не сможет использовать "john" или "JOHN" для входа.


##### - SSL -

Настройка SSL (Secure Sockets Layer) позволяет обеспечить защищенное соединение между клиентами и сервером PostgreSQL.

`ssl = on`	включение SSL.
`#ssl_ca_file = ''`
`ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'`	путь к сертификату сервера.
`#ssl_crl_file = ''`
`#ssl_crl_dir = ''`
`ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'`	путь к приватному ключу сервера.
`#ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'`
`#ssl_prefer_server_ciphers = on`
`#ssl_ecdh_curve = 'prime256v1'`
`#ssl_min_protocol_version = 'TLSv1.2'`
`#ssl_max_protocol_version = ''`
`#ssl_dh_params_file = ''`
`#ssl_passphrase_command = ''`
`#ssl_passphrase_command_supports_reload = off`


--------------------------------------
### ИСПОЛЬЗОВАНИЕ РЕСУРСОВ (кроме WAL)
--------------------------------------

##### - Память -

`shared_buffers = 128MB`	отвечает за выделение оперативной памяти для работы с общим буфером Postgres. Общий буфер используется для кэширования данных, что может повысить производительность базы данных.

`#huge_pages = try`	относится к использованию "огромных страниц" (huge pages) в операционной системе. Огромные страницы являются особенным типом памяти, который обладает некоторыми преимуществами в производительности. Однако, наличие поддержки огромных страниц и их корректная настройка зависит от операционной системы и настройки системы. Значение `try` указывает PostgreSQL попробовать использовать огромные страницы, если они доступны на системе.

`#huge_page_size = 0`	определяет размер hugepages в байтах. Значение 0 означает, что размер hugepages будет автоматически настроен на оптимальное значение операционной системы.

`#temp_buffers = 8MB`	указывает количество памяти, выделяемой для временных объектов, таких как временные таблицы или сортировочные структуры данных, в оперативной памяти. Значение 8MB указывает, что выделено 8 мегабайт оперативной памяти для временных объектов.

`#max_prepared_transactions = 0`	определяет максимальное количество предварительно подготовленных транзакций, которые могут быть активными одновременно. Значение 0 указывает, что предварительно подготовленные транзакции не включены, и PostgreSQL не будет их использовать. Не рекомендуется устанавливать значение ненулевым, если только вы активно намерены использовать подготовленные транзакции.

`#work_mem = 4MB`	определяет максимальный объем памяти, который может быть использован для операций сортировки и хеш-таблиц внутри PostgreSQL.

`#hash_mem_multiplier = 1.0`	определяет множитель, используемый для вычисления отведенной памяти для хеш-таблиц. Значение 1.0 означает, что выделенная память будет равна `work_mem`, а более высокие значения увеличивают отведенную память.

`#maintenance_work_mem = 64MB`	определяет объем памяти, который будет использован для операций обслуживания, таких как перестроение индексов или выполнение команды `VACUUM`.

`#autovacuum_work_mem = -1`	определяет объем памяти, который будет использован для операций автоматического обслуживания (автовакуумирования), если не указан явно. Значение -1 означает, что будет использовано значение `maintenance_work_mem`.

`#logical_decoding_work_mem = 64MB`	определяет объем памяти, который будет использован для операций дешифровки логического журнала при использовании логического декодирования.

`#max_stack_depth = 2MB`	определяет максимальную глубину стека для каждого запроса. Это значение должно быть достаточным для выполнения ваших запросов, но слишком большие значения могут привести к исчерпанию памяти на сервере.

`#shared_memory_type = mmap`	определяет тип разделяемой памяти, используемой PostgreSQL (mmap, sysv, windows).

`dynamic_shared_memory_type = posix`	определяет тип динамической разделяемой памяти, используемой PostgreSQL (posix, sysv, windows, mmap).

`#min_dynamic_shared_memory = 0MB`	определяет минимальный объем памяти, выделяемой для динамической разделяемой памяти. Значение 0 указывает на отсутствие минимального объема памяти.


##### - Диск -

`#temp_file_limit = -1`	устанавливает предел размера временных файлов, которые могут использоваться сервером PostgreSQL. Значение -1 означает, что предел не ограничен.


##### - Ресурсы ядра (Kernel Resources) -

`#max_files_per_process = 1000`	(минимум 64) определяет максимальное количество файлов, которые может открыть каждый процесс сервера PostgreSQL. Каждое открытое соединение с базой данных и каждая активная транзакция требуют соответствующего количества открытых файлов. 


##### - Cost-Based Vacuum Delay -

Данные настройки отвечают за контроль над задержкой и затратами, связанными с операцией VACUUM.

`#vacuum_cost_delay = 0`	(0-100 милисекунд) определяет задержку между итерациями операции VACUUM в миллисекундах. Значение 0 означает, что задержка отключена. Большее значение приведет к большей задержке между итерациями.

`#vacuum_cost_page_hit = 1`	(0-10000 credits) определяет затраты, связанные с чтением из кэша страницы.

`#vacuum_cost_page_miss = 2`	(0-10000 credits) определяет затраты, связанные с чтением страницы, отсутствующей в кэше.

`#vacuum_cost_page_dirty = 20`	(0-10000 credits) определяет затраты на запись измененной страницы.

`#vacuum_cost_limit = 200`	(1-10000 credits) пределяет пороговое значение, после которого VACUUM будет считать стоимость операции слишком высокой и прекратит выполнение.


##### - Background Writer -

Эти настройки отвечают за управление фоновым процессом, который выполняет запись данных из shared_buffers (оперативной памяти) на диск. 

`#bgwriter_delay = 200ms`	(10-10000ms) задает задержку между запусками фонового процесса записи в миллисекундах. Значение 200ms означает, что фоновый процесс будет запускаться каждые 200 миллисекунд.

`#bgwriter_lru_maxpages = 100`	указывает максимальное количество страниц, которые фоновый процесс может записать за одну итерацию. Значение 100 означает, что фоновый процесс не будет записывать более 100 страниц за раз.

`#bgwriter_lru_multiplier = 2.0`	управляет тем, как быстро фоновый процесс увеличивает количество записываемых страниц при недостаточном объеме доступной памяти. Значение 2.0 означает, что количество записываемых страниц будет удваиваться при каждой следующей итерации.

`#bgwriter_flush_after = 512kB`	указывает объем измененных данных, после которого фоновый процесс выполнит запись на диск. Значение 512kB означает, что запись будет выполняться после накопления 512 килобайт данных.


# - Асинхронное поведение (Asynchronous Behavior) -

Настройки Asynchronous Behavior регулируют поведение и конфигурацию работы с асинхронными операциями в PostgreSQL.

`#backend_flush_after = 0`	определяет пороговое значение для сброса изменений буферизованных данных в файловую систему. Значение 0 отключает данную опцию.

`#effective_io_concurrency = 1`	(1-1000) определяет количество одновременных операций ввода-вывода, которые PostgreSQL может выполнять для одного клиента. Значение 1 означает отсутствие параллельных операций, 0 отключает предварительную выборку.

`#maintenance_io_concurrency = 10`	(1-1000) определяет количество одновременных операций ввода-вывода, которые PostgreSQL может выполнять во время процессов обслуживания и обслуживания таблиц. Значение 10 предоставляет 10 параллельных операций, 0 отключает предварительную выборку.

`#max_worker_processes = 8`	определяет максимальное количество рабочих процессов (worker processes), которые могут выполняться в PostgreSQL.

`#max_parallel_workers_per_gather = 2`	определяет максимальное количество параллельных рабочих процессов, которые могут быть запущены во время операции сбора данных (gather operation).

`#max_parallel_maintenance_workers = 2`	определяет максимальное количество параллельных рабочих процессов, которые могут использоваться в процессах обслуживания и обслуживания таблиц.

`#max_parallel_workers = 8`	определяет максимальное общее количество параллельных рабочих процессов, которые могут быть запущены одновременно.

`#parallel_leader_participation = on`	определяет, будет ли лидер (leader) параллельной операции активно участвовать в выполнении операции или будет выполнять только роль координатора.

`#old_snapshot_threshold = -1`	(1min-60d) определяет пороговое время в миллисекундах, после которого должен быть сгенерирован новый снимок для транзакций, которые дольше этого времени.


#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------

# - Settings -

#wal_level = replica			# minimal, replica, or logical
					# (change requires restart)
#fsync = on				# flush data to disk for crash safety
					# (turning this off can cause
					# unrecoverable data corruption)
#synchronous_commit = on		# synchronization level;
					# off, local, remote_write, remote_apply, or on
#wal_sync_method = fsync		# the default is the first option
					# supported by the operating system:
					#   open_datasync
					#   fdatasync (default on Linux and FreeBSD)
					#   fsync
					#   fsync_writethrough
					#   open_sync
#full_page_writes = on			# recover from partial page writes
#wal_log_hints = off			# also do full page writes of non-critical updates
					# (change requires restart)
#wal_compression = off			# enable compression of full-page writes
#wal_init_zero = on			# zero-fill new WAL files
#wal_recycle = on			# recycle WAL files
#wal_buffers = -1			# min 32kB, -1 sets based on shared_buffers
					# (change requires restart)
#wal_writer_delay = 200ms		# 1-10000 milliseconds
#wal_writer_flush_after = 1MB		# measured in pages, 0 disables
#wal_skip_threshold = 2MB

#commit_delay = 0			# range 0-100000, in microseconds
#commit_siblings = 5			# range 1-1000

# - Checkpoints -

#checkpoint_timeout = 5min		# range 30s-1d
#checkpoint_completion_target = 0.9	# checkpoint target duration, 0.0 - 1.0
#checkpoint_flush_after = 256kB		# measured in pages, 0 disables
#checkpoint_warning = 30s		# 0 disables
max_wal_size = 1GB
min_wal_size = 80MB

# - Archiving -

#archive_mode = off		# enables archiving; off, on, or always
				# (change requires restart)
#archive_command = ''		# command to use to archive a logfile segment
				# placeholders: %p = path of file to archive
				#               %f = file name only
				# e.g. 'test ! -f /mnt/server/archivedir/%f && cp %p /mnt/server/archivedir/%f'
#archive_timeout = 0		# force a logfile segment switch after this
				# number of seconds; 0 disables

# - Archive Recovery -

# These are only used in recovery mode.

#restore_command = ''		# command to use to restore an archived logfile segment
				# placeholders: %p = path of file to restore
				#               %f = file name only
				# e.g. 'cp /mnt/server/archivedir/%f %p'
#archive_cleanup_command = ''	# command to execute at every restartpoint
#recovery_end_command = ''	# command to execute at completion of recovery

# - Recovery Target -

# Set these only when performing a targeted recovery.

#recovery_target = ''		# 'immediate' to end recovery as soon as a
                                # consistent state is reached
				# (change requires restart)
#recovery_target_name = ''	# the named restore point to which recovery will proceed
				# (change requires restart)
#recovery_target_time = ''	# the time stamp up to which recovery will proceed
				# (change requires restart)
#recovery_target_xid = ''	# the transaction ID up to which recovery will proceed
				# (change requires restart)
#recovery_target_lsn = ''	# the WAL LSN up to which recovery will proceed
				# (change requires restart)
#recovery_target_inclusive = on # Specifies whether to stop:
				# just after the specified recovery target (on)
				# just before the recovery target (off)
				# (change requires restart)
#recovery_target_timeline = 'latest'	# 'current', 'latest', or timeline ID
				# (change requires restart)
#recovery_target_action = 'pause'	# 'pause', 'promote', 'shutdown'
				# (change requires restart)


#------------------------------------------------------------------------------
# REPLICATION
#------------------------------------------------------------------------------

# - Sending Servers -

# Set these on the primary and on any standby that will send replication data.

#max_wal_senders = 10		# max number of walsender processes
				# (change requires restart)
#max_replication_slots = 10	# max number of replication slots
				# (change requires restart)
#wal_keep_size = 0		# in megabytes; 0 disables
#max_slot_wal_keep_size = -1	# in megabytes; -1 disables
#wal_sender_timeout = 60s	# in milliseconds; 0 disables
#track_commit_timestamp = off	# collect timestamp of transaction commit
				# (change requires restart)

# - Primary Server -

# These settings are ignored on a standby server.

#synchronous_standby_names = ''	# standby servers that provide sync rep
				# method to choose sync standbys, number of sync standbys,
				# and comma-separated list of application_name
				# from standby(s); '*' = all
#vacuum_defer_cleanup_age = 0	# number of xacts by which cleanup is delayed

# - Standby Servers -

# These settings are ignored on a primary server.

#primary_conninfo = ''			# connection string to sending server
#primary_slot_name = ''			# replication slot on sending server
#promote_trigger_file = ''		# file name whose presence ends recovery
#hot_standby = on			# "off" disallows queries during recovery
					# (change requires restart)
#max_standby_archive_delay = 30s	# max delay before canceling queries
					# when reading WAL from archive;
					# -1 allows indefinite delay
#max_standby_streaming_delay = 30s	# max delay before canceling queries
					# when reading streaming WAL;
					# -1 allows indefinite delay
#wal_receiver_create_temp_slot = off	# create temp slot if primary_slot_name
					# is not set
#wal_receiver_status_interval = 10s	# send replies at least this often
					# 0 disables
#hot_standby_feedback = off		# send info from standby to prevent
					# query conflicts
#wal_receiver_timeout = 60s		# time that receiver waits for
					# communication from primary
					# in milliseconds; 0 disables
#wal_retrieve_retry_interval = 5s	# time to wait before retrying to
					# retrieve WAL after a failed attempt
#recovery_min_apply_delay = 0		# minimum delay for applying changes during recovery

# - Subscribers -

# These settings are ignored on a publisher.

#max_logical_replication_workers = 4	# taken from max_worker_processes
					# (change requires restart)
#max_sync_workers_per_subscription = 2	# taken from max_logical_replication_workers


#------------------------------------------------------------------------------
# QUERY TUNING
#------------------------------------------------------------------------------

# - Planner Method Configuration -

#enable_async_append = on
#enable_bitmapscan = on
#enable_gathermerge = on
#enable_hashagg = on
#enable_hashjoin = on
#enable_incremental_sort = on
#enable_indexscan = on
#enable_indexonlyscan = on
#enable_material = on
#enable_memoize = on
#enable_mergejoin = on
#enable_nestloop = on
#enable_parallel_append = on
#enable_parallel_hash = on
#enable_partition_pruning = on
#enable_partitionwise_join = off
#enable_partitionwise_aggregate = off
#enable_seqscan = on
#enable_sort = on
#enable_tidscan = on

# - Planner Cost Constants -

#seq_page_cost = 1.0			# measured on an arbitrary scale
#random_page_cost = 4.0			# same scale as above
#cpu_tuple_cost = 0.01			# same scale as above
#cpu_index_tuple_cost = 0.005		# same scale as above
#cpu_operator_cost = 0.0025		# same scale as above
#parallel_setup_cost = 1000.0	# same scale as above
#parallel_tuple_cost = 0.1		# same scale as above
#min_parallel_table_scan_size = 8MB
#min_parallel_index_scan_size = 512kB
#effective_cache_size = 4GB

#jit_above_cost = 100000		# perform JIT compilation if available
					# and query more expensive than this;
					# -1 disables
#jit_inline_above_cost = 500000		# inline small functions if query is
					# more expensive than this; -1 disables
#jit_optimize_above_cost = 500000	# use expensive JIT optimizations if
					# query is more expensive than this;
					# -1 disables

# - Genetic Query Optimizer -

#geqo = on
#geqo_threshold = 12
#geqo_effort = 5			# range 1-10
#geqo_pool_size = 0			# selects default based on effort
#geqo_generations = 0			# selects default based on effort
#geqo_selection_bias = 2.0		# range 1.5-2.0
#geqo_seed = 0.0			# range 0.0-1.0

# - Other Planner Options -

#default_statistics_target = 100	# range 1-10000
#constraint_exclusion = partition	# on, off, or partition
#cursor_tuple_fraction = 0.1		# range 0.0-1.0
#from_collapse_limit = 8
#jit = on				# allow JIT compilation
#join_collapse_limit = 8		# 1 disables collapsing of explicit
					# JOIN clauses
#plan_cache_mode = auto			# auto, force_generic_plan or
					# force_custom_plan


#------------------------------------------------------------------------------
# REPORTING AND LOGGING
#------------------------------------------------------------------------------

# - Where to Log -

#log_destination = 'stderr'		# Valid values are combinations of
					# stderr, csvlog, syslog, and eventlog,
					# depending on platform.  csvlog
					# requires logging_collector to be on.

# This is used when logging to stderr:
#logging_collector = off		# Enable capturing of stderr and csvlog
					# into log files. Required to be on for
					# csvlogs.
					# (change requires restart)

# These are only used if logging_collector is on:
#log_directory = 'log'			# directory where log files are written,
					# can be absolute or relative to PGDATA
#log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'	# log file name pattern,
					# can include strftime() escapes
#log_file_mode = 0600			# creation mode for log files,
					# begin with 0 to use octal notation
#log_rotation_age = 1d			# Automatic rotation of logfiles will
					# happen after that time.  0 disables.
#log_rotation_size = 10MB		# Automatic rotation of logfiles will
					# happen after that much log output.
					# 0 disables.
#log_truncate_on_rotation = off		# If on, an existing log file with the
					# same name as the new log file will be
					# truncated rather than appended to.
					# But such truncation only occurs on
					# time-driven rotation, not on restarts
					# or size-driven rotation.  Default is
					# off, meaning append to existing files
					# in all cases.

# These are relevant when logging to syslog:
#syslog_facility = 'LOCAL0'
#syslog_ident = 'postgres'
#syslog_sequence_numbers = on
#syslog_split_messages = on

# This is only relevant when logging to eventlog (Windows):
# (change requires restart)
#event_source = 'PostgreSQL'

# - When to Log -

#log_min_messages = warning		# values in order of decreasing detail:
					#   debug5
					#   debug4
					#   debug3
					#   debug2
					#   debug1
					#   info
					#   notice
					#   warning
					#   error
					#   log
					#   fatal
					#   panic

#log_min_error_statement = error	# values in order of decreasing detail:
					#   debug5
					#   debug4
					#   debug3
					#   debug2
					#   debug1
					#   info
					#   notice
					#   warning
					#   error
					#   log
					#   fatal
					#   panic (effectively off)

#log_min_duration_statement = -1	# -1 is disabled, 0 logs all statements
					# and their durations, > 0 logs only
					# statements running at least this number
					# of milliseconds

#log_min_duration_sample = -1		# -1 is disabled, 0 logs a sample of statements
					# and their durations, > 0 logs only a sample of
					# statements running at least this number
					# of milliseconds;
					# sample fraction is determined by log_statement_sample_rate

#log_statement_sample_rate = 1.0	# fraction of logged statements exceeding
					# log_min_duration_sample to be logged;
					# 1.0 logs all such statements, 0.0 never logs


#log_transaction_sample_rate = 0.0	# fraction of transactions whose statements
					# are logged regardless of their duration; 1.0 logs all
					# statements from all transactions, 0.0 never logs

# - What to Log -

#debug_print_parse = off
#debug_print_rewritten = off
#debug_print_plan = off
#debug_pretty_print = on
#log_autovacuum_min_duration = -1	# log autovacuum activity;
					# -1 disables, 0 logs all actions and
					# their durations, > 0 logs only
					# actions running at least this number
					# of milliseconds.
#log_checkpoints = off
#log_connections = off
#log_disconnections = off
#log_duration = off
#log_error_verbosity = default		# terse, default, or verbose messages
#log_hostname = off
log_line_prefix = '%m [%p] %q%u@%d '		# special values:
					#   %a = application name
					#   %u = user name
					#   %d = database name
					#   %r = remote host and port
					#   %h = remote host
					#   %b = backend type
					#   %p = process ID
					#   %P = process ID of parallel group leader
					#   %t = timestamp without milliseconds
					#   %m = timestamp with milliseconds
					#   %n = timestamp with milliseconds (as a Unix epoch)
					#   %Q = query ID (0 if none or not computed)
					#   %i = command tag
					#   %e = SQL state
					#   %c = session ID
					#   %l = session line number
					#   %s = session start timestamp
					#   %v = virtual transaction ID
					#   %x = transaction ID (0 if none)
					#   %q = stop here in non-session
					#        processes
					#   %% = '%'
					# e.g. '<%u%%%d> '
#log_lock_waits = off			# log lock waits >= deadlock_timeout
#log_recovery_conflict_waits = off	# log standby recovery conflict waits
					# >= deadlock_timeout
#log_parameter_max_length = -1		# when logging statements, limit logged
					# bind-parameter values to N bytes;
					# -1 means print in full, 0 disables
#log_parameter_max_length_on_error = 0	# when logging an error, limit logged
					# bind-parameter values to N bytes;
					# -1 means print in full, 0 disables
#log_statement = 'none'			# none, ddl, mod, all
#log_replication_commands = off
#log_temp_files = -1			# log temporary files equal or larger
					# than the specified size in kilobytes;
					# -1 disables, 0 logs all temp files
log_timezone = 'Europe/Moscow'


#------------------------------------------------------------------------------
# PROCESS TITLE
#------------------------------------------------------------------------------

cluster_name = '14/main'			# added to process titles if nonempty
					# (change requires restart)
#update_process_title = on


#------------------------------------------------------------------------------
# STATISTICS
#------------------------------------------------------------------------------

# - Query and Index Statistics Collector -

#track_activities = on
#track_activity_query_size = 1024	# (change requires restart)
#track_counts = on
#track_io_timing = off
#track_wal_io_timing = off
#track_functions = none			# none, pl, all
stats_temp_directory = '/var/run/postgresql/14-main.pg_stat_tmp'


# - Monitoring -

#compute_query_id = auto
#log_statement_stats = off
#log_parser_stats = off
#log_planner_stats = off
#log_executor_stats = off


#------------------------------------------------------------------------------
# AUTOVACUUM
#------------------------------------------------------------------------------

#autovacuum = on			# Enable autovacuum subprocess?  'on'
					# requires track_counts to also be on.
#autovacuum_max_workers = 3		# max number of autovacuum subprocesses
					# (change requires restart)
#autovacuum_naptime = 1min		# time between autovacuum runs
#autovacuum_vacuum_threshold = 50	# min number of row updates before
					# vacuum
#autovacuum_vacuum_insert_threshold = 1000	# min number of row inserts
					# before vacuum; -1 disables insert
					# vacuums
#autovacuum_analyze_threshold = 50	# min number of row updates before
					# analyze
#autovacuum_vacuum_scale_factor = 0.2	# fraction of table size before vacuum
#autovacuum_vacuum_insert_scale_factor = 0.2	# fraction of inserts over table
					# size before insert vacuum
#autovacuum_analyze_scale_factor = 0.1	# fraction of table size before analyze
#autovacuum_freeze_max_age = 200000000	# maximum XID age before forced vacuum
					# (change requires restart)
#autovacuum_multixact_freeze_max_age = 400000000	# maximum multixact age
					# before forced vacuum
					# (change requires restart)
#autovacuum_vacuum_cost_delay = 2ms	# default vacuum cost delay for
					# autovacuum, in milliseconds;
					# -1 means use vacuum_cost_delay
#autovacuum_vacuum_cost_limit = -1	# default vacuum cost limit for
					# autovacuum, -1 means use
					# vacuum_cost_limit


#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------

# - Statement Behavior -

#client_min_messages = notice		# values in order of decreasing detail:
					#   debug5
					#   debug4
					#   debug3
					#   debug2
					#   debug1
					#   log
					#   notice
					#   warning
					#   error
#search_path = '"$user", public'	# schema names
#row_security = on
#default_table_access_method = 'heap'
#default_tablespace = ''		# a tablespace name, '' uses the default
#default_toast_compression = 'pglz'	# 'pglz' or 'lz4'
#temp_tablespaces = ''			# a list of tablespace names, '' uses
					# only default tablespace
#check_function_bodies = on
#default_transaction_isolation = 'read committed'
#default_transaction_read_only = off
#default_transaction_deferrable = off
#session_replication_role = 'origin'
#statement_timeout = 0			# in milliseconds, 0 is disabled
#lock_timeout = 0			# in milliseconds, 0 is disabled
#idle_in_transaction_session_timeout = 0	# in milliseconds, 0 is disabled
#idle_session_timeout = 0		# in milliseconds, 0 is disabled
#vacuum_freeze_table_age = 150000000
#vacuum_freeze_min_age = 50000000
#vacuum_failsafe_age = 1600000000
#vacuum_multixact_freeze_table_age = 150000000
#vacuum_multixact_freeze_min_age = 5000000
#vacuum_multixact_failsafe_age = 1600000000
#bytea_output = 'hex'			# hex, escape
#xmlbinary = 'base64'
#xmloption = 'content'
#gin_pending_list_limit = 4MB

# - Locale and Formatting -

datestyle = 'iso, dmy'
#intervalstyle = 'postgres'
timezone = 'Europe/Moscow'
#timezone_abbreviations = 'Default'     # Select the set of available time zone
					# abbreviations.  Currently, there are
					#   Default
					#   Australia (historical usage)
					#   India
					# You can create your own file in
					# share/timezonesets/.
#extra_float_digits = 1			# min -15, max 3; any value >0 actually
					# selects precise output mode
#client_encoding = sql_ascii		# actually, defaults to database
					# encoding

# These settings are initialized by initdb, but they can be changed.
lc_messages = 'en_US.UTF-8'			# locale for system error message
					# strings
lc_monetary = 'ru_RU.UTF-8'			# locale for monetary formatting
lc_numeric = 'ru_RU.UTF-8'			# locale for number formatting
lc_time = 'ru_RU.UTF-8'				# locale for time formatting

# default configuration for text search
default_text_search_config = 'pg_catalog.english'

# - Shared Library Preloading -

#local_preload_libraries = ''
#session_preload_libraries = ''
#shared_preload_libraries = ''	# (change requires restart)
#jit_provider = 'llvmjit'		# JIT library to use

# - Other Defaults -

#dynamic_library_path = '$libdir'
#extension_destdir = ''			# prepend path when loading extensions
					# and shared objects (added by Debian)
#gin_fuzzy_search_limit = 0


#------------------------------------------------------------------------------
# LOCK MANAGEMENT
#------------------------------------------------------------------------------

#deadlock_timeout = 1s
#max_locks_per_transaction = 64		# min 10
					# (change requires restart)
#max_pred_locks_per_transaction = 64	# min 10
					# (change requires restart)
#max_pred_locks_per_relation = -2	# negative values mean
					# (max_pred_locks_per_transaction
					#  / -max_pred_locks_per_relation) - 1
#max_pred_locks_per_page = 2            # min 0


#------------------------------------------------------------------------------
# VERSION AND PLATFORM COMPATIBILITY
#------------------------------------------------------------------------------

# - Previous PostgreSQL Versions -

#array_nulls = on
#backslash_quote = safe_encoding	# on, off, or safe_encoding
#escape_string_warning = on
#lo_compat_privileges = off
#quote_all_identifiers = off
#standard_conforming_strings = on
#synchronize_seqscans = on

# - Other Platforms and Clients -

#transform_null_equals = off


#------------------------------------------------------------------------------
# ERROR HANDLING
#------------------------------------------------------------------------------

#exit_on_error = off			# terminate session on any error?
#restart_after_crash = on		# reinitialize after backend crash?
#data_sync_retry = off			# retry or panic on failure to fsync
					# data?
					# (change requires restart)
#recovery_init_sync_method = fsync	# fsync, syncfs (Linux 5.8+)


#------------------------------------------------------------------------------
# CONFIG FILE INCLUDES
#------------------------------------------------------------------------------

# These options allow settings to be loaded from files other than the
# default postgresql.conf.  Note that these are directives, not variable
# assignments, so they can usefully be given more than once.

include_dir = 'conf.d'			# include files ending in '.conf' from
					# a directory, e.g., 'conf.d'
#include_if_exists = '...'		# include file only if it exists
#include = '...'			# include file


#------------------------------------------------------------------------------
# CUSTOMIZED OPTIONS
#------------------------------------------------------------------------------

# Add settings for extensions here
