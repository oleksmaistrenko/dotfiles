function dev-container --description 'Shell into a misto-api app container'

    set bold (set_color green --bold)
    set normal (set_color normal)

    # Optional arg: a container name (or substring) to target. Defaults to the
    # compose app-service containers (named <project>-app-N).
    set -l filter $argv[1]
    if test -z "$filter"
        set filter -app-
    end

    set -l matches (docker ps --format '{{.Names}}' --filter "name=$filter")

    switch (count $matches)
        case 0
            echo "No running container matching: \"$filter\"" >&2
            return 1
        case 1
            set -l name $matches[1]
            set -l port (docker port $name 8000/tcp 2>/dev/null | head -n1 | string replace -r '.*:' '')
            if test -n "$port"
                echo "🐳 Connecting to$bold $name$normal → http://localhost:$port"
            else
                echo "🐳 Connecting to$bold $name$normal"
            end
            docker exec -it $name sh
        case '*'
            echo "Multiple containers match \"$filter\" — pass one as an argument:" >&2
            for m in $matches
                set -l port (docker port $m 8000/tcp 2>/dev/null | head -n1 | string replace -r '.*:' '')
                if test -n "$port"
                    echo "  • $m → http://localhost:$port" >&2
                else
                    echo "  • $m" >&2
                end
            end
            return 1
    end
end
