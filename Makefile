
.PHONY: build
build:
	cd ~/isucari/webapp/go; \
	go build -o isucari; \
	sudo systemctl restart isucari.golang.service;

.PHONY: pprof
pprof:
	go tool pprof -http=0.0.0.0:8080 /home/isucon/isucari/webapp/go/isucari http://localhost:6060/debug/pprof/profile

MYSQL_HOST="127.0.0.1"
MYSQL_PORT=3306
MYSQL_USER=isucari
MYSQL_DBNAME=isucari
MYSQL_PASS=isucari

MYSQL=mysql -h$(MYSQL_HOST) -P$(MYSQL_PORT) -u$(MYSQL_USER) -p$(MYSQL_PASS) $(MYSQL_DBNAME)
SLOW_LOG=/tmp/slow-query.log

# slow-wuery-logを取る設定にする
# DBを再起動すると設定はリセットされる
.PHONY: slow-on
slow-on:
	-sudo rm $(SLOW_LOG)
	sudo systemctl restart mysql
	$(MYSQL) -e "set global slow_query_log_file = '$(SLOW_LOG)'; set global long_query_time = 0.001; set global slow_query_log = ON;"

.PHONY: slow-off
slow-off:
	$(MYSQL) -e "set global slow_query_log = OFF;"

# mysqldumpslowを使ってslow wuery logを出力
# オプションは合計時間ソート
.PHONY: slow-show
slow-show:
	sudo mysqldumpslow -s t $(SLOW_LOG) | head -n 20
.PHONY: slow-detail
slow-detail:
	sudo cat /tmp/slow-query.log | pt-query-digest --limit 8

# alp

ALPSORT=sum
ALPM="/new_items/.*\.json.*,/users/.+\.json.*,/items/.+\.json.*,/transactions/.+\.png,/categories/.+/items,/items.+,/items/.+/edit,/items/.+/buy,/transactions/.+,/users/.+,/upload/*,/new_items.json.*,/static/*"
OUTFORMAT=count,method,uri,min,max,sum,avg,p99
.PHONY: alp
alp:
	sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q
.PHONY: alpsave
alpsave:
	sudo alp ltsv --file=/var/log/nginx/access.log --pos /tmp/alp.pos --dump /tmp/alp.dump --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q
.PHONY: alpload
alpload:
	sudo alp ltsv --load /tmp/alp.dump --sort $(ALPSORT) --reverse -o count,method,uri,min,max,sum,avg,p99 -q
.PHONY: alp-reset
alp-reset:
	-sudo rm /var/log/nginx/access.log; \
	sudo systemctl restart nginx.service;

.PHONY: prebench
prebench: build alp-reset slow-on
