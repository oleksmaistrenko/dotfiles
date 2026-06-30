function dev-keepalive --description 'keepalive azure dev (odesa) misto-api'
  set parent_pid $argv[1]
  while true
    if test -n "$parent_pid"
      kill -0 $parent_pid 2>/dev/null; or return
    end
    curl -s 'https://odesa.api-dev.misto.live/c240303fa07eb4cd10d26847fedf8376/fast' | jq '{status, time: (.time | todate)}'
    sleep 60
  end
end
