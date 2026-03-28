release: bin/rails release
web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
# SolidQueue runs in-process via the Puma plugin (config/puma.rb: plugin :solid_queue)
