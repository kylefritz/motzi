release: PG_TRANSACTION_TIMEOUT=0 bin/rails release
web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
worker: bundle exec bin/jobs start
