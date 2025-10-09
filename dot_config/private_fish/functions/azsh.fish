function azsh
    set bold (set_color green --bold)
    set normal (set_color normal)

    # Handle subscription switching (only when there's exactly 1 argument)
    if test (count $argv) -eq 1
        if test "$argv[1]" = "dev"
            az account set --subscription "Kyivstar_Rock IT_dev"
            echo "🏗️ Switched to$bold Kyivstar_Rock IT_dev$normal subscription"
            return
        else if test "$argv[1]" = "demo"  
            az account set --subscription "Kyivstar_Rock IT_demo"
            echo "🏗️ Switched to$bold Kyivstar_Rock IT_demo$normal subscription"
            return
        else if test "$argv[1]" = "prod"
            az account set --subscription "Kyivstar_Rock IT"
            echo "🏗️ Switched to$bold Kyivstar_Rock IT (PROD)$normal subscription"
            return
        end
    end
    
    # Handle service connections: azsh <env> <service> [type]
    if test (count $argv) -lt 2
        echo "Usage:"
        echo "  azsh dev|demo                  # Switch subscription"
        echo "  azsh <env> <service> [type]    # Connect to service"
        echo ""
        echo "Environments: dev, demo, prod"
        echo "Services: b2c, odesa, bucha, khmelnytskyi, platform, vinnytsia, edu, surprise"  
        echo "Types: server (default), cron"
        echo ""
        echo "Examples:"
        echo "  azsh dev                       # Switch to dev subscription"
        echo "  azsh dev b2c                   # Connect to b2c-server-dev"
        echo "  azsh demo edu cron             # Connect to edu-cron-demo"
        return 1
    end
    
    set env $argv[1]
    set service $argv[2] 
    set type (test (count $argv) -ge 3; and echo $argv[3]; or echo "server")
    
    # Build app name and resource group
    switch $env
        case dev
            set app_name "$service-$type-dev"
            set rg "rg-misto-dev"
        case demo
            set app_name "$service-$type-demo" 
            set rg "rg-misto-demo"
	case prod
            set app_name "$service-$type-v2i"
            set rg "misto-prod-v2"
        case '*'
            echo "Unknown environment: $env"
            return 1
    end
    
    echo "🛠️ Connecting to $bold$app_name$normal in $bold$rg$normal"
    command az containerapp exec --name $app_name --resource-group $rg --command "/bin/sh -l"
end
