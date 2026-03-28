release: bin/rails release
web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
# SolidQueue runs in-process via the Puma plugin when SOLID_QUEUE_IN_PUMA=1.
# To revert to a separate worker dyno, uncomment below and unset the env var.
# worker: bundle exec bin/jobs start
