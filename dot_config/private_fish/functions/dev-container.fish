function dev-container --description 'php dev container for misto-api'
  docker exec -it $(docker ps -q --filter name=app) sh
        
end
