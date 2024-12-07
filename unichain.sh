#!/bin/bash

# Название файла для сохранения скрипта
SCRIPT_NAME="unichain.sh"

save_and_run_script() {
  echo "Сохраняю текущий скрипт в файл ${SCRIPT_NAME}..."
  
  # Создаем скрипт unichain.sh
  cat > $SCRIPT_NAME << 'EOF'
#!/bin/bash

# Цвета для вывода
GREEN="\033[0;32m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

print_header() {
  echo -e "${CYAN}"
  echo "========================================="
  echo "         🚀 Unichain Node Manager        "
  echo "========================================="
  echo -e "${RESET}"
}

download_node() {
  print_header
  echo -e "${YELLOW}Начинаю установку всех необходимых компонентов...${RESET}\n"

  echo -e "${BLUE}1. Обновление системы...${RESET}"
  sudo apt update -y && sudo apt upgrade -y

  echo -e "${BLUE}2. Установка зависимостей...${RESET}"
  sudo apt-get install -y make build-essential unzip lz4 gcc git jq curl

  echo -e "${BLUE}3. Установка Docker...${RESET}"
  sudo apt install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker

  echo -e "${BLUE}4. Установка Docker Compose...${RESET}"
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  echo -e "${BLUE}5. Клонирование репозитория...${RESET}"
  git clone https://github.com/Uniswap/unichain-node
  cd unichain-node || { echo -e "${RED}Ошибка: не удалось войти в директорию unichain-node${RESET}"; return; }

  echo -e "${BLUE}6. Запуск Docker Compose...${RESET}"
  sudo docker-compose up -d

  echo -e "${GREEN}\nУстановка завершена!${RESET}"
}

restart_node() {
  print_header
  echo -e "${YELLOW}Перезагрузка ноды...${RESET}"
  local HOMEDIR="$HOME/unichain-node"
  sudo docker-compose -f "${HOMEDIR}/docker-compose.yml" down
  sudo docker-compose -f "${HOMEDIR}/docker-compose.yml" up -d
  echo -e "${GREEN}Нода успешно перезагружена!${RESET}"
}

check_node() {
  print_header
  echo -e "${YELLOW}Проверка статуса ноды...${RESET}"
  local response
  response=$(curl -s -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
    -H "Content-Type: application/json" http://localhost:8545)

  if [[ -z "$response" ]]; then
    echo -e "${RED}Нода не отвечает или не запущена.${RESET}"
  else
    echo -e "${GREEN}Ответ от ноды:${RESET} $response"
  fi
}

check_logs_op_node() {
  print_header
  echo -e "${YELLOW}Просмотр логов OP Node в реальном времени. Чтобы выйти, нажмите Ctrl+C.${RESET}"
  sudo docker logs -f unichain-node-op-node-1 2>/dev/null || \
  echo -e "${RED}Логи OP Node недоступны. Проверьте имя контейнера или его статус.${RESET}"
}

check_logs_unichain() {
  print_header
  echo -e "${YELLOW}Просмотр логов Unichain Execution Client в реальном времени. Чтобы выйти, нажмите Ctrl+C.${RESET}"
  sudo docker logs -f unichain-node-execution-client-1 2>/dev/null || \
  echo -e "${RED}Логи Unichain недоступны. Проверьте имя контейнера или его статус.${RESET}"
}

stop_node() {
  print_header
  echo -e "${YELLOW}Остановка ноды...${RESET}"
  local HOMEDIR="$HOME/unichain-node"
  sudo docker-compose -f "${HOMEDIR}/docker-compose.yml" down
  echo -e "${GREEN}Нода успешно остановлена.${RESET}"
}

display_private_key() {
  print_header
  local nodekey_path="$HOME/unichain-node/geth-data/geth/nodekey"
  if [[ -f "$nodekey_path" ]]; then
    echo -e "${CYAN}Ваш приватный ключ:${RESET}"
    cat "$nodekey_path"
  else
    echo -e "${RED}Приватный ключ не найден.${RESET}"
  fi
}

edit_private_key() {
  print_header
  local nodekey_path="$HOME/unichain-node/geth-data/geth/nodekey"
  if [[ -f "$nodekey_path" ]]; then
    echo -e "${YELLOW}Введите новый приватный ключ:${RESET}"
    read -r new_key
    echo "$new_key" > "$nodekey_path"
    echo -e "${GREEN}Приватный ключ обновлен!${RESET}"
  else
    echo -e "${RED}Ошибка: файл приватного ключа не найден.${RESET}"
  fi
}

exit_from_script() {
  echo -e "${GREEN}Выход из скрипта.${RESET}"
  exit 0
}

# Главное меню
while true; do
  print_header
  echo -e "${CYAN}Меню:${RESET}"
  echo -e "1. 🚀 ${GREEN}Установить ноду${RESET}"
  echo -e "2. 🔄 ${YELLOW}Перезагрузить ноду${RESET}"
  echo -e "3. ✅ ${CYAN}Проверить ноду${RESET}"
  echo -e "4. 📜 ${BLUE}Посмотреть логи Unichain (OP) в реальном времени${RESET}"
  echo -e "5. 📜 ${BLUE}Посмотреть логи Unichain Execution Client в реальном времени${RESET}"
  echo -e "6. 🛑 ${RED}Остановить ноду${RESET}"
  echo -e "7. 🔑 ${CYAN}Посмотреть приватный ключ${RESET}"
  echo -e "8. ✏️ ${YELLOW}Изменить приватный ключ${RESET}"
  echo -e "9. ❌ ${RED}Выйти из скрипта${RESET}\n"

  read -p "Выберите пункт меню: " choice

  case $choice in
    1) download_node ;;
    2) restart_node ;;
    3) check_node ;;
    4) check_logs_op_node ;;
    5) check_logs_unichain ;;
    6) stop_node ;;
    7) display_private_key ;;
    8) edit_private_key ;;
    9) exit_from_script ;;
    *) echo -e "${RED}Неверный ввод. Попробуйте снова.${RESET}" ;;
  esac
done
EOF

  # Делаем файл исполняемым
  chmod +x $SCRIPT_NAME
  echo "Скрипт сохранен как ${SCRIPT_NAME} и сделан исполняемым."

  # Запускаем меню
  echo "Открытие меню..."
  bash $SCRIPT_NAME
}

# Выполнение функции
save_and_run_script

# Выполнение функции
save_and_run_script
